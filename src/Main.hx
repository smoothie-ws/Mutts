package;

import se.App;
import se.Timer;
import se.math.SMath;
import se.animation.Easing;
import se.animation.ColorAnimation;
import s2d.WindowScene;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
@:app.framebuffer(samplesPerPixel = 4)
class Main extends se.App implements s2d.Markup {
	public static function main() {
		var scene = new WindowScene(window);
		scene.root.padding = 50;
		markup(scene.root);
	}

	@:ui.style
	static function style() {
		@text {
			$alignment = AlignCenter;
		}
	}

	@:ui.markup
	static function markup() {
		@use style;

		$tag = "root";

		var rect = @rectangle {
            $anchors.fill(parent);
            $color = Black;
			$tag = "rectangle";

			// new Timer(() -> $transform.rotate(radians(1), vec2(375, 250)), 0.01).loop();

			// @text("Hello, world!") {
			// 	$anchors.fill($parent);
			// 	$tag = "text";
			// 	$color = Black;
			// }

			// @interactive {
			// 	$anchors.fill($parent);

			// 	var anim = new ColorAnimation(0.5, c -> rect.color = c).ease(Easing.OutQuart);
			// 	$onMouseEntered((x, y) -> {
			// 		anim.stop();
			// 		anim.start(rect.color, Green);
			// 	});
			// 	$onMouseExited((x, y) -> {
			// 		anim.stop();
			// 		anim.start(rect.color, Red);
			// 	});
			// 	$onHoveredDirty(h -> se.App.input.mouse.cursor = h ? Pointer : Default);
			// }
		}
	}
}
