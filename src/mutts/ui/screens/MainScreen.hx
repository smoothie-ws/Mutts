package mutts.ui.screens;

import mutts.game.GameState;

class MainScreen extends Screen {
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
			$padding = 50;
			$anchors.fill($parent.hCenter, $parent.right, $parent.vCenter, $parent.bottom);

			for (t in [
				{title: "PLAY", state: GameState.play},
				{title: "LEAGUE", state: GameState.league},
				{title: "SETTINGS", state: GameState.settings},
				{title: "EXIT", state: GameState.exit}
			]) {
				@button(t.title) {
					$margins = 10;
					$layout.fillWidth = true;
					$layout.fillHeight = true;
					$label.font.pixelSize = 32;

					$onMouseClicked(_ -> Game.state.goto(t.state));
				}
			}
		}
	}
}
