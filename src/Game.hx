package;

import s.App;
import s.app.Window;
import s.app.input.Shortcut;
import mutts.ui.GameUI;
import mutts.net.GameClient;
import mutts.game.GameState;

@:app.title("Mutts")
@:app.window(width = 750, height = 650)
@:app.framebuffer(verticalSync = false)
class Game extends App {
	public static var state:GameState;
	public static var client:GameClient;

	public static function main() {
		state = new GameState();
		client = new GameClient();
		GameUI.init(window);

		App.input.keyboard.onShortcut(Cancel, () -> state.back());
	}
}
