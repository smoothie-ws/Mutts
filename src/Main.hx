package;

import s2d.elements.Interactive;
import s2d.elements.shapes.RectangleRounded;
import se.animation.Easing;
import se.App;
import se.system.input.Mouse;
import se.animation.ColorAnimation;
import s2d.Element;
import s2d.WindowScene;
import s2d.elements.Text;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
class Main extends se.App implements s2d.Markup {
	public static function main() {
		var scene = new WindowScene(window);
		scene.color = Blue;
		scene.root.padding = 50;
		markup(scene.root);
	}

	@:ui.style
	static function style() {
		@drawable {
			$color = Red;
		}

		@text {
			$alignment = AlignCenter;
			$fontSize = 32;
		}
	}

	@:ui.markup
	static function markup() {
		@use style;

		var rect = @interactive(rectangle.rounded) {
			$onMouseScrolled(m -> rect.radius += m.delta * 10);
			$onMouseEntered((x, y) -> new ColorAnimation($color, White, 0.5, c -> $color = c).ease(Easing.OutQuart).start());
			$onMouseExited((x, y) -> new ColorAnimation($color, Black, 0.5, c -> $color = c).ease(Easing.OutQuart).start());
			$onHoveredDirty(h -> se.App.input.mouse.cursor = h ? Pointer : Default);

			$anchors.fill($parent);
			$anchors.margins = 50;

			@text("Hello, world!") {
				$tag = "text";

				$color = Black;
				$anchors.fill(rect);
			}
		}
	}
}
