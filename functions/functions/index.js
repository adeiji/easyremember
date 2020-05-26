const functions = require('firebase-functions');

const admin = require('firebase-admin')
admin.initializeApp()

exports.checkSendNotificationsEveryMinute = functions.pubsub.schedule('every 1 minutes').onRun((context) => {    
    console.log("Checking for hour " + new Date().getUTCHours())
    return sendNotifications(new Date().getUTCHours()).then(result => console.log(result)).catch(error => console.log(error))    
})

async function sendNotifications (time) {

    // Get all the schedules that contain the current time
    var scheduleSnapshot = admin.firestore().collection('schedule').where('timeSlots', 'array-contains', time)
    var retrievedSnapshot;

    const minutes = new Date().getUTCMinutes()

    // If it's the start of the hour than we send all notifications
    if (minutes !== 0) {
        if (minutes % 10 === 0) {
            retrievedSnapshot = await scheduleSnapshot.where("frequency", "==", 10).get()
        } else if (minutes % 15 === 0) {
            retrievedSnapshot = await scheduleSnapshot.where("frequency", "==", 15).get()
        } else if (minutes % 30 === 0) {
            retrievedSnapshot = await scheduleSnapshot.where("frequency", "==", 30).get()
        }
    } else {
        retrievedSnapshot = await scheduleSnapshot.where("frequency", "==", 60).get()
    }

    if (!retrievedSnapshot) {
        return
    }

    retrievedSnapshot.docs.forEach( async(schedule) => {
        // Get the device Id for the schedule and then grab all the notifications that need to be sent to this device
        const deviceId = schedule.get('deviceId')

        console.log("Retrieving fcmToken for deviceId: " + deviceId)        
        var fcmTokensSnapshot = await admin.firestore().collection('fcmTokens').where('deviceId', '==', deviceId).get()

        // If this device has no fcm tokens attached to it then don't continue because there's no device to send
        // the notifications too
        if (fcmTokensSnapshot.docs.length === 0) {
            return
        }        

        console.log("Received fcmTokens: " + fcmTokensSnapshot.docs)

        const notificationsSnapshot = await admin.firestore().collection('notifications')
            .where('deviceId', '==', deviceId)
            .where('active', '==', true).get()

        console.log("Sending notifications for deviceId: " + deviceId)
        var fcmTokensSent = []
        fcmTokensSnapshot.docs.map( (tokenDoc) => {                                
            const token = tokenDoc.get('token')

            if (fcmTokensSent.indexOf(token) !== -1) {
                return
            }

            fcmTokensSent.push(token)

            notificationsSnapshot.docs.forEach( async(notificationSnapshot) => {
                var title = notificationSnapshot.get("caption")
                var body = notificationSnapshot.get("description")      
                var id = notificationSnapshot.get("id")     
                var creationDate = notificationSnapshot.get("creationDate")                                                 
                sendNotification(title, body, token, id, creationDate, tokenDoc.id)                    
            })            
        })
    });
}


function sendNotification (title, body, fcmToken, id, creationDate, fcmTokenDocId) {

    var message = {
        "token": fcmToken,
        "notification": {
            "title": title,
            "body": body,            
        }, "data": {            
            "notificationId": id,
            "creationDate": `${creationDate}`
        }, "apns": {
            "payload": {
                "aps": {
                    "category": "NOTIFICATIONS"
                }                
            }
        }
    }

    admin.messaging().send(message).then().catch(error => {
        if (error.errorInfo.code === 'messaging/registration-token-not-registered') {
            admin.firestore().collection('fcmTokens').doc(fcmTokenDocId).delete()
        }
        console.log(error)
    })
}