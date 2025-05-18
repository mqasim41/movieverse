const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize the Admin SDK
admin.initializeApp();

exports.newReviewNotify = functions
    .region("asia-south1") // or your Firestore region
    .firestore
    .document("users/{uid}/reviews/{reviewId}")
    .onCreate(async (snap, ctx) => {
      const review = snap.data();
      const movieTitle = review.movieTitle;

      if (!movieTitle) {
        return null;
      }

      const uid = ctx.params.uid;
      const followersSnap = await admin
          .firestore()
          .collection("followers")
          .doc(uid)
          .get();

      const tokens = followersSnap.exists ?
      followersSnap.data().deviceTokens || [] :
      [];

      if (tokens.length === 0) {
        return null;
      }

      const message = {
        notification: {
          title: "New review 🚀",
          body: movieTitle,
        },
        tokens,
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(
          `Sent to ${response.successCount} devices, ` +
      `${response.failureCount} failures.`,
      );

      return null;
    });
