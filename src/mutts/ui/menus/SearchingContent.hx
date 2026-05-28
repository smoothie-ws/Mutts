package mutts.ui.menus;

import s.ui.Element;
import mutts.GameState;
import mutts.game.Match;

class SearchingContent extends MenuContent {
	public function new() {
		super("SEARCHING...");
		Game.client.onGameReady(onGameReady);
		Game.client.onFailed(showError);
		Game.client.requestGame();
	}

	@:ui.markup
	override function markup() {
		@layout.column {
			$anchors.fill(this);

			@element {}
			@markup(GameUI.loading(GameUI.colors.cyan)) {}
			@markup(GameUI.button(GameUI.colors.red, "CANCEL")) {
				$layout.alignment = AlignCenter;
				$onMouseClicked(_->Game.state.goto(GameState.main));
			}
		}
	}

	function onGameReady(match:mutts.net.Types.Match) {
		Game.match = new Match(match.opponent, match.location, match.state);
		Game.state.goto(GameState.play);
	}

	function showError(message:String)
		GameUI.showPopup(GameUI.colors.red, message, false, () -> Game.state.goto(GameState.main));

	override function destroy() {
		Game.client.offGameReady(onGameReady);
		Game.client.offFailed(showError);
		super.destroy();
	}
}
