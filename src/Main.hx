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

	// global style that can be referenced

	@:ui.style
	static function style() {}

	@:ui.markup
	static function markup() {
		// inline style that applies instantly on the parent
		@style {
			var __s0 = (e:s2d.widgets.ImageWidget) -> {
				// функция, которая применяется к отобранным элементам
				function apply(r:Rectangle) {
					r.color = Red;
				}
				// моментальное применение
				for (c in e.select(Children(ByType(Rectangle))))
					apply(cast c);
				// отслеживание
				e.onChildAdded(c -> if (c.matches(ByType(Rectangle))) apply(cast c));
			}

			@rule(image > rectangle) {
				color = red;
			}

			@rule(!hovered, -0) {
				color = Black;
				anchors.margins = 50;
				anchors.fill = @args [parent];
			}
		}

		@rectangle.rounded(20) {
			@text("Hello, World!", {
				"color": White,
				"alignment": AlignCenter,
				"anchors.margins": 50,
				"anchors.fill": @args[parent],
				"fontSize": 64
			}) {};
		}
	}
}
