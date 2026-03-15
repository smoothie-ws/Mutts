package;

import se.App;
import se.Timer;
import se.math.SMath;
import se.animation.Easing;
import se.animation.ColorAnimation;
import s2d.Element;
import s2d.WindowScene;
import s2d.elements.Text;
import s2d.elements.InteractiveElement;
import s2d.elements.shapes.RectangleRounded;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
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
			$fontSize = 32;
		}
	}

	@:ui.markup
	static function markup() {
		@use style;

		var rect = @rectangle {
			$anchors.fill($parent);
			$anchors.margins = 50;

			new Timer(() -> $rotate(radians(1), vec2(375, 250)), 0.01).loop();

			@text("Hello, world!") {
				$anchors.fill($parent);
				$tag = "text";
				$color = Black;
			}

			@interactive {
				$anchors.fill($parent);

				$onMouseEntered((x, y) -> new ColorAnimation(rect.color, Green, 0.5, c -> rect.color = c).ease(Easing.OutQuart).start());
				$onMouseExited((x, y) -> new ColorAnimation(rect.color, Red, 0.5, c -> rect.color = c).ease(Easing.OutQuart).start());
				$onHoveredDirty(h -> {
					se.App.input.mouse.cursor = h ? Pointer : Default;
					if (h)
						rect.upscale(1.2, vec2(375, 250));
					else
						rect.upscale(1 / 1.2, vec2(375, 250));
				});
			}
		}
	}
}
