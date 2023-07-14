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

const configs = document.querySelectorAll(".config")
for (const config of configs) {
    if (config.type == "range") {
        config.oninput = (e) => {
            fetch("/api/tweak", {
                method: "POST",
                body: `${config.getAttribute("id")}=${config.value}`,
            })
        }
    } else if (config.type == "button") {
        config.onclick = (e) => {
            console.log("post", config.getAttribute("id"))
            fetch("/api/action", {
                method: "POST",
                body: config.getAttribute("id"),
            })
        }

    }
}
