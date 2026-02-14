const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Suppression complète du compte utilisateur :
 * - Firebase Auth
 * - Document Firestore /users/{uid}
 *
 * ⚠️ Ne supprime PAS les personnages / campagnes
 */
exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Utilisateur non authentifié"
    );
  }

  const uid = context.auth.uid;

  try {
    // 1️⃣ Suppression Firestore
    await admin.firestore().collection("users").doc(uid).delete();

    // 2️⃣ Suppression Auth
    await admin.auth().deleteUser(uid);

    return { success: true };
  } catch (error) {
    console.error("Delete account error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Erreur lors de la suppression du compte"
    );
  }
});
