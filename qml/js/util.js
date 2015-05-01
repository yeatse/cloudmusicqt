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
