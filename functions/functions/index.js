const functions = require('firebase-functions');
const { sendNotifications } = require('./sendNotifications')

const admin = require('firebase-admin')
admin.initializeApp()

exports.checkSendNotificationsEveryMinute = functions.pubsub.schedule('every 1 minutes').onRun((context) => {    
    console.log("Checking for hour " + new Date().getUTCHours() + " and minute " + new Date().getUTCMinutes())
    return sendNotifications(new Date().getUTCHours()).then(result => console.log(result)).catch(error => console.log(error))    
})