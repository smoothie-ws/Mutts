const fs = require("fs");
const path = require("path");

let project = new Project("New Project");

project.addSources("src");
const assetOptions = {
    nameBaseDir: "assets",
    destination: "assets/{dir}/{name}",
    name: "{name}",
};
project.addAssets("assets/dev/**", assetOptions);
project.addAssets("assets/fonts/**", assetOptions);
project.addAssets("assets/images/**", assetOptions);

project.addDefine("log");
project.addDefine("debug");
project.addDefine("debug_element_bounds");
project.addDefine('analyzer-optimize');
project.addParameter('-main Game');

await project.addProject("sengine");

function chainCallback(name, next) {
    const prev = callbacks[name];
    callbacks[name] = (...args) => {
        if (prev != null)
            prev(...args);
        next(...args);
    };
}

function copyHtml5Index() {
    if (platform !== "html5")
        return;

    const source = path.join(path.resolve("."), "assets", "index.html");
    const target = path.join(path.resolve("."), "build", platform, "index.html");
    if (fs.existsSync(source) && fs.existsSync(path.dirname(target)))
        fs.copyFileSync(source, target);
}

function patchElectronMain() {
    if (platform !== "debug-html5")
        return;

    const target = path.join(path.resolve("."), "build", platform, "electron.js");
    if (!fs.existsSync(target))
        return;

    let source = fs.readFileSync(target, "utf8");
    if (!source.includes("webSecurity: false")) {
        source = source.replace(
            /webPreferences:\s*{/,
            "webPreferences: {\n\t\t\twebSecurity: false,"
        );
    }
    fs.writeFileSync(target, source);
}

function patchHtml5Build() {
    copyHtml5Index();
    patchElectronMain();
}

chainCallback("postBuild", patchHtml5Build);
chainCallback("postHaxeCompilation", patchHtml5Build);

resolve(project);
