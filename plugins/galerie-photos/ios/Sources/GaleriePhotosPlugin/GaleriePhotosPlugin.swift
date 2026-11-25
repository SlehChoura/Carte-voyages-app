import Foundation
import UIKit
import Photos
import CoreLocation
import Capacitor

/// Lit la galerie Photos de l'iPhone : date + position GPS de chaque photo,
/// et fabrique des miniatures sur le téléphone. Rien n'est envoyé sur internet.
@objc(GaleriePhotosPlugin)
public class GaleriePhotosPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "GaleriePhotosPlugin"
    public let jsName = "GaleriePhotos"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "info", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestAccess", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "listPhotos", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "makeThumbs", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getImage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openSettings", returnType: CAPPluginReturnPromise)
    ]

    private let work = DispatchQueue(label: "fr.famille.galerie", qos: .userInitiated)

    // MARK: - Outils

    private func statusString(_ s: PHAuthorizationStatus) -> String {
        switch s {
        case .authorized: return "full"
        case .limited: return "limited"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }

    /// Dossier des miniatures (Library/Application Support/miniatures), exclu de la sauvegarde iCloud.
    private func thumbDir() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var dir = base.appendingPathComponent("miniatures", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            var rv = URLResourceValues()
            rv.isExcludedFromBackup = true
            try? dir.setResourceValues(rv)
        }
        return dir
    }

    /// Même règle que dans la page web : les « / » de l'identifiant deviennent « _ ».
    private static func fileName(_ localId: String) -> String {
        return localId.replacingOccurrences(of: "/", with: "_") + ".jpg"
    }

    private func requestImage(_ asset: PHAsset, side: CGFloat) -> UIImage? {
        let o = PHImageRequestOptions()
        o.isSynchronous = true
        o.deliveryMode = .highQualityFormat
        o.resizeMode = .fast
        o.isNetworkAccessAllowed = true // photos « optimisées » stockées dans iCloud
        var result: UIImage?
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: side, height: side),
                                              contentMode: .aspectFill,
                                              options: o) { img, _ in result = img }
        return result
    }

    // MARK: - Méthodes appelées depuis la page

    @objc func info(_ call: CAPPluginCall) {
        call.resolve([
            "thumbDir": thumbDir().path,
            "status": statusString(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        ])
    }

    @objc func requestAccess(_ call: CAPPluginCall) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            call.resolve(["status": self.statusString(status)])
        }
    }

    /// Liste toutes les photos de la galerie qui ont une position GPS.
    @objc func listPhotos(_ call: CAPPluginCall) {
        work.async {
            let opts = PHFetchOptions()
            opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            opts.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
            let res = PHAsset.fetchAssets(with: .image, options: opts)
            var out: [[String: Any]] = []
            out.reserveCapacity(res.count)
            var noLoc = 0
            res.enumerateObjects { a, _, _ in
                guard let loc = a.location, let d = a.creationDate else { noLoc += 1; return }
                let c = loc.coordinate
                if !CLLocationCoordinate2DIsValid(c) || (c.latitude == 0 && c.longitude == 0) { noLoc += 1; return }
                out.append([
                    "id": a.localIdentifier,
                    "lat": c.latitude,
                    "lng": c.longitude,
                    "t": d.timeIntervalSince1970 * 1000
                ])
            }
            call.resolve(["photos": out, "total": res.count, "noLocation": noLoc])
        }
    }

    /// Fabrique les miniatures manquantes pour une liste d'identifiants.
    @objc func makeThumbs(_ call: CAPPluginCall) {
        let ids = call.getArray("ids", String.self) ?? []
        let side = CGFloat(call.getInt("size") ?? 320)
        work.async {
            let dir = self.thumbDir()
            let fm = FileManager.default
            let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var assets: [PHAsset] = []
            fetched.enumerateObjects { a, _, _ in assets.append(a) }
            let lock = NSLock()
            var ok: [String] = []
            DispatchQueue.concurrentPerform(iterations: assets.count) { i in
                let a = assets[i]
                let url = dir.appendingPathComponent(GaleriePhotosPlugin.fileName(a.localIdentifier))
                var done = fm.fileExists(atPath: url.path)
                if !done, let img = self.requestImage(a, side: side),
                   let data = img.jpegData(compressionQuality: 0.72) {
                    done = (try? data.write(to: url, options: .atomic)) != nil
                }
                if done { lock.lock(); ok.append(a.localIdentifier); lock.unlock() }
            }
            let okSet = Set(ok)
            call.resolve(["ok": ok, "failed": ids.filter { !okSet.contains($0) }])
        }
    }

    /// Image plus grande pour la visionneuse (fichier temporaire).
    @objc func getImage(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { call.reject("id manquant"); return }
        let side = CGFloat(call.getInt("size") ?? 1600)
        work.async {
            guard let a = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject,
                  let img = self.requestImage(a, side: side),
                  let data = img.jpegData(compressionQuality: 0.85) else {
                call.reject("Photo introuvable")
                return
            }
            let url = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("vue-" + GaleriePhotosPlugin.fileName(id))
            do {
                try data.write(to: url, options: .atomic)
                call.resolve(["path": url.path])
            } catch {
                call.reject("Écriture impossible")
            }
        }
    }

    @objc func openSettings(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            call.resolve()
        }
    }
}
