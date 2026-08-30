const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

exports.sendNotificationOnWrite = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snap, context) => {
        const data = snap.data();
        if (!data) return null;

        const type = data.type || "minor";
        const title = data.title || "UniFind";
        const body = data.body || "";
        const recipient = data.recipient; // username or "all"
        const extraData = data.extraData || {};

        try {
            let tokens = [];

            if (recipient === "all") {
                const usersSnapshot = await db.collection("users").get();
                usersSnapshot.forEach(userDoc => {
                    const token = userDoc.data().fcmToken;
                    if (token) tokens.push(token);
                });

                // Copy notification to each user for in-app display
                for (const userDoc of usersSnapshot.docs) {
                    await db.collection('users')
                        .doc(userDoc.id)
                        .collection('notifications')
                        .add(data);
                }
            } else {
                // Single recipient
                const userDoc = await db.collection("users").doc(recipient).get();
                const token = userDoc.data()?.fcmToken;
                if (token) tokens.push(token);

                // Save in-app notification
                await db.collection('users')
                    .doc(recipient)
                    .collection('notifications')
                    .add(data);
            }

            if (tokens.length > 0) {
                await admin.messaging().sendMulticast({
                    tokens,
                    notification: { title, body },
                    data: extraData
                });
            }

            console.log("✅ Notification sent:", title, body);
        } catch (error) {
            console.error("⚠️ Error sending notification:", error);
        }

        return null;
    });
