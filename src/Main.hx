package;

import se.animation.Easing;
import se.animation.NumberAnimation;
import se.animation.Animation;
import se.animation.Action;
import se.App;
import se.system.input.Mouse;
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

	static function setup(window) {
		var scene = new WindowScene(window);
		scene.root.padding = 50;
		markup(scene.root);
	}

	@:ui.style
	static function style() {
		@element {
			$anchors.fill($parent);
			$anchors.margins = 50;
		}

		@drawable([color]) {
			$color = Red;
		}

		@rectangle.rounded {
			$color = Black;
			$clip = true;

			@text {
				// $color = Red;
				$alignment = AlignCenter;
				$fontSize = 64;
			}
		}
	}

	@:ui.markup
	static function markup() {
		@use style;

		var rect = @rectangle.rounded {
			@text("Hello, world!") {}
		}
	}
}
