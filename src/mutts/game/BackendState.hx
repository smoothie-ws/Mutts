package mutts.game;

import mutts.net.Types;
import mutts.net.Value;

class BackendState {
	public static function apply(state:Null<BackendGameState>, msg:Dynamic):Void {
		if (state == null)
			return;

		switch msg.type {
			case "countdown":
				final seconds = Value.int(msg, ["seconds", "time_left"]);
				if (seconds != null)
					state.timer = seconds;
			case "timer_update":
				final timer = Value.int(msg, ["time_left", "timer", "seconds"]);
				if (timer != null)
					state.timer = timer;
			case "planning_phase_start":
				state.phase = "planning";
				Value.setInt(state, "round", Value.int(msg, ["round"]));
				Value.setInt(state, "timer", Value.int(msg, ["time_left", "timer"]));
				updatePlayerCoins(state.player1, Value.int(msg, ["player1_coins", "player1_balance", "coins_player1", "player1.coins", "state.player1.coins"]));
				updatePlayerCoins(state.player2, Value.int(msg, ["player2_coins", "player2_balance", "coins_player2", "player2.coins", "state.player2.coins"]));
				updateHp(state.player1, Value.int(msg, ["player1_hp", "player1.hp", "state.player1.hp"]), Value.int(msg, ["damage_to_player1"]));
				updateHp(state.player2, Value.int(msg, ["player2_hp", "player2.hp", "state.player2.hp"]), Value.int(msg, ["damage_to_player2"]));
			case "unit_placed":
				final unit:BackendUnit = msg.unit;
				if (unit != null) {
					upsert(state, unit);
					updateCoins(state, playerName(msg, unit), Value.int(msg, ["coins_left", "coins"]));
				}
			case "auto_merge":
				final unit:BackendUnit = msg.merged_unit ?? msg.unit;
				if (unit != null) {
					merge(state, unit, Value.strings(msg, ["source_unit_ids", "source_ids"]));
					updateCoins(state, playerName(msg, unit), Value.int(msg, ["coins_left", "coins"]));
				}
			case "unit_moved":
				move(state, Value.str(msg, ["unit_id", "id"]), Value.float(msg, ["x", "position_x"]), Value.float(msg, ["y", "position_y"]),
					Value.str(msg, ["location"]));
			case "unit_sold":
				remove(state, Value.str(msg, ["unit_id", "id"]));
				updateCoins(state, Value.str(msg, ["player", "owner", "username"]), Value.int(msg, ["coins_left", "coins"]));
			case "battle_phase_start":
				state.phase = "battle";
				state.timer = 0;
				Value.setInt(state, "round", Value.int(msg, ["round"]));
			case "battle_events":
				final units:Array<BackendUnit> = msg.units;
				if (units != null)
					state.units = units;
			case "battle_phase_end":
				state.phase = "battle_end";
				state.timer = 0;
				Value.setInt(state, "round", Value.int(msg, ["round"]));
				updateHp(state.player1, Value.int(msg, ["player1_hp"]), Value.int(msg, ["damage_to_player1"]));
				updateHp(state.player2, Value.int(msg, ["player2_hp"]), Value.int(msg, ["damage_to_player2"]));
			case "game_over":
				state.phase = "game_over";
				Value.setInt(state.player1, "hp", Value.int(msg, ["player1_hp"]));
				Value.setInt(state.player2, "hp", Value.int(msg, ["player2_hp"]));
				final winner = Value.str(msg, ["winner"]);
				if (winner != null)
					state.winner = winner;
			default:
		}
	}

	public static function upsert(state:Null<BackendGameState>, unit:BackendUnit):Void {
		if (state == null || unit == null)
			return;
		remove(state, unit.id);
		state.units.push(unit);
	}

	public static function merge(state:Null<BackendGameState>, unit:BackendUnit, ?sourceIds:Array<String>):Void {
		if (state == null || unit == null)
			return;
		removeMergeSources(state, unit, sourceIds);
		upsert(state, unit);
	}

	public static function move(state:Null<BackendGameState>, id:Dynamic, x:Null<Float>, y:Null<Float>, location:Null<String>):Void {
		final unit = find(state, id);
		if (unit == null)
			return;
		if (x != null)
			unit.position_x = x;
		if (y != null)
			unit.position_y = y;
		if (location != null)
			unit.location = location;
	}

	public static function remove(state:Null<BackendGameState>, id:Dynamic):Bool {
		if (state == null || id == null)
			return false;

		var removed = false;
		var i = state.units.length - 1;
		while (i >= 0) {
			if (Value.sameId(state.units[i].id, id)) {
				state.units.splice(i, 1);
				removed = true;
			}
			i--;
		}
		return removed;
	}

	public static function find(state:Null<BackendGameState>, id:Dynamic):Null<BackendUnit> {
		if (state == null || id == null)
			return null;
		for (unit in state.units)
			if (Value.sameId(unit.id, id))
				return unit;
		return null;
	}

	public static function battleUnit(state:Null<BackendGameState>, id:String, location:Int, ownUsername:String):Null<Unit> {
		final data = find(state, id);
		return data == null ? null : toDisplayUnit(data, location, ownUsername);
	}

	public static function battleUnits(state:Null<BackendGameState>, location:Int, ownUsername:String):Array<Unit>
		return state == null ? [] : [
			for (data in state.units)
				if (data.location != "bench") toDisplayUnit(data, location, ownUsername)
		];

	public static function battleColumn(state:Null<BackendGameState>, id:String, column:Int, location:Int, ownUsername:String):Int {
		final data = find(state, id);
		return data == null ? column : displayColumn(data.owner, column, location, ownUsername);
	}

	public static function battleY(state:Null<BackendGameState>, id:String, y:Float, location:Int, ownUsername:String):Float {
		final data = find(state, id);
		return data == null ? y : displayPositionY(data.owner, y, location, ownUsername);
	}

	public static function displayColumn(owner:String, column:Int, location:Int, ownUsername:String):Int {
		return location == 0 ? column : mutts.game.Match.columns - 1 - column;
	}

	public static function displayPositionY(owner:String, y:Float, location:Int, ownUsername:String):Float {
		return location == 0 ? y : mutts.game.Match.columns - y;
	}

	static function toDisplayUnit(data:BackendUnit, location:Int, ownUsername:String):Unit {
		final unit = Unit.fromBackend(data);
		unit.row = Std.int(Math.floor(data.position_x));
		unit.column = displayColumn(data.owner, Std.int(Math.floor(data.position_y)), location, ownUsername);
		return unit;
	}

	static function removeMergeSources(state:BackendGameState, merged:BackendUnit, ?sourceIds:Array<String>):Void {
		if (sourceIds != null && sourceIds.length > 0) {
			for (id in sourceIds)
				remove(state, id);
			return;
		}

		final sourceLevel = merged.level - 1;
		if (sourceLevel <= 0)
			return;

		var remaining = 3;
		var i = state.units.length - 1;
		while (i >= 0 && remaining > 0) {
			final unit = state.units[i];
			if (!Value.sameId(unit.id, merged.id) && unit.owner == merged.owner && unit.type == merged.type && unit.level == sourceLevel) {
				state.units.splice(i, 1);
				remaining--;
			}
			i--;
		}
	}

	static function updateCoins(state:BackendGameState, username:Null<String>, coins:Null<Int>):Void {
		if (username == null || coins == null)
			return;
		if (state.player1.username == username)
			state.player1.coins = coins;
		else if (state.player2.username == username)
			state.player2.coins = coins;
	}

	static function updatePlayerCoins(player:BackendPlayerState, coins:Null<Int>):Void {
		if (coins != null)
			player.coins = coins;
	}

	static function updateHp(player:BackendPlayerState, hp:Null<Int>, damage:Null<Int>):Void {
		if (hp != null)
			player.hp = hp;
		else if (damage != null)
			player.hp = Std.int(Math.max(0, player.hp - damage));
	}

	static function playerName(msg:Dynamic, ?unit:BackendUnit):Null<String>
		return Value.str(msg, ["player", "owner", "username"]) ?? unit?.owner;
}
