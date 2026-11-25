# Nos voyages : l'app iPhone

Cette application affiche la carte des voyages en famille. Elle lit directement la galerie Photos de l'iPhone : la date et le lieu de chaque photo. Rien ne quitte le téléphone.

## Récupérer le fichier .ipa

1. Sur GitHub, ouvrez l'onglet **Actions** de ce dépôt, puis la dernière exécution verte « Fabriquer l'app iPhone (.ipa) ».
2. En bas de la page, dans **Artifacts**, téléchargez **NosVoyages-ipa**. C'est un .zip : décompressez-le pour obtenir `NosVoyages.ipa`.

Pour relancer une fabrication à la main : **Actions › Fabriquer l'app iPhone › Run workflow**.

## Installer sur l'iPhone avec un PC Windows (gratuit)

À faire une seule fois :
1. Installez **iTunes** (version du site d'Apple, pas celle du Microsoft Store si possible) et **iCloud pour Windows**. Sideloadly en a besoin pour parler à l'iPhone.
2. Installez **Sideloadly** depuis sideloadly.io.
3. Branchez l'iPhone au PC en USB, déverrouillez-le et touchez « Se fier à cet ordinateur ».

Installer l'app :
1. Ouvrez Sideloadly, glissez `NosVoyages.ipa` dans la fenêtre.
2. Choisissez votre iPhone et tapez votre **Apple ID** (votre adresse iCloud habituelle). Il ne sert qu'à signer l'app chez Apple.
3. Cliquez **Start**. Si Apple demande un code de validation, tapez-le.
4. Sur l'iPhone : **Réglages › Général › VPN et gestion de l'appareil**, touchez votre Apple ID puis **Faire confiance**.
5. Sur l'iPhone (iOS 16 ou plus récent) : **Réglages › Confidentialité et sécurité › Mode développeur**, activez-le, puis l'iPhone redémarre et vous confirmez.
6. Ouvrez « Nos voyages », touchez **Lire ma galerie**, puis choisissez **Autoriser l'accès complet**.

## Tous les 7 jours

Avec un Apple ID gratuit, la signature dure 7 jours. Après, l'app ne s'ouvre plus. Il suffit de rebrancher l'iPhone et de refaire **Start** dans Sideloadly avec le même .ipa et le même Apple ID. Les données (séjours, annotations) sont conservées.

Faites quand même de temps en temps **☰ › Sauvegarder** pour garder une copie de vos annotations.

## Pour les curieux : comment c'est fait

- `web/app.html` : la carte (la même que la version web, avec en plus la lecture de la galerie quand elle tourne dans l'app).
- `plugins/galerie-photos` : le petit module iOS (Swift, PhotoKit) qui lit la date et le lieu des photos et fabrique les miniatures.
- `.github/workflows/ipa.yml` : un Mac de GitHub crée le projet Capacitor, compile l'app sans signature et produit `NosVoyages.ipa`.
