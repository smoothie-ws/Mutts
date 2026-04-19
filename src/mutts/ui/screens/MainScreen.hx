package mutts.ui.screens;

class MainScreen extends Screen {
	var mouseExitHooked = false;

	public function new() {
		super("background");
		markup(this);
	}

	@:ui.markup @hotload.reload
	function markup() {
		@gradient.linear([{position: -0.5, color: Blue}, {position: 0.75, color: Transparent}]) {
			$start = {x: 0.0, y: 0.0}
			$end = {x: 1.0, y: 1.0}
			$anchors.fill($parent);
		}

		@gradient.linear([{position: -0.5, color: Red}, {position: 0.75, color: Transparent}]) {
			$start = {x: 1.0, y: 1.0}
			$end = {x: 0.0, y: 0.0}
			$anchors.fill($parent);
		}

		@layout.column {
			$padding = 10;
			$anchors.fill($parent.hCenter, $parent.right, $parent.vCenter, $parent.bottom);

			for (t in ["PLAY", "LEAGUE", "SETTINGS", "EXIT"]) {
				@button(t) {
					@:bind($isFocused) $background.color = $isFocused ? Green : Red;

					$label.font.pixelSize = 32;

					$margins = 10;
					$layout.fillWidth = true;
					$layout.fillHeight = true;

					$onMouseEntered(() -> $label.font.weight = 1000);
					$onMouseExited(() -> $label.font.weight = 100);

					$onMousePressed((m) -> $setScale(1.1));
					$onMouseReleased((m) -> $setScale(1.0));
				}
			}
		}
	}
}
