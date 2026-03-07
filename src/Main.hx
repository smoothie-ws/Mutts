package;

import se.system.Window;
import s2d.WindowScene;
import s2d.Element;
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

	@:ui.style
	static function style() {
		@rule(a | b) {
			anchors.fill = @args [parent];
			anchors.margins = 50;
		}
		@text {
			color = Red;
			alignment = AlignCenter;
			fontSize = 64;
		}
		@rectangle.rounded {
			color = Black;
			clip = true;
		}
	}

	@:ui.markup
	static function markup() {
		// @use style;

		var a = @rectangle.rounded(20) {
			@text("Hello, World!") {};
		}
	}
}
