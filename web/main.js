const EFFECTS = [ "elasticbubbles", "swirl", "rainbow", "texteffects", "textplayground", "popper" ];

const moduleOptions = document.getElementById("modules");

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
                fetch("/api/tweak/number", {
                    method: "POST",
                    body: `${config.getAttribute("id")}=${config.value}`,
                })
            }
        } else if (config instanceof HTMLSelectElement) {
            config.oninput = () => {
                fetch("/api/tweak/string", {
                    method: "POST",
                    body: `${config.name}=${config.value}`,
                })
            }
        } else if (config.type == "text") {
            config.oninput = (e) => {
                fetch("/api/tweak/string", {
                    method: "POST",
                    body: `${config.name}=${config.value}`,
                })
            }
        } else if (config.type == "color") {
            config.oninput = (e) => {
                fetch("/api/tweak/color", {
                    method: "POST",
                    body: `${config.name}=${config.value}`
                })
            }

        } else if (config instanceof HTMLButtonElement) {
            config.onclick = (e) => {
                fetch("/api/tweak/action", {
                    method: "POST",
                    body: `${config.name}=${config.value}`
                })
            }
        } else {
            console.log("unknown tweak type", config.type)
        }
    }
}

const tweaksContainer = document.getElementById("module-tweaks");

function setupModules(current) {
    moduleOptions.onchange = () => {
        LoadModule(moduleOptions.value)
    }

    moduleOptions.innerHTML = EFFECTS
        .map(name => `<option value="${name}">${name}</option>`)
        .join('');

    moduleOptions.value = current;
}

function GetTweaks() {
    fetch("/api/tweaks", { method: "GET" })
        .then(response => response.text())
        .then(text => tweaksContainer.innerHTML = text)
        .then(() => {
            attachListeners();
            setupModules(tweaksContainer.children[0].id);
        });
}

function LoadModule(module) {
    console.log(module);
    fetch("/api/module", { method: "POST", body: module })
        .then(() => GetTweaks());
}

GetTweaks();
window.onfocus = requestUpdate
