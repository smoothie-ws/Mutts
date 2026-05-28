package mutts.ui.menus;

import mutts.GameState;

class PlaygroundContent extends MenuContent {
	public function new()
		super("MATCH");

	@:ui.markup
	override function markup() {
		@column {
			$spacing = 25;
			$alignment = AlignCenter;
			$layout.fillWidth = true;
			$layout.fillHeight = true;

			for (t in [
				{
					title: "RETURN",
					width: 400,
					height: 100,
					color: GameUI.colors.green,
					state: GameState.play
				},
				{
					title: "SETTINGS",
					width: 350,
					height: 75,
					color: GameUI.colors.cyan,
					state: GameState.settings
				},
				{
					title: "LEAVE",
					width: 350,
					height: 75,
					color: GameUI.colors.red,
					state: GameState.main
				}
			]) {
				@markup(GameUI.button(t.color, t.title)) {
					$width = t.width;
					$height = t.height;
					$layout.alignment = AlignCenter;
					$onMouseClicked(_ -> if (t.state == GameState.main) Game.state.confirmLeaveMatch() else Game.state.goto(t.state));
				}
			}
		}
	}
}
