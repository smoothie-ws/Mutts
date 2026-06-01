package mutts.ui.menus;

import mutts.GameState;

class MainContent extends MenuContent {
	public function new()
		super(Game.player.nickname);

	@:ui.markup
	override function markup() {
		@column {
			$spacing = 0;
			$alignment = AlignCenter;
			$layout.fillWidth = true;
			$layout.fillHeight = true;

			@markup(GameUI.button(GameUI.colors.green, "PLAY")) {
				$width = 400;
				$height = 115;
				$layout.alignment = AlignCenter;
				$onMouseClicked(_->Game.state.goto(GameState.searching));
			}

			@markup(GameUI.button(GameUI.colors.cyan, "LEAGUE")) {
				$width = 350;
				$height = 115;
				$layout.alignment = AlignCenter;
				$onMouseClicked(_->Game.state.goto(GameState.league));
			}

			@markup(GameUI.button(GameUI.colors.cyan, "SETTINGS")) {
				$width = 350;
				$height = 115;
				$layout.alignment = AlignCenter;
				$onMouseClicked(_->Game.state.goto(GameState.settings));
			}
		}

		@layout.row {
			$anchors.fillWidth($parent);
			$height = 115;

			@markup(GameUI.iconButton(GameUI.colors.red, "logout")) {
				$width = 50;
				$height = 50;
				$layout.alignment = AlignCenter;
				$onMouseClicked(_ -> {
					Game.logout();
					Game.state.goto(GameState.auth);
				});
			}

			@markup(GameUI.iconButton(GameUI.colors.red, "exit")) {
				$width = 50;
				$height = 50;
				$layout.alignment = AlignCenter;
				$onMouseClicked(_->Game.state.goto(GameState.exit));
			}
		}
	}
}
