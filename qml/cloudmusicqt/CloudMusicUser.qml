import QtQuick 1.1
import "../js/api.js" as Api

QtObject {
    id: user

    property bool loggedIn: false

    signal userChanged;

    function initialize() {
        var token = qmlApi.getCookieToken()
        loggedIn = token != ""
        userChanged()
        if (loggedIn) {
            var s = new Function()
            var f = function(err) {
                console.log("refresh token failed: ", f)
                loggedIn = false
                userChanged()
            }
            Api.refreshToken(token, s, f)
        }
    }
}
