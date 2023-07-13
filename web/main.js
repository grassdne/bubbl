fetch("/configure", {
    method: "POST",
    credentials: "same-origin",
    headers: {
        "Content-Type": "text/plain",
    },
    body: "Hello, World!",
})

const reload = document.getElementById("reload")
reload.onclick = function() {
    fetch("/action/reload", {
        method: "POST",
        credentials: "same-origin",
        headers: {
            "Content-Type": "text/plain",
        },
    })
}
