let project = new Project("New Project");

project.addSources("src");
project.addAssets("assets/**", {
    nameBaseDir: "assets",
    destination: "assets/{dir}/{name}",
    name: "{name}",
});
project.localLibraryPath = "libs";
project.addDefine("log");
project.addDefine("S2D_DEBUG_FPS");
// project.addDefine("S2D_UI_DEBUG_ELEMENT_BOUNDS");
project.addLibrary("snet");

process.shortcuts = {
    "ground": "mutts.ui.Playground.Ground"
}

await project.addProject("sengine");

resolve(project);
