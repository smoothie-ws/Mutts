package mutts.game;

import s.FSM;

class GameState extends FSM {
	public static final load:State = [];
	public static final login:State = [];
	public static final main:State = [];

	public function new() {
		super([load => () -> {}]);
	}
}
