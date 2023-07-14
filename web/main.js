async function requestUpdate() {
    const response = await fetch("/api/update", {
        method: "POST",
    });
    const values = await response.json();
    for (const id in values) {
        const v = values[id];
        const item = document.getElementById(id);
        if (item) {
            item.value = v;
        }
    }
}

const reload = document.getElementById("reload")
if (reload) {
    reload.onclick = async () => {
        await fetch("/action/reload", { method: "POST" });
        await requestUpdate();
    }
}

function attachListeners() {
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
}

const tweaksContainer = document.getElementById("module-tweaks");

function LoadModule(module) {
    console.log(module);
    fetch("/api/module", { method: "POST", body: module })
        .then(response => response.text())
        .then(text => tweaksContainer.innerHTML = text)
        .then(() => attachListeners());
}

{
    const EFFECTS = [ "elasticbubbles", "texteffects", "rainbow", "swirl" ];

    const moduleOptions = document.getElementById("modules");

    moduleOptions.innerHTML = EFFECTS
        .map(name => `<button type="button" name=${name} onclick="LoadModule(this.name)">${name}</button>`)
        .join('');
}

LoadModule("elasticbubbles")

window.onfocus = requestUpdate
