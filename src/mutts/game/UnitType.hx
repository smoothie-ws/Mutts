package mutts.game;

enum abstract UnitType(String) from String to String {
	public static final shopPool:Array<UnitType> = defaultShopPool();

	public static function setShopPool(types:Array<UnitType>):Void {
		if (types == null || types.length == 0)
			return;

		shopPool.resize(0);
		for (type in types)
			shopPool.push(type);
	}

	static function defaultShopPool():Array<UnitType>
		return [
		ARCHITECT,
		BARRICADE,
		BERSERKER,
		BULLDOZER,
		CATAPULT,
		DRONE,
		GUNNER,
		MEDIC,
		PHANTOM,
		SCRAMBLER,
		SNIPER,
		TECHNICIAN,
		TURRET
	];

	var ARCHITECT = "ARCHITECT";
	var BARRICADE = "BARRICADE";
	var BERSERKER = "BERSERKER";
	var BULLDOZER = "BULLDOZER";
	var CATAPULT = "CATAPULT";
	var DRONE = "DRONE";
	var GUNNER = "GUNNER";
	var MEDIC = "MEDIC";
	var PHANTOM = "PHANTOM";
	var SCRAMBLER = "SCRAMBLER";
	var SNIPER = "SNIPER";
	var TECHNICIAN = "TECHNICIAN";
	var TURRET = "TURRET";
}
