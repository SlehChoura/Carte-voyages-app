// Construit www/index.html : la page web/app.html avec toutes les bibliothèques intégrées (fonctionne hors-ligne, sauf le fond de carte).
const fs=require('fs'),path=require('path');
const root=path.join(__dirname,'..');const nm=p=>path.join(root,'node_modules',p);
const c=require('i18n-iso-countries');c.registerLocale(require('i18n-iso-countries/langs/fr.json'));
const topo=JSON.parse(fs.readFileSync(nm('world-atlas/countries-50m.json')));
const extra={'Kosovo':['XK','Kosovo'],'N. Cyprus':['CY','Chypre'],'Somaliland':['SO','Somalie'],'Siachen Glacier':['IN','Inde'],'Indian Ocean Ter.':['AU','Australie']};
topo.objects.countries.geometries.forEach(g=>{let a=g.id?c.numericToAlpha2(g.id):null;let n=a?c.getName(a,'fr'):null;
  if(!a&&extra[g.properties.name]){[a,n]=extra[g.properties.name]}
  g.properties={a:a||'',n:n||g.properties.name};});
let h=fs.readFileSync(path.join(root,'web/app.html'),'utf8');
const rep={'/*LEAFLET_CSS*/':'leaflet/dist/leaflet.css','/*CLUSTER_CSS*/':'leaflet.markercluster/dist/MarkerCluster.css','/*LEAFLET_JS*/':'leaflet/dist/leaflet.js','/*CLUSTER_JS*/':'leaflet.markercluster/dist/leaflet.markercluster.js','/*EXIFR_JS*/':'exifr/dist/full.umd.js','/*TOPO_JS*/':'topojson-client/dist/topojson-client.min.js'};
for(const[k,f]of Object.entries(rep)){const v=fs.readFileSync(nm(f),'utf8').replace(/\/\/# sourceMappingURL=.*$/gm,'');const i=h.indexOf(k);if(i<0)throw new Error('missing '+k);h=h.slice(0,i)+v+h.slice(i+k.length)}
const i=h.indexOf('/*COUNTRIES*/');h=h.slice(0,i)+JSON.stringify(topo)+h.slice(i+13);
fs.mkdirSync(path.join(root,'www'),{recursive:true});
fs.writeFileSync(path.join(root,'www/index.html'),h);
console.log('www/index.html',Math.round(h.length/1024),'Ko');
