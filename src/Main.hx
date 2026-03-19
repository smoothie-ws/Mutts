package;

import s.markup.Alignment;
import s.markup.elements.Text;
import s.system.App;
import s.system.Timer;
import s.system.math.SMath;
import s.system.animation.Easing;
import s.system.animation.ColorAnimation;
import s.markup.WindowScene;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
@:app.framebuffer(samplesPerPixel = 4, verticalSync = false)
class Main extends s.system.App implements s.markup.Markup {
	public static function main() {
		var scene = new WindowScene(window);
		scene.root.padding = 50;
		markup(scene.root);

		var a = new StringBuf();
		var b = new StringBuf();
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

				var r = @rectangle {
					$margins = 50;
					$width = 100;
					$anchors.top = $parent.top;
					$anchors.left = $parent.left;
					$anchors.bottom = $parent.bottom;
					$color = Green;
				}

				@rectangle {
					$margins = 50;
					$padding = 50;
					$width = 100;
					$anchors.top = $parent.top;
					$anchors.bottom = $parent.bottom;
					$anchors.left = r.right;
					$anchors.right = $parent.right;
					$color = Green;

					@rectangle {
						$width = "25vw";
						$height = "25vh";
						$anchors.fill($parent);
						$color = Blue;

						@text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.") {
							$width = "50%";
							$height = "50%";
							$color = Yellow;
							$fontSize = 32;
							$elideMode = Left;
                            $wrapMode = Anywhere;
							$alignment = AlignCenter;
							$anchors.centerIn($parent);

							App.input.mouse.onButtonPressed(Left, (x, y) -> {
								if ($alignment & AlignLeft != 0)
									$alignment = AlignHCenter;
								else if ($alignment & AlignHCenter != 0)
									$alignment = AlignRight;
								else
									$alignment = AlignLeft;
								$alignment = $alignment | AlignVCenter;
							});
							App.input.mouse.onScrolled(d -> $lineHeight += d);
						}
					}
				}
			}
		}
	}
}
