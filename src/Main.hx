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
@:app.framebuffer(samplesPerPixel = 4, verticalSync = false)
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

					@ellipse(30) {
						$anchors.fill($parent);
						$color = Black;
					}
				}

				@rectangle {
					$margins = 50;
					$padding = 50;
					$anchors.top = $parent.top;
					$anchors.bottom = $parent.bottom;
					$anchors.left = r.right;
					$anchors.right = $parent.right;
					$color = Black;

					var grad = @gradient.linear {
						$stops = [
							{color: White, position: 0.0},
							{color: Red, position: 0.5},
							{color: Black, position: 1.0}
						];
						$interpolation = Interpolation.InQuart;
						$anchors.fill($parent);
						$padding = 50;
						$width = 100;

						App.input.mouse.onMoved((x, y, dx, dy) -> $start = grad.mapFromGlobalNormalized(x, y));

						@triangle(10) {
							$border.width = 5;
							$border.color = Blue;
							$color = Yellow;
							$anchors.fill($parent);
						}

						@box {
							$anchors.fill($parent);

							App.input.mouse.onScrolled(d -> $padding = $left.padding + d);

							@text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.") {
								$layout.fillWidth = true;
								$layout.fillWidthFactor = 0.5;
								$layout.fillHeight = true;
								$layout.fillHeightFactor = 0.5;
								$layout.alignment = AlignCenter;
								$color = Green;
								$fontSize = 32;
								$elideMode = ElideLeft;
								$wrapMode = WrapAnywhere;
								$alignment = AlignBottom;

								App.input.mouse.onButtonPressed(Left, (x, y) -> {
									trace($displayText);
									
									if ($alignment & AlignLeft != 0)
										$alignment = AlignHCenter;
									else if ($alignment & AlignHCenter != 0)
										$alignment = AlignRight;
									else
										$alignment = AlignLeft;
									$alignment = $alignment | AlignBottom;
								});
							}
						}
					}
				}
			}
		}
	}
}
