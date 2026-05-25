package mutts.game;

@:forward
enum abstract Unit(UnitData) from UnitData {
	@:from
	public static function get(type:UnitType):Unit
		return create(type);

	public static function create(type:UnitType, level:Int = 1):Unit {
		final id:String = type;
		final config = GameConfigs.unit(type);
		final maxHealth = GameConfigs.unitHealth(type, level);
		return {
			type: type,
			id: id,
			name: id.charAt(0).toUpperCase() + id.substr(1),
			price: config.cost,
			row: 0,
			column: 0,
			level: level,
			health: maxHealth,
			maxHealth: maxHealth,
			attack: config.attack,
			attackSpeed: config.attack_speed,
			range: config.attack_range,
			moveSpeed: config.move_speed,
			critChance: config.crit_chance,
			critDamage: config.crit_damage,
			lastAttackTime: 0.0,
			location: "board"
		};
	}

	public static function fromBackend(data:mutts.net.Types.BackendUnit):Unit {
		final unit = create(data.type, data.level);
		unit.serverId = data.id;
		unit.owner = data.owner;
		unit.location = data.location;
		unit.health = data.hp;
		unit.maxHealth = data.max_hp;
		unit.attack = data.attack;
		unit.attackSpeed = data.attack_speed;
		unit.range = data.range;
		unit.moveSpeed = data.move_speed;
		unit.targetId = data.target_id;
		unit.lastAttackTime = data.last_attack_time ?? 0.0;
		unit.critChance = data.crit_chance ?? 0.0;
		unit.critDamage = data.crit_damage ?? 1.5;
		return unit;
	}

	public function getSellPrice():Int {
		return GameConfigs.sellPrice(this.type, this.level);
	}
}

private typedef UnitData = {
	type:UnitType,
	id:String,
	name:String,
	price:Int,
	row:Int,
	column:Int,
	level:Int,
	health:Int,
	maxHealth:Int,
	attack:Int,
	attackSpeed:Float,
	range:Int,
	moveSpeed:Float,
	critChance:Float,
	critDamage:Float,
	lastAttackTime:Float,
	location:String,
	?serverId:String,
	?owner:String,
	?targetId:String
}
