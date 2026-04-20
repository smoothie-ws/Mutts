package;

import s.ui.Scene;
import s.app.Window;
import mutts.net.GameClient;
import mutts.game.GameState;
import mutts.ui.screens.Screen;
import mutts.ui.screens.MainScreen;
import mutts.ui.screens.PlayScreen;
import mutts.ui.screens.SettingsScreen;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
@:app.framebuffer(verticalSync = false)
class Game extends s.App {
	static var scene:Scene;
	static var screen:Screen;

	public static var screens:{main:MainScreen, play:PlayScreen, settings:SettingsScreen}

	public static final state = new GameState();
	public static final client = new GameClient();

	public static function main() {
		scene = new Scene(window);
		screens = {
			main: new MainScreen(),
			play: new PlayScreen(),
			settings: new SettingsScreen()
		};
		setScreen(Game.screens.main);
	}

	public static function setScreen(screen:Screen) {
		if (Game.screen != null)
			Game.screen.parent = null;
		Game.screen = screen;
		Game.screen.parent = scene;
		Game.screen.anchors.fill(scene);
	}
}
