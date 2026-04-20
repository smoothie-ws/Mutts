package mutts.ui.screens;

import mutts.game.GameState;

class SettingsScreen extends Screen {
	public function new() {
		super("background");
		markup(this);
	}

	@:ui.markup
	function markup() {
		@layout.row {
			$anchors.fill($parent);

			@layout.column {
				$layout.alignment = AlignBottom;
				$layout.fillWidth = true;
				$layout.fillHeight = true;
				$layout.fillHeightFactor = 0.5;

				@label("SETTINGS") {}
				@button("BACK") {
					$onMouseButtonClicked(Left, () -> Game.state.goto(GameState.main));
				}
			}

			@layout.column {
				$layout.fillWidth = true;
				$layout.fillHeight = true;

				@label("AUDIO") {}
				@row {
					@label("MUSIC") {}
				}
				@row {
					@label("SOUNDS") {}
				}
				@label("DISPLAY") {}
				@row {
					@label("OPACITY") {}
				}
			}
		}
	}
}
