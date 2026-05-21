package mutts.game;

extern enum abstract MatchPhase(String) to String {
	var Preparation = "PREPARATION";
	var Waiting = "WAITING";
	var Battle = "BATTLE";
	var Results = "RESULTS";
}
