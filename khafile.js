let project = new Project("New Project");

project.addSources("src");
project.addAssets("assets/**");

project.addDefine("log");
project.addDefine("debug");
project.addDefine("debug_element_bounds");
project.addDefine('analyzer-optimize');
project.addParameter('-main Game');

await project.addProject("sengine");

resolve(project);
