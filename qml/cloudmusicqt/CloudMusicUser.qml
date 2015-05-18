import QtQuick 1.1
import "../js/api.js" as Api

QtObject {
    id: user

    property bool loggedIn: false

    signal userChanged;

    function initialize() {
        var token = qmlApi.getCookieToken()
        var uid = qmlApi.getUserId()
        loggedIn = token != "" && uid != ""
        userChanged()
        if (loggedIn) {
            collector.refresh()
            refreshUserToken(token)
        }
    }

    function refreshUserToken(token) {
        var f = function(err) {
            console.log("refresh token failed: ", err)
            if (err != 0) {
                loggedIn = false
                userChanged()
            }
        }
        Api.refreshToken(token, new Function(), f)
    }
}
