package;

import s.system.App;
import s.system.Timer;
import s.system.math.SMath;
import s.system.animation.Easing;
import s.system.animation.ColorAnimation;
import s.markup.WindowScene;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
@:app.framebuffer(samplesPerPixel = 4)
class Main extends s.system.App implements s.markup.Markup {
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

		var rect = @rectangle {
			$anchors.fill($parent);
			$color = Black;
			$tag = "rectangle";
			$padding = 50;

			@rectangle {
				$anchors.fill($parent);
				$color = Red;

				@rectangle {
					$margins = 50;
					$width = 100;
					$anchors.top = $parent.top;
					$anchors.left = $parent.left;
					$anchors.bottom = $parent.bottom;
					$color = Green;
				}

				@rectangle {
					$margins = 50;
					$width = 100;
					$anchors.top = $parent.top;
					$anchors.bottom = $parent.bottom;
					$anchors.right = $parent.right;
					$color = Green;
				}
			}
		}
	}
}
