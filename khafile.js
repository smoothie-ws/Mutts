let project = new Project("New Project");

project.addSources("src");
project.addAssets("assets/**", {
    nameBaseDir: "assets",
    destination: "assets/{dir}/{name}",
    name: "{name}",
});
project.localLibraryPath = "libs";
project.addDefine("log");
project.addLibrary("snet");

process.shortcuts = {
    "ground": "mutts.ui.Playground.Ground"
}

await project.addProject("sengine");

resolve(project);
