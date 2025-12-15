const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendUnfinishedTasksNotification = functions.pubsub
  .schedule("15 14 * * *") // la ora 21:00 zilnic
  .timeZone("Europe/Oslo") // ora Norvegiei
  .onRun(async () => {
    const db = admin.firestore();
    const usersSnapshot = await db.collection("users").get();

    const currentDate = new Date();
    const today = currentDate.toLocaleDateString("en-GB", { weekday: "long" }); // Luni, Tirsdag, etc.
    const year = currentDate.getFullYear();
    const week = getWeekNumber(currentDate);
    const currentWeekId = `Y${year}-W${week}`;

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const fcmToken = userDoc.data().fcmToken;

      if (!fcmToken) continue; // dacă nu are token, sărim peste el

      const dayRef = db
        .collection("users")
        .doc(userId)
        .collection("userProgress")
        .doc(currentWeekId)
        .collection("days")
        .doc(getNorwegianDay(today))
        .collection("locations");

      const locationsSnap = await dayRef.get();
      if (locationsSnap.empty) continue;

      let hasIncomplete = false;
      locationsSnap.forEach((loc) => {
        const data = loc.data();
        if (data.completed === false || data.completed === undefined) {
          hasIncomplete = true;
        }
      });

      if (hasIncomplete) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "⚠️ Ikke mist streaken din!",
            body: "Du har fortsatt oppgaver igjen i dag. Fullfør dem nå for å beholde streaken 🔥",
          },
        });
      }
    }

    return null;
  });

exports.sendDailyMotivationNotification = functions.pubsub
  .schedule("40 19 * * *") // în fiecare zi la ora 18:15 ora României
  .timeZone("Europe/Bucharest") // ora României
  .onRun(async () => {
    const db = admin.firestore();
    const usersSnapshot = await db.collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const fcmToken = userDoc.data().fcmToken;

      if (!fcmToken) continue; // skip dacă nu are token

      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "🧹 Det er tid for rengjøring!",
            body: "Gjennomfør dagens oppgaver og hold streaken din i live 🔥",
          },
        });
        console.log(`✅ Sent daily motivation to ${userId}`);
      } catch (error) {
        console.error(`❌ Failed to send notification to ${userId}:`, error);
      }
    }

    console.log("✅ Daily motivation notifications sent to all users");
    return null;
  });

function getWeekNumber(date) {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
}

function getNorwegianDay(englishDay) {
  const map = {
    Monday: "Mandag",
    Tuesday: "Tirsdag",
    Wednesday: "Onsdag",
    Thursday: "Torsdag",
    Friday: "Fredag",
    Saturday: "Lørdag",
    Sunday: "Søndag",
  };
  return map[englishDay] || englishDay;
}