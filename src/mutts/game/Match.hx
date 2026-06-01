package mutts.game;

import haxe.ds.Vector;
import s.math.Vec2;
import s.math.SMath;
import mutts.game.Unit;
import mutts.net.Types;
import mutts.net.Value;

@:allow(mutts.ui.playground.PlaygroundUnit)
class Match {
	static inline final shopCount:Int = 3;
	public static var maxHealth(get, never):Int;
	public static inline final rows:Int = 8;
	public static inline final columns:Int = 8;

	static final points = [
		for (row in 0...rows) [
			for (column in 0...columns)
				vec2((row - column) * 1.55 / 2 - 0.02, (row + column) * 1.15 / 2 - 3.61)
		]
	];

	public static inline function pointAt(row:Float, column:Float):Vec2
		return vec2((row - column) * 1.55 / 2 - 0.02, (row + column) * 1.15 / 2 - 3.61);

	static function pick(pos:Vec2, minColumn:Int = 0, maxColumn:Int = columns - 1) {
		inline function dist(p)
			return distance(pos, p);

		var p = null;
		var min = Math.POSITIVE_INFINITY;
		final fromColumn = Std.int(Math.max(0, minColumn));
		final toColumn = Std.int(Math.min(columns - 1, maxColumn));

		for (row in 0...rows)
			for (column in fromColumn...toColumn + 1) {
				var point = points[row][column];
				var d = dist(point);
				if (d < min) {
					min = d;
					p = {point: point, row: row, column: column};
				}
			}

		return p;
	}

	final groundArea:MatchPlayground;
	final benchArea:UnitCollection;
	final availableShop:Array<UnitType> = [];
	var latestState:BackendGameState;
	var ownUsername:String;

	public final shop:Vector<UnitType> = new Vector(shopCount);
	public var bench(get, never):Array<Unit>;
	public var ground(get, never):Array<Unit>;

	public final opponent:PlayerProfile;
	public final location:Int;

	public var round:Int = 1;
	public var timer:Int = 0;
	public var phase:MatchPhase = Preparation;
	public var balance:Int = GameConfigs.game.initial_coins;
	public var playerHealth:Int = GameConfigs.game.initial_hp;
	public var opponentHealth:Int = GameConfigs.game.initial_hp;
	public var winner:Null<Int> = null;

	public function new(opponent:PlayerProfile, location:Int, ?state:BackendGameState) {
		this.opponent = opponent;
		this.location = location;

		groundArea = new MatchPlayground(ownBoardMinColumn(), ownBoardMaxColumn());
		benchArea = new UnitCollection(GameConfigs.game.max_units_on_bench);

		for (unit in UnitType.shopPool)
			availableShop.push(unit);
		rerollShop();

		if (state != null)
			syncGameState(state);
	}

	public function canBuy(i:Int):Bool {
		final unit = shopUnit(i);
		return phase == Preparation && unit != null && balance >= unit.price && (groundArea.canAccept() || benchArea.canAccept());
	}

	public function canTake(i:Int):Bool
		return phase == Preparation && i >= 0 && i < bench.length && groundArea.canAccept();

	public function take(i:Int):Null<Unit> {
		if (!canTake(i))
			return null;

		var unit = benchArea.removeAt(i);
		if (unit == null)
			return null;

		if (!groundArea.add(unit)) {
			benchArea.add(unit);
			return null;
		}
		return unit;
	}

	public function moveGroundUnit(unit:Unit, row:Int, column:Int):Bool
		return phase == Preparation && groundArea.move(unit, row, column);

	public function moveToBench(unit:Unit):Bool {
		if (phase != Preparation || !groundArea.contains(unit) || !benchArea.canAccept())
			return false;

		groundArea.remove(unit);
		if (benchArea.add(unit))
			return true;

		groundArea.add(unit);
		return false;
	}

	public function beginServerBattle():Void {
		phase = Battle;
	}

	public function beginServerPlanning(round:Int):Void {
		this.round = round;
		phase = Preparation;
		winner = null;
	}

	public function finishServerBattle(playerHealth:Int, opponentHealth:Int):Void {
		phase = Results;
		this.playerHealth = playerHealth;
		this.opponentHealth = opponentHealth;
		winner = playerHealth <= 0 && opponentHealth <= 0 ? null : playerHealth <= 0 ? 1 : opponentHealth <= 0 ? 0 : null;
	}

	public function syncGameState(state:BackendGameState):Void {
		latestState = state;
		round = state.round;
		timer = state.timer;
		phase = state.phase == "battle" ? Battle : Preparation;

		final own = location == 0 ? state.player1 : state.player2;
		final enemy = location == 0 ? state.player2 : state.player1;
		ownUsername = own.username;
		balance = own.coins;
		playerHealth = own.hp;
		opponentHealth = enemy.hp;
		winner = state.winner == null || state.winner == "draw" ? null : state.winner == own.username ? 0 : 1;

		groundArea.units.resize(0);
		benchArea.units.resize(0);
		for (unit in state.units)
			if (unit.owner == own.username)
				placeBackendUnit(unit);
	}

	public function applyUnitPlaced(unit:BackendUnit, coins:Null<Int>, ?shopSlot:Int):Void {
		BackendState.upsert(latestState, unit);
		if (unit.owner != ownUsername)
			return;

		if (coins != null)
			balance = coins;
		placeBackendUnit(unit);
		if (shopSlot != null)
			rerollShopSlot(shopSlot);
	}

	public function applyAutoMerge(unit:BackendUnit, coins:Null<Int>, ?sourceIds:Array<String>, ?shopSlot:Int):Void {
		BackendState.merge(latestState, unit, sourceIds);
		if (unit.owner != ownUsername)
			return;

		if (coins != null)
			balance = coins;
		removeMergeSources(unit, sourceIds);
		placeBackendUnit(unit);
		if (shopSlot != null)
			rerollShopSlot(shopSlot);
	}

	public function applyUnitMoved(unitId:String, x:Int, y:Int, targetLocation:String):Bool {
		BackendState.move(latestState, unitId, x, y, targetLocation);

		final unit = findByServerId(unitId);
		if (unit == null)
			return false;

		if (targetLocation == "bench") {
			groundArea.remove(unit);
			if (!benchArea.contains(unit))
				benchArea.units.push(unit);
			return true;
		}

		if (targetLocation != "board")
			return false;

		benchArea.remove(unit);
		if (!groundArea.contains(unit))
			groundArea.units.push(unit);
		unit.row = x;
		unit.column = displayBoardColumn(y);
		return true;
	}

	public function applyUnitSold(unitId:String, coins:Int):Bool {
		BackendState.remove(latestState, unitId);
		balance = coins;
		final unit = findByServerId(unitId);
		if (unit == null)
			return false;

		return groundArea.remove(unit) || benchArea.remove(unit);
	}

	public function boardY(column:Int):Int
		return serverBoardColumn(column);

	public function ownBoardMinColumn():Int
		return 0;

	public function ownBoardMaxColumn():Int
		return columns - 1 - boardColumnOffset();

	public function benchSlot(unit:Unit):Int {
		final slot = bench.indexOf(unit);
		return slot < 0 ? 0 : slot;
	}

	public function battleUnit(id:String):Null<Unit>
		return BackendState.battleUnit(latestState, id, location, ownUsername);

	public function battleColumn(unitId:String, column:Int):Int
		return BackendState.battleColumn(latestState, unitId, column, location, ownUsername);

	public function battleY(unitId:String, y:Float):Float
		return BackendState.battleY(latestState, unitId, y, location, ownUsername);

	public function battleUnits():Array<Unit>
		return latestState == null ? ground.copy() : BackendState.battleUnits(latestState, location, ownUsername);

	function get_bench():Array<Unit>
		return benchArea.units;

	function get_ground():Array<Unit>
		return groundArea.units;

	function shopUnit(i:Int):Null<Unit>
		return i < 0 || i >= shop.length ? null : (shop[i] : Unit);

	function rerollShop():Void {
		for (i in 0...shop.length)
			rerollShopSlot(i);
	}

	function rerollShopSlot(i:Int):Void {
		if (i < 0 || i >= shop.length)
			return;

		final old = shop[i];
		if (old != null)
			availableShop.push(old);
		shop[i] = drawShopUnit();
	}

	function drawShopUnit():UnitType {
		if (availableShop.length == 0)
			for (unit in UnitType.shopPool)
				availableShop.push(unit);
		return availableShop.splice(Std.random(availableShop.length), 1)[0];
	}

	function placeBackendUnit(data:BackendUnit):Void {
		final old = findByServerId(data.id);
		if (old != null) {
			groundArea.remove(old);
			benchArea.remove(old);
		}

		final unit = Unit.fromBackend(data);
		if (data.location == "bench") {
			benchArea.units.push(unit);
			return;
		}

		unit.row = Std.int(Math.floor(data.position_x));
		unit.column = displayColumn(data);
		groundArea.units.push(unit);
	}

	function removeMergeSources(merged:BackendUnit, ?sourceIds:Array<String>):Void {
		if (sourceIds != null && sourceIds.length > 0) {
			for (id in sourceIds)
				removeByServerId(id);
			return;
		}

		final sourceLevel = merged.level - 1;
		if (sourceLevel <= 0)
			return;

		var remaining = 3;
		for (units in [groundArea.units, benchArea.units]) {
			var i = units.length - 1;
			while (i >= 0 && remaining > 0) {
				final unit = units[i];
				if (unit.type == merged.type && unit.level == sourceLevel) {
					units.splice(i, 1);
					remaining--;
				}
				i--;
			}
		}
	}

	function removeByServerId(id:String):Bool {
		final unit = findByServerId(id);
		return unit != null && (groundArea.remove(unit) || benchArea.remove(unit));
	}

	function findByServerId(id:String):Null<Unit> {
		for (unit in groundArea.units)
			if (Value.sameId(unit.serverId, id))
				return unit;
		for (unit in benchArea.units)
			if (Value.sameId(unit.serverId, id))
				return unit;
		return null;
	}

	function displayColumn(data:BackendUnit):Int {
		final column = Std.int(Math.floor(data.position_y));
		return BackendState.displayColumn(data.owner, column, location, ownUsername);
	}

	function displayBoardColumn(column:Int):Int
		return location == 0 ? column : columns - 1 - column;

	function serverBoardColumn(column:Int):Int
		return location == 0 ? column : columns - 1 - column;

	static function boardColumnOffset():Int
		return Std.int(Math.max(0, Match.columns - MatchPlayground.columns));

	static function get_maxHealth():Int
		return GameConfigs.game.initial_hp;
}
