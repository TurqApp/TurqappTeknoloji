const admin = require('firebase-admin');
const fs = require('fs');
const key='/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-6a2cb82e5b.json';
const cred=JSON.parse(fs.readFileSync(key,'utf8'));
const app=admin.initializeApp({credential:admin.credential.cert(cred)},'check-isbul');
const db=app.firestore();
(async()=>{
  const [a,b]=await Promise.all([db.collection('IsBul').get(), db.collection('isBul').get()]);
  console.log(JSON.stringify({IsBul:a.size,isBul:b.size},null,2));
})().catch(e=>{console.error(String(e));process.exit(1);});
