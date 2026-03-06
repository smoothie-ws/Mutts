package;

import se.system.Window;
import s2d.WindowScene;
import s2d.elements.Text;
import s2d.elements.shapes.Rectangle;

class Main implements s2d.Markup {
	public static function main() {
		se.App.start({
			title: "Mutts",
			width: 1920,
			height: 1080
		}, setup);
	}

	static function setup(window:Window) {
		var scene = new WindowScene(window);
		scene.active = true;
		scene.padding = 50;
		markup(scene);
	}

	@:ui.markup
	static function markup() {
		var a = @rectangle.rounded(20, {
			color: Black,
            clip: true,
			"anchors.fill": @args[parent],
		}) {
			@text("Hello, World!", {
				"color": Red,
				"alignment": AlignCenter,
				"anchors.margins": 50,
				"anchors.fill": @args[parent],
				"fontSize": 64
			}) {};
		}
	}
}
