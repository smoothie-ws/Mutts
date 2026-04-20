package mutts.game;

import s.FSM;

class GameState extends FSM {
	public static final play:State = [];
	public static final league:State = [];
	public static final settings:State = [];
	public static final exit:State = [];
	public static final main:State = [];

	public function new() {
		super(main);

		main[play] = () -> Game.setScreen(Game.screens.play);
		main[league] = () -> Log.info("League");
		main[settings] = () -> Game.setScreen(Game.screens.settings);
		main[exit] = () -> Log.info("Exit");

		settings[main] = () -> Game.setScreen(Game.screens.main);
	}
}
