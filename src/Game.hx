package;

import s.ui.Scene;
import s.app.Window;
import mutts.net.GameClient;
import mutts.game.GameState;
import mutts.ui.screens.MainScreen;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
@:app.framebuffer(verticalSync = false)
class Game extends s.App {
	public static final state = new GameState();
	public static final client = new GameClient();

	public static function main() {
		var scene = new Scene(window);
		var mainScreen = new MainScreen();
		mainScreen.parent = scene;
		mainScreen.anchors.fill(scene);
	}
}
