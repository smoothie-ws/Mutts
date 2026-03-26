let project = new Project("New Project");

project.addSources("src");
project.addDefine("S2D_DEBUG_FPS");
project.addDefine("S2D_UI_DEBUG_ELEMENT_BOUNDS");

process.shortcuts = {
    "ground": "mutts.ui.Playground.Ground"
}

await project.addProject("sengine");

resolve(project);
