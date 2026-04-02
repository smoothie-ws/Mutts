let project = new Project("New Project");

project.addSources("src");
project.addAssets("assets/**");
project.addDefine("log");
// project.addDefine("S2D_DEBUG_FPS");
// project.addDefine("S2D_UI_DEBUG_ELEMENT_BOUNDS");

await project.addProject("sengine");

resolve(project);
