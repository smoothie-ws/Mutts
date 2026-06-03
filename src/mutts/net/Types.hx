package mutts.net;

import mutts.game.UnitType;

// common
typedef AuthTokens = {access_token:String, refresh_token:String, ?token_type:String};
typedef BackendUser = {
	id:Int,
	username:String,
	rating:Int,
	win_count:Int,
	lose_count:Int,
	draw_count:Int
};
typedef LeaderboardResponse = {players:Array<BackendUser>};
typedef QueueStatus = {?status:String, ?queue_size:Int, ?game_id:String, ?message:String};
typedef UnitConfig = {
	name:String,
	hp:Int,
	attack:Int,
	attack_speed:Float,
	attack_range:Int,
	attack_type:String,
	crit_chance:Float,
	crit_damage:Float,
	move_speed:Float,
	cost:Int
};
typedef BackendGameConfig = {
	initial_hp:Int,
	initial_coins:Int,
	new_round_coins:Int,
	max_units_on_board:Int,
	max_units_on_bench:Int,
	sell_refund_percent:Float,
	planning_time:Int,
	board_size_x:Int,
	board_size_y:Int
};
typedef BackendPlayerState = {username:String, hp:Int, coins:Int, max_units:Int};

typedef BackendUnit = {
	id:String,
	type:UnitType,
	level:Int,
	hp:Int,
	max_hp:Int,
	attack:Int,
	attack_speed:Float,
	range:Int,
	move_speed:Float,
	position_x:Float,
	position_y:Float,
	owner:String,
	location:String,
	?target_id:String,
	?last_attack_time:Float,
	?crit_chance:Float,
	?crit_damage:Float
};
typedef BackendGameState = {
	game_id:String,
	player1:BackendPlayerState,
	player2:BackendPlayerState,
	units:Array<BackendUnit>,
	phase:String,
	round:Int,
	timer:Int,
	?winner:String
};
// player
typedef PlayerProfile = {id:Int, nickname:String};
typedef GlobalStat = {id:Int, nickname:String, mmr:Int, win_count:Int, lose_count:Int, draw_count:Int};
typedef GlobalStats = Array<GlobalStat>;
typedef Match = {opponent:PlayerProfile, location:Int, ?state:BackendGameState};

// battle animation
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
	?x:Float,
	?y:Float,
	?row:Int,
	?column:Int,
	?health:Int,
	?maxHealth:Int,
	?damage:Int
};

typedef UnitTimeline = {
	id:String,
	?type:UnitType,
	?level:Int,
	?side:Int,
	actions:Array<Action>
};

typedef MatchBattle = Array<UnitTimeline>;
