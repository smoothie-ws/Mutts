package mutts;

import s.FSM;
import s.Timer;
import s.app.input.Shortcut;
import mutts.ui.GameUI;
import mutts.ui.screens.MainScreen;
import mutts.ui.screens.MatchScreen;
import mutts.ui.menus.AuthContent;
import mutts.ui.menus.MainContent;
import mutts.ui.menus.SettingsContent;
import mutts.ui.menus.LeagueContent;
import mutts.ui.menus.SearchingContent;
import mutts.ui.menus.ConnectingContent;
import mutts.ui.menus.PlaygroundContent;

class GameState extends FSM {
	public static final start:State = [];
	public static final connecting:State = [];
	public static final auth:State = [];
	public static final main:State = [];
	public static final searching:State = [];
	public static final play:State = [];
	public static final playMenu:State = [];
	public static final league:State = [];
	public static final settings:State = [];
	public static final exit:State = [];

	var states:Array<State> = [];

	public function new() {
		super(start);

		Game.client.onAuth(profile -> {
			Game.player = profile;
			if (current != main)
				Game.state.goto(main);
		});

		// start states
		start[connecting] = () -> {
			GameUI.setScreenMenuContent(ConnectingContent);
			Timer.set(() -> if (!Game.tryAutoAuth()) Game.state.goto(auth), 0);
		}

		// connecting states
		connecting[auth] = () -> GameUI.setScreenMenuContent(AuthContent);
		connecting[main] = () -> GameUI.setScreenMenuContent(MainContent);

		// auth states
		auth[main] = () -> GameUI.setScreenMenuContent(MainContent);

		// main states
		main[searching] = () -> GameUI.setScreenMenuContent(SearchingContent);
		main[playMenu] = () -> {};
		main[auth] = () -> GameUI.setScreenMenuContent(AuthContent);

		main[league] = () -> GameUI.setScreenMenuContent(LeagueContent);

		main[settings] = () -> GameUI.setScreenMenuContent(SettingsContent);
		main[exit] = () -> GameUI.showPopup(GameUI.colors.red, "Are you sure?", true, () -> s.App.exit(), () -> goto(main));

		// league states
		league[main] = () -> GameUI.setScreenMenuContent(MainContent);

		// settins states
		settings[main] = () -> GameUI.setScreenMenuContent(MainContent);
		settings[playMenu] = () -> GameUI.setScreenMenuContent(PlaygroundContent);

		// searching states
		searching[play] = () -> GameUI.setScreen(MatchScreen, () -> GameUI.setScreenMenuContent(PlaygroundContent));
		searching[main] = () -> {
			Game.client.cancelSearch();
			GameUI.setScreenMenuContent(MainContent);
		}

		// play states
		play[playMenu] = () -> GameUI.screen.showMenu(true);
		play[main] = leaveMatch;

		// playMenu states
		playMenu[play] = () -> GameUI.screen.showMenu(false);
		playMenu[settings] = () -> GameUI.setScreenMenuContent(SettingsContent);
		playMenu[main] = leaveMatch;

		// exit states
		exit[main] = () -> {};

		s.App.input.keyboard.onShortcut(Cancel, () -> back());
	}

	override function goto(to:State) {
		if (to == null || to == current)
			return false;

		final from = current;
		if (!super.goto(to))
			return false;

		if (from != null && from != start) {
			var i = states.indexOf(from);
			if (i >= 0)
				states.splice(i, 1);
			states.push(from);
		}
		return true;
	}

	public function back()
		goto([
			play => playMenu,
			playMenu => play,
			searching => main,
			league => main,
			settings => states.pop() ?? main
		].get(current));

	public function confirmLeaveMatch():Void
		GameUI.showPopup(GameUI.colors.red, "Are you sure?", true, () -> goto(main), () -> goto(playMenu));

	function leaveMatch():Void {
		Game.client.closeGame();
		Game.match = null;
		GameUI.setScreen(MainScreen, () -> GameUI.setScreenMenuContent(MainContent));
	}
}
