const functions = require('firebase-functions');

const admin = require('firebase-admin')
admin.initializeApp()

exports.checkSendNotificationsEveryMinute = functions.pubsub.schedule('every 1 minutes').onRun((context) => {
    console.log("Hit function and checking for hour: " + new Date().getUTCHours())

    return sendNotifications(new Date().getUTCHours()).then(result => console.log(result)).catch(error => console.log(error))    
})

async function sendNotifications (time) {

    // Get all the schedules that contain the current time
    var scheduleSnapshot = admin.firestore().collection('schedule').where('timeSlots', 'array-contains', time)
    
    const minutes = new Date().getUTCMinutes()
    console.log("Current minutes " + minutes)
    // If it's the start of the hour than we send all notifications
    if (minutes !== 0) {
        if (minutes % 10 === 0) {
            console.log("Retrieving schedules with a frequency of 10")
            scheduleSnapshot = await scheduleSnapshot.where("frequency", "==", 10).get()
        } else if (minutes % 15 === 0) {
            console.log("Retrieving schedules with a frequency of 15")
            scheduleSnapshot = await scheduleSnapshot.where("frequency", "==", 15).get()
        } else if (minutes % 30 === 0) {
            console.log("Retrieving schedules with a frequency of 30")
            scheduleSnapshot = await scheduleSnapshot.where("frequency", "==", 30).get()
        }
    } else {
        console.log("Retrieving schedules with a frequency of 60")
        scheduleSnapshot = await scheduleSnapshot.where("frequency", "==", 60).get()
    }

    if (!scheduleSnapshot.docs) {
        console.log("No schedules match this criteria")
        return
    }

    scheduleSnapshot.docs.forEach( async(scheduleSnapshot) => {
        // Get the device Id for the schedule and then grab all the notifications that need to be sent to this device
        const deviceId = scheduleSnapshot.get('deviceId')
        var fcmTokensSnapshot = await admin.firestore().collection('fcmTokens').where('deviceId', '==', deviceId).get()
        
        // If this device has no fcm tokens attached to it then don't continue because there's no device to send
        // the notifications too
        if (fcmTokensSnapshot.docs.length === 0) {
            return
        }

        const notificationsSnapshot = await admin.firestore().collection('notifications')
            .where('deviceId', '==', deviceId)
            .where('active', '==', true).get()

        notificationsSnapshot.docs.forEach( async(notificationSnapshot) => {
            var title = notificationSnapshot.get("caption")
            var body = notificationSnapshot.get("description")

            fcmTokensSnapshot.docs.map( (tokenDoc) => tokenDoc.get('token')).forEach(token => {         
                console.log("Sending notification for token: " + token)       
                sendNotification(title, body, token)
            })            
        })
    });
}


function sendNotification (title, body, fcmToken) {

    var message = {
        "token": fcmToken,
        "notification": {
            "title": title,
            "body": body,
        }
    }

    console.log("Notification being sent at " + new Date())

    admin.messaging().send(message).then(response => console.log(response)) .catch((error) => console.log(error))
}