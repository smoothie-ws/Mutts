let project = new Project("New Project");

project.addSources("src");
const assetOptions = {
    nameBaseDir: "assets",
    destination: "assets/{dir}/{name}",
    name: "{name}",
};
project.addAssets("assets/fonts/**", assetOptions);
project.addAssets("assets/images/**", assetOptions);

project.addDefine("log");
project.addDefine("debug");
project.addDefine("debug_element_bounds");
project.addDefine('analyzer-optimize');
project.addDefine('kha_html5_disable_automatic_size_adjust');
project.addParameter('-main Game');

await project.addProject("sengine");

resolve(project);
