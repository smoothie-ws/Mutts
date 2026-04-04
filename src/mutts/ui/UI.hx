package mutts.ui;

import s.ui.Direction;

class UI implements s.ui.Markup {
	@:ui.markup
	public static function markup() {
		@layout.row {
			$anchors.fill(parent);

			s.App.input.mouse.onClicked((b, x, y) -> $direction = !$direction);
			s.App.input.mouse.onScrolled(d -> $spacing += d);

			for (i in 0...5) {
				@rectangle() {
					// $layout.fillWidth = true;
					// $layout.minimumWidth = 50;
					// $layout.maximumWidth = 150;
					$margins = 10;
					$color = s.Color.rgb(i / 4, 0.0, 0.0);
					$width = 100;
					$height = 100;
				}
			}
		}
	}
}
