const admin = require('firebase-admin')
var serviceAccount = require("./config/keyFile.json");
const { sendNotifications } = require('./sendNotifications')

admin.initializeApp(serviceAccount)
sendNotifications(admin, 4, true)

