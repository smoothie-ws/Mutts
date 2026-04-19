package mutts.net;

// common
typedef Error = {message:String};
// player
typedef PlayerProfile = {id:Int, nickname:String};
// stats
typedef PlayerStats = {id:Int, mmr:Int, win_count:Int, lose_count:Int};
typedef GlobalStats = Array<{id:Int, nickname:String, mmr:Int}>;

// gameplay
enum ActionType {
	Idle;
	Walk;
	Attack;
	Death;
}

typedef Action = {id:ActionType, duration:Float}
typedef Game = {opponent:PlayerProfile, location:Int};
typedef GameBattle = Array<{id:Int, actions:Array<Action>}>;
