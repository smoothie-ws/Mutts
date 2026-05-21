package mutts.ui.menus;

import s.ui.Element;
import mutts.GameState;
import mutts.game.Match;

class SearchingContent extends MenuContent {
	public function new() {
		super("SEARCHING...");
		Game.client.onGameReady(match -> {
			Game.match = new Match(match.opponent, match.location);
			Game.state.goto(GameState.play);
		});
		Game.client.requestGame();
	}

	@:ui.markup
	override function markup() {
		@layout.column {
			$anchors.fill(this);

			@element {}
			@markup(GameWidgets.loading(GameUI.colors.cyan)) {}
			@markup(GameWidgets.button(GameUI.colors.red, "CANCEL")) $layout.alignment = AlignCenter;
		}
	}
}
