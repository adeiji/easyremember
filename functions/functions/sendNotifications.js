async function sendNotifications (admin, time, debug) {

    // Get all the schedules that contain the current time
    var scheduleSnapshot = admin.firestore().collection('schedule').where('timeSlots', 'array-contains', time)
    var retrievedSnapshots = []

    const minutes = new Date().getUTCMinutes()

    if (debug) {
        retrievedSnapshots.push(await scheduleSnapshot.get())
    } else if (minutes !== 0) { // If it's the start of the hour than we send all notifications
        if (minutes % 30 === 0) {
            console.log("Retrieving schedules for frequency 30...")
            retrievedSnapshots.push(await scheduleSnapshot.where("frequency", "==", 30).get())
        } 

        if (minutes % 15 === 0) {
            console.log("Retrieving schedules for frequency 15...")
            retrievedSnapshots.push(await scheduleSnapshot.where("frequency", "==", 15).get())
        }
        
        if (minutes % 10 === 0) {
            console.log("Retrieving schedules for frequency 10...")
            retrievedSnapshots.push(await scheduleSnapshot.where("frequency", "==", 10).get())
        }
    } else {
        console.log("Retrieving schedules for frequency 60...")
        retrievedSnapshots.push(await scheduleSnapshot.get())
    }

    retrievedSnapshots.forEach (retrievedSnapshot => {
        if (!retrievedSnapshot.docs) {
            return
        }
        
        retrievedSnapshot.docs.forEach( async(schedule) => {
            // Get the device Id for the schedule and then grab all the notifications that need to be sent to this device
            const deviceId = schedule.get('deviceId')
            const isPaused = schedule.get('paused')

            if (isPaused === true) { return }
    
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
    
                var index = 0
    
                notificationsSnapshot.docs.forEach( async(notificationSnapshot) => {                
                    if (debug === true && index > 0) {                    
                        return
                    }                
    
                    sendNotification(notificationSnapshot, schedule.get("style"), token, tokenDoc.id, admin)                                        
                    index = index + 1
                })       
                
                let writingPractice = schedule.get("writingPractice")

                if (writingPractice === undefined || writingPractice === true ) {
                    sendSentenceNotification(notificationsSnapshot, token, schedule.get("sentence"), admin)
                    sendSentenceNotification(notificationsSnapshot, token, schedule.get("sentence"), admin)
                }                
            })
        });
    })
}

function sendSentenceNotification (notificationsSnapshot, fcmToken, previousSentence, admin) {
    var counter = 0
    var words = []
    var usedIndexes = []

    while (counter < notificationsSnapshot.docs.length && counter < 5) {
        var index = Math.floor(Math.random() * notificationsSnapshot.docs.length)
        
        while (usedIndexes.indexOf(index) !== -1) {
            index = Math.floor(Math.random() * notificationsSnapshot.docs.length)
        }

        words.push(getRandomWordFromSentence(notificationsSnapshot.docs[index].get('caption')))
        usedIndexes.push(index)

        counter = counter + 1;        
    }
    
    var hiddenData = ""

    if (previousSentence) {
        hiddenData = `Your previous sentence was:\n'${previousSentence}'\n\nYou can try keeping the same theme, or start something from scratch.`
    }

    var message = {
        "token": fcmToken,
        "notification": {
            "title": "Writing Practice - press and hold or swipe down to write your sentence",
            "body": `Try to write at least one sentence using one or all of these words:\n${words.join(", ")}`,            
        }, "data": {            
            "hiddenData": hiddenData,
        }, "apns": {
            "payload": {
                "aps": {
                    "category": "SENTENCE"
                }                
            }
        }
    }

    admin.messaging().send(message).then().catch(error => {        
        console.log(error)
    })
}

function getRandomWordFromSentence (sentence) {
    const sentenceWords = sentence.split(" ")
    return randomWord = sentenceWords[Math.floor(Math.random() * sentenceWords.length)]
}

function sendNotification (notificationSnapshot, style, fcmToken, fcmTokenDocId, admin) {

    var title = ""
    var body = ""
    var hiddenData = ""

    console.log("Sending notification")

    if (style === "Show Everything") {
        title = notificationSnapshot.get("caption")
        body = notificationSnapshot.get("description")
    } else if (style === "Flashcard - Hide Content") {
        title = "Press and hold or swipe down to see content..."
        body = notificationSnapshot.get("caption")
        hiddenData = notificationSnapshot.get("description")
    } else if (style === "Flashcard - Hide Caption") {
        title = "Press and hold or swipe down to see content..."
        hiddenData = notificationSnapshot.get("caption")
        body = notificationSnapshot.get("description")
    }

    console.log("Notification message created")
    
    var id = notificationSnapshot.get("id")     
    var creationDate = notificationSnapshot.get("creationDate")          
                                         
    var message = {
        "token": fcmToken,
        "notification": {
            "title": title,
            "body": body,            
        }, "data": {            
            "notificationId": id,
            "hiddenData": hiddenData,
            "creationDate": `${creationDate}`
        }, "apns": {
            "payload": {
                "aps": {
                    "category": "NOTIFICATIONS"
                }                
            }
        }
    }

    console.log(message)

    admin.messaging().send(message).then().catch(error => {
        if (error.errorInfo.code === 'messaging/registration-token-not-registered') {
            admin.firestore().collection('fcmTokens').doc(fcmTokenDocId).delete()
        }
        console.log(error)
    })
}

module.exports = { sendNotifications }