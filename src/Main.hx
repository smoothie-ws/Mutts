package;

import s.markup.Alignment;
import s.markup.elements.Text;
import s.App;
import s.Timer;
import s.math.SMath;
import s.Interpolation;
import s.animation.ColorAnimation;
import s.markup.WindowScene;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
@:app.framebuffer(verticalSync = false)
class Main extends s.App implements s.markup.Markup {
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

		var img = @image("teoria_veroyatnostei2") {
			$anchors.fill($parent);
			$fillMode = Contain;
			App.input.mouse.onButtonPressed(Left, (x, y) -> {
				img.sampling = switch img.sampling {
					case Nearest: Bilinear;
					case Bilinear: Prefiltered;
					case Prefiltered: Trilinear;
					case Trilinear: Nearest;
				}
			});
			// new Timer(() -> $transform.rotation += 0.01, 0.01).loop();
		}

		var rect = @rectangle(10) {
			$x = 100;
			$y = 200;
			$height = 350;
			$color = Black;
			$anchors.left = $parent.left;
			$anchors.right = $parent.right;

			// new Timer(() -> $transform.rotate(0.01, 350, 375), 0.01).loop();

			@label("ASDASDASDSAadsda afaf mw19j311mrASDASDASDSAadsda afaf mw19j311mr") {
				$anchors.fill($parent);
				$color = Red;
				$fontSize = 32;
				$elideMode = ElideMiddle;
				$alignment = AlignRight;
				// $wrapMode = WrapAnywhere;

				// $transform.rotation = radians(45);

				App.input.mouse.onScrolled(d -> $fontSize += d);
				App.input.mouse.onButtonPressed(Left, (x, y) -> {
					if ($alignment & AlignTop != 0)
						$alignment = AlignVCenter;
					else if ($alignment & AlignVCenter != 0)
						$alignment = AlignBottom;
					else
						$alignment = AlignTop;
					$alignment = $alignment | AlignHCenter;
					trace($alignment);
				});
			}
		}
	}
}
