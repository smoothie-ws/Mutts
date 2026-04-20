package mutts.ui;

import s.app.Window;
import s.ui.Scene;
import mutts.ui.screens.Screen;
import mutts.ui.screens.MainScreen;
import mutts.ui.screens.PlayScreen;
import mutts.ui.screens.LeagueScreen;
import mutts.ui.screens.SettingsScreen;

class GameUI {
	static var scene:Scene;
	static var screen:Screen;
    
	public static var screens:{main:MainScreen, play:PlayScreen, league:LeagueScreen, settings:SettingsScreen}

	public static function init(window:Window) {
		scene = new Scene(window);
		screens = {
			main: new MainScreen(),
			play: new PlayScreen(),
			league: new LeagueScreen(),
			settings: new SettingsScreen()
		};
		setScreen(screens.main);
	}

	public static function setScreen(screen:Screen) {
		if (GameUI.screen != null)
			GameUI.screen.parent = null;
		GameUI.screen = screen;
		GameUI.screen.parent = scene;
		GameUI.screen.anchors.fill(scene);
	}
}
