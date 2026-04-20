package mutts.game;

import s.FSM;
import mutts.ui.GameUI;

class GameState extends FSM {
	public static final main:State = [];
	public static final play:State = [];
	public static final league:State = [];
	public static final settings:State = [];
	public static final exit:State = [];

	public function new() {
		super(main);

		// main states
		main[play] = () -> GameUI.setScreen(GameUI.screens.play);
		main[league] = () -> GameUI.setScreen(GameUI.screens.league);
		main[settings] = () -> GameUI.setScreen(GameUI.screens.settings);
		main[exit] = () -> s.App.exit();

		// play states
		play[main] = () -> GameUI.setScreen(GameUI.screens.main);

		// settins states
		settings[main] = () -> GameUI.setScreen(GameUI.screens.main);

		// league states
		league[main] = () -> GameUI.setScreen(GameUI.screens.main);
	}

	public function back()
		goto([play => main, league => main, settings => main, main => exit].get(current));
}
