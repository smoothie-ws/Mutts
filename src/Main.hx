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
			$color = Black;
			// $padding = 50;
			// $stops = [
			// 	{color: White, position: 0.0},
			// 	{color: Red, position: 0.5},
			// 	{color: Black, position: 1.0}
			// ];
		}

		// new Timer(() -> $transform.rotation += 0.01, 0.01).loop();

		// @rectangle {
		// 	$anchors.fill($parent);
		// 	$color = Red;

		// 	var r = @rectangle {
		// 		$margins = 50;
		// 		$width = 100;
		// 		$anchors.top = $parent.top;
		// 		$anchors.left = $parent.left;
		// 		$anchors.bottom = $parent.bottom;
		// 		$color = Green;

		// 		@ellipse(30) {
		// 			$anchors.fill($parent);
		// 			$color = Black;
		// 		}
		// 	}

		var img = @image("teoria_veroyatnostei2") {
			$fillMode = Contain;
			$x = 100;
			$y = 200;
			$width = 500;
			$height = 350;
			// $layout.fillWidth = true;
			// $layout.fillWidthFactor = 0.5;
			// $layout.fillHeight = true;
			// $layout.fillHeightFactor = 0.5;
			// $layout.alignment = AlignVCenter | AlignLeft;

			App.input.mouse.onButtonPressed(Left, (x, y) -> {
				img.sampling = switch img.sampling {
					case Nearest: Bilinear;
					case Bilinear: Prefiltered;
					case Prefiltered: Trilinear;
					case Trilinear: Nearest;
				}
			});
		}

		// @rectangle {
		// 	$margins = 50;
		// 	$padding = 50;
		// 	$anchors.top = $parent.top;
		// 	$anchors.bottom = $parent.bottom;
		// 	$anchors.left = r.right;
		// 	$anchors.right = $parent.right;
		// 	$color = Black;

		// 	var grad = @gradient.linear {
		// 		$stops = [
		// 			{color: White, position: 0.0},
		// 			{color: Red, position: 0.5},
		// 			{color: Black, position: 1.0}
		// 		];
		// 		$interpolation = Interpolation.InQuart;
		// 		$anchors.fill($parent);
		// 		$padding = 50;
		// 		$width = 100;

		// 		App.input.mouse.onMoved((x, y, dx, dy) -> $start = grad.mapFromGlobalNormalized(x, y));

		// 		@triangle(10) {
		// 			$border.width = 5;
		// 			$border.color = Blue;
		// 			$color = Yellow;
		// 			$anchors.fill($parent);
		// 		}

		// 		@box {
		// 			$anchors.fill($parent);

		// 			App.input.mouse.onScrolled(d -> $padding = $left.padding + d * 10);

		// @label("ASDASDASDSAadsda afaf mw19j311mrASDASDASDSAadsda afaf mw19j311mr") {
		// 	$anchors.fill($parent);
		// 	$color = Red;
		// 	$fontSize = 32;
		// 	// $elideMode = ElideLeft;
		// 	// $wrapMode = WrapAnywhere;

		// 	// $transform.rotation = radians(45);

		// 	App.input.mouse.onButtonPressed(Left, (x, y) -> {
		// 		if ($alignment & AlignTop != 0)
		// 			$alignment = AlignVCenter;
		// 		else if ($alignment & AlignVCenter != 0)
		// 			$alignment = AlignBottom;
		// 		else
		// 			$alignment = AlignTop;
		// 		$alignment = $alignment | AlignHCenter;
		// 		trace($alignment);
		// 	});
		// }

		// 		}
		// 	}
		// }
		// }
		// }
	}
}
