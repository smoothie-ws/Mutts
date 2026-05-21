package mutts.ui.menus;

import mutts.GameState;

class MainContent extends MenuContent {
	public function new()
		super("MAIN");

	@:ui.markup
	override function markup() {
		@column {
			$spacing = 25;
			$alignment = AlignCenter;
			$layout.fillWidth = true;
			$layout.fillHeight = true;

			for (t in [
				{
					title: "PLAY",
					width: 400,
					height: 100,
					color: GameUI.colors.green,
					state: GameState.searching
				},
				{
					title: "LEAGUE",
					width: 350,
					height: 75,
					color: GameUI.colors.cyan,
					state: GameState.league
				},
				{
					title: "SETTINGS",
					width: 350,
					height: 75,
					color: GameUI.colors.cyan,
					state: GameState.settings
				},
				{
					title: "EXIT",
					width: 350,
					height: 75,
					color: GameUI.colors.red,
					state: GameState.exit
				}
			]) {
				@markup(GameWidgets.button(t.color, t.title)) {
					$width = t.width;
					$height = t.height;
					$layout.alignment = AlignCenter;
					$onMouseClicked(_->Game.state.goto(t.state));
				}
			}
		}
	}
}
