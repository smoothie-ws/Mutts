package mutts.ui.screens;

import s.assets.Image;
import s.math.Interpolation;

class MainScreen extends Screen {
	@:ui.markup
	override function markup() {
		@image(Image.load("background")) {
			$fillMode = Cover;
			$anchors.fill($parent);

			@gradient.linear([0xC9000000, 0xB4925714]) {
				$interpolation = Interpolation.Smoothstep;
				$anchors.fill($parent);
			}
		}
	}
}
