package mutts.net;

// common
typedef Error = {message:String};
typedef AuthTokens = {access_token:String, refresh_token:String, ?token_type:String};
typedef BackendUser = {id:Int, username:String, rating:Int};
typedef LeaderboardResponse = {players:Array<BackendUser>};
typedef QueueStatus = {status:String, ?queue_size:Int, ?game_id:String};
typedef BackendPlayerState = {username:String, hp:Int, coins:Int, max_units:Int};
typedef BackendGameState = {
	game_id:String,
	player1:BackendPlayerState,
	player2:BackendPlayerState,
	round:Int
};
// player
typedef PlayerProfile = {id:Int, nickname:String};
// stats
typedef PlayerStats = {id:Int, mmr:Int, win_count:Int, lose_count:Int};
typedef GlobalStats = Array<{id:Int, nickname:String, mmr:Int}>;

// gameplay
extern enum abstract ActionType(Int) from Int to Int {
	var Spawn = 0;
	var Idle = 1;
	var Walk = 2;
	var Attack = 3;
	var Damage = 4;
	var Death = 5;
}

typedef Action = {
	id:ActionType,
	duration:Float,
	?row:Int,
	?column:Int
}
typedef Match = {opponent:PlayerProfile, location:Int};
typedef UnitTimeline = {
	id:Int,
	?type:Int,
	?level:Int,
	?side:Int,
	actions:Array<Action>
}
typedef MatchBattle = Array<UnitTimeline>;
typedef UnitPlacement = {id:Int, level:Int, row:Int, column:Int}
typedef MatchRoundResult = {playerHealth:Int, opponentHealth:Int, winner:Null<Int>}
typedef MatchRoundResponse = {battle:MatchBattle, result:MatchRoundResult}
