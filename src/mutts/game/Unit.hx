package mutts.game;

enum abstract UnitType(Int) from Int to Int {
	public static inline final count:Int = 8;

	var ARCHITECT;
	var BERSERKER;
	var BULLDOZER;
	var DRONE;
	var MEDIC;
	var PHANTOM;
	var SNIPER;
	var TECHNICIAN;
}

@:forward
enum abstract Unit(UnitData) from UnitData {
	static final ids = ["architect", "berserker", "bulldozer", "drone", "medic", "phantom", "sniper", "technician"];
	static final names = ["Architect", "Berserker", "Bulldozer", "Drone", "Medic", "Phantom", "Sniper", "Technician"];

	@:from
	public static function get(type:UnitType):Unit
		return create(type);

	public static function create(type:UnitType, level:Int = 1):Unit {
		final i:Int = type;
		if (i < 0 || i >= UnitType.count) {
			Log.error("Unknown unit type: " + type);
			return null;
		}
		return {matchId: 0, type: type, id: ids[i], name: names[i], price: 100, row: 0, column: 0, level: level, health: 100};
	}

	public inline function canMergeWith(unit:Unit):Bool
		return this.type == unit.type && this.level == unit.level;

	public inline function levelUp():Void
		this.level++;

	public function getSellPrice():Int {
		var value = this.price;
		for (_ in 1...this.level)
			value *= 2;
		return Std.int(value / 2);
	}
}

private typedef UnitData = {
	matchId:Int,
	type:UnitType,
	id:String,
	name:String,
	price:Int,
	row:Int,
	column:Int,
	level:Int,
	health:Int
}
