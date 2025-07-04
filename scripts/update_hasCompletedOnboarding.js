const admin = require("firebase-admin");

// Replace with the path to your service account key JSON file
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function updateAllUsers() {
  const usersRef = db.collection("users");
  const snapshot = await usersRef.get();

  let updatedCount = 0;
  for (const doc of snapshot.docs) {
    await doc.ref.set({ hasCompletedOnboarding: true }, { merge: true });
    updatedCount++;
    console.log(`Updated user: ${doc.id}`);
  }
  console.log(`Done! Updated ${updatedCount} users.`);
}

updateAllUsers().catch(console.error);
