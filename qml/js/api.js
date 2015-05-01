.pragma library

var ApiBaseUrl = "http://music.163.com/api";

var CloundMusicApi = {
    SNS_AUTH_SINA: ApiBaseUrl + "/sns/authorize/?snsType=2&clientType=pc",
    LOGIN_TOKEN_REFRESH: ApiBaseUrl + "/login/token/refresh"
};

var ApiRequest = function(url, method) {
    this.url = url;
    this.method = method || "GET";
    this.query = "";
    this.postData = "";
};

ApiRequest.prototype.setQuery = function(query) {
            for (var k in query) {
                this.query += this.query == "" ? "?" : "&";
                this.query += k + "=" + encodeURIComponent(query[k]);
            }
        };

ApiRequest.prototype.setParams = function(params) {
            for (var k in params) {
                if (this.postData != "")
                    this.postData += "&";

                this.postData += k + "=" + encodeURIComponent(params[k]);
            }
        };

ApiRequest.prototype.sendRequest = function(onSuccess, onFailure) {
            var xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function() {
                        if (xhr.readyState == XMLHttpRequest.DONE) {
                            if (xhr.status == 200) {
                                try {
                                    var resp = JSON.parse(xhr.responseText);
                                    if (resp.code == 200)
                                        onSuccess(resp);
                                    else
                                        onFailure(resp.code)
                                }
                                catch (e) {
                                    onFailure(e.toString());
                                }
                            }
                            else {
                                onFailure(xhr.status);
                            }
                        }
                    };
            xhr.open(this.method, this.url + this.query);
            if (this.method == "POST") {
                xhr.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
                xhr.setRequestHeader("Content-Length", this.postData.length);
                xhr.send(this.postData);
            }
            else {
                xhr.send(null);
            }
        };

function refreshToken(token, onSuccess, onFailure) {
    var req = new ApiRequest(CloundMusicApi.LOGIN_TOKEN_REFRESH, "POST");
    req.setParams({ cookieToken: token });
    req.sendRequest(onSuccess, onFailure);
}
