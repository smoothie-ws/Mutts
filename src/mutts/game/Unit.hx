package mutts.game;

enum abstract UnitType(Int) from Int to Int {
	public static inline final count:Int = 13;

	var ARCHITECT;
	var BARRICADE;
	var BERSERKER;
	var BULLDOZER;
	var CATAPULT;
	var DRONE;
	var GUNNER;
	var MEDIC;
	var PHANTOM;
	var SCRAMBLER;
	var SNIPER;
	var TECHNICIAN;
	var TURRET;
}

@:forward
enum abstract Unit(UnitData) from UnitData {
	@:from
	public static function get(type:UnitType):Unit
		return create(type);

	public static function create(type:UnitType, level:Int = 1):Unit {
		return switch type {
			case ARCHITECT: {
					matchId: 0,
					type: type,
					id: "architect",
					name: "Architect",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case BARRICADE: {
					matchId: 0,
					type: type,
					id: "barricade",
					name: "Barricade",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case BERSERKER: {
					matchId: 0,
					type: type,
					id: "berserker",
					name: "Berserker",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case BULLDOZER: {
					matchId: 0,
					type: type,
					id: "bulldozer",
					name: "Bulldozer",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case CATAPULT: {
					matchId: 0,
					type: type,
					id: "catapult",
					name: "Catapult",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case DRONE: {
					matchId: 0,
					type: type,
					id: "drone",
					name: "Drone",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case GUNNER: {
					matchId: 0,
					type: type,
					id: "gunner",
					name: "Gunner",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case MEDIC: {
					matchId: 0,
					type: type,
					id: "medic",
					name: "Medic",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case PHANTOM: {
					matchId: 0,
					type: type,
					id: "phantom",
					name: "Phantom",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case SCRAMBLER: {
					matchId: 0,
					type: type,
					id: "scrambler",
					name: "Scrambler",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case SNIPER: {
					matchId: 0,
					type: type,
					id: "sniper",
					name: "Sniper",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case TECHNICIAN: {
					matchId: 0,
					type: type,
					id: "technician",
					name: "Technician",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
			case TURRET: {
					matchId: 0,
					type: type,
					id: "turret",
					name: "Turret",
					price: 100,
					row: 0,
					column: 0,
					level: level,
					health: 100
				}
		}
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
