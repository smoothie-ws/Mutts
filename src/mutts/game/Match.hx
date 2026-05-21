package mutts.game;

import haxe.ds.Vector;
import s.math.Vec2;
import s.math.SMath;
import mutts.game.Unit;
import mutts.net.Types;

@:allow(mutts.ui.screens.MatchScreen)
@:allow(mutts.ui.playground.PlaygroundUnit)
class Match {
	static inline final shopCount:Int = 5;
	static inline final benchCount:Int = 4;
	public static inline final maxHealth:Int = 10;
	public static inline final rows:Int = 8;
	public static inline final columns:Int = 8;

	static final points = [
		for (row in 0...rows) [
			for (column in 0...columns)
				vec2((row - column) * 1.55 / 2 - 0.02, (row + column) * 1.15 / 2 - 3.61)
		]
	];

	static function pick(pos:Vec2, col:Int = columns) {
		inline function dist(p)
			return distance(pos, p);

		final maxColumn = Std.int(Math.min(col, columns));
		var p = null;
		var min = Math.POSITIVE_INFINITY;

		for (row in 0...rows)
			for (column in 0...maxColumn) {
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
	final available:Array<UnitType> = [];

	public final shop:Vector<UnitType> = new Vector(shopCount);
	public var bench(get, never):Array<Unit>;
	public var ground(get, never):Array<Unit>;

	public final opponent:PlayerProfile;
	public final location:Int;

	public var round:Int = 1;
	public var phase:MatchPhase = Preparation;
	public var balance:Int = 10000;
	public var playerHealth:Int = maxHealth;
	public var opponentHealth:Int = maxHealth;
	public var winner:Null<Int> = null;

	var nextUnitId:Int = 1;

	public function new(opponent:PlayerProfile, location:Int) {
		this.opponent = opponent;
		this.location = location;

		groundArea = new MatchPlayground();
		benchArea = new UnitCollection(benchCount);

		for (i in 0...shopCount)
			shop[i] = i;
		for (i in shopCount...UnitType.count)
			available.push(i);
	}

	public function canBuy(i:Int):Bool {
		final unit = shopUnit(i);
		return phase == Preparation && unit != null && balance >= unit.price && canPlace(unit);
	}

	public function willBuyMerge(i:Int):Bool {
		final unit = shopUnit(i);
		return unit != null && willAddPurchasedUnitMerge(unit);
	}

	public function canTake(i:Int):Bool
		return phase == Preparation && i >= 0 && i < bench.length && groundArea.canAccept(bench[i]);

	public function buy(i:Int):Null<Unit> {
		final unit = shopUnit(i);
		if (phase != Preparation || unit == null || balance < unit.price || !addPurchasedUnit(unit))
			return null;

		unit.matchId = nextUnitId++;
		balance -= unit.price;
		rollShop(i);
		return unit;
	}

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

	public function sell(i:Int):Null<Unit> {
		if (phase != Preparation)
			return null;

		var unit = benchArea.removeAt(i);
		if (unit == null)
			return null;

		balance += unit.getSellPrice();
		return unit;
	}

	public function moveGroundUnit(unit:Unit, row:Int, column:Int):Bool
		return phase == Preparation && groundArea.move(unit, row, column);

	public function moveToBench(unit:Unit):Bool {
		if (phase != Preparation || !groundArea.contains(unit) || !benchArea.canAccept(unit))
			return false;

		groundArea.remove(unit);
		if (benchArea.add(unit))
			return true;

		groundArea.add(unit);
		return false;
	}

	public function startRound():Bool
		return phase == Preparation || transition(Preparation, Results);

	public function submitPlacement():Null<Array<UnitPlacement>>
		return transition(Waiting, Preparation) ? [for (unit in ground) {id: unit.matchId, level: unit.level, row: unit.row, column: unit.column}] : null;

	public function beginBattle():Bool
		return transition(Battle, Waiting);

	public function finishRound(result:MatchRoundResult):Bool {
		if (!transition(Results, Battle))
			return false;
		playerHealth = result.playerHealth;
		opponentHealth = result.opponentHealth;
		winner = result.winner;
		return true;
	}

	public function nextRound():Bool {
		if (phase != Results || winner != null)
			return false;
		round++;
		return startRound();
	}

	function transition(to:MatchPhase, from:MatchPhase):Bool {
		if (phase != from)
			return false;
		phase = to;
		return true;
	}

	function canPlace(unit:Unit):Bool
		return groundArea.canAccept(unit) || benchArea.canAccept(unit);

	function get_bench():Array<Unit>
		return benchArea.units;

	function get_ground():Array<Unit>
		return groundArea.units;

	function shopUnit(i:Int):Null<Unit>
		return i < 0 || i >= shop.length ? null : (shop[i] : Unit);

	function rollShop(i:Int):Void {
		if (available.length == 0)
			return;
		final old = shop[i], next = available[Std.random(available.length)];
		available.remove(next);
		available.push(old);
		shop[i] = next;
	}

	function addPurchasedUnit(unit:Unit):Bool
		return groundArea.canAccept(unit) && groundArea.add(unit) || benchArea.canAccept(unit) && benchArea.add(unit);

	function willAddPurchasedUnitMerge(unit:Unit):Bool
		return groundArea.canMerge(unit) || !groundArea.canAccept(unit) && benchArea.canMerge(unit);
}
