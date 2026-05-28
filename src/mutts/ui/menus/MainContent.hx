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

			for (t in [
				{
					title: "PLAY",
					width: 400,
					height: 115,
					color: GameUI.colors.green,
					state: GameState.searching
				},
				{
					title: "LEAGUE",
					width: 350,
					height: 115,
					color: GameUI.colors.cyan,
					state: GameState.league
				},
				{
					title: "SETTINGS",
					width: 350,
					height: 115,
					color: GameUI.colors.cyan,
					state: GameState.settings
				},
				{
					title: "LOG OUT",
					width: 350,
					height: 115,
					color: GameUI.colors.yellow,
					state: GameState.auth
				},
				{
					title: "EXIT",
					width: 350,
					height: 115,
					color: GameUI.colors.red,
					state: GameState.exit
				}
			]) {
				@markup(GameUI.button(t.color, t.title)) {
					$width = t.width;
					$height = t.height;
					$layout.alignment = AlignCenter;
					$onMouseClicked(_ -> {
						if (t.state == GameState.auth)
							Game.logout();
						Game.state.goto(t.state);
					});
				}
			}
		}
	}
}
