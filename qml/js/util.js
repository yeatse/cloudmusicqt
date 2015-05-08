.pragma library

function formatTime(millisec) {
    var secs = Math.ceil(millisec / 1000);
    var sec = secs % 60;
    var min = Math.floor(secs / 60);
    return paddingLeft(min) + ":" + paddingLeft(sec);
}

function paddingLeft(num){
    if (num < 10) return "0"+num;
    else return ""+num;
}

function verNameToVerCode(vername) {
    var sl = vername.split(".");
    if (sl.length == 3) {
        var major = Number(sl[0]), minor = Number(sl[1]), patch = Number(sl[2]);
        return (major << 16) + (minor << 8) + patch;
    }
    else {
        return 0;
    }
}
