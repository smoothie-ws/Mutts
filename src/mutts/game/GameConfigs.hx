package mutts.game;

import mutts.net.Types.BackendGameConfig;
import mutts.net.Types.UnitConfig;

class GameConfigs {
	static var unitConfigs:Map<String, UnitConfig> = [];

	public static var game(default, null):BackendGameConfig = defaultGameConfig();

	public static function setGameConfig(config:BackendGameConfig):Void {
		if (config != null)
			game = config;
	}

	public static function setUnitConfigs(configs:Array<UnitConfig>):Void {
		if (configs == null || configs.length == 0)
			return;

		unitConfigs = [];

		final types:Array<UnitType> = [];
		for (config in configs) {
			if (config == null || config.name == null || config.name == "")
				continue;

			unitConfigs.set(config.name, config);
			types.push(cast config.name);
		}

		UnitType.setShopPool(types);
	}

	public static function unit(type:UnitType):UnitConfig {
		final config = unitConfigs.get((type : String));
		return config != null ? config : defaultUnitConfig(type);
	}

	public static function unitHealth(type:UnitType, level:Int):Int
		return scale(unit(type).hp, level);

	public static function unitCost(type:UnitType):Int
		return unit(type).cost;

	public static function sellPrice(type:UnitType, level:Int):Int
		return Std.int(scale(unitCost(type), level) * game.sell_refund_percent);

	static function scale(value:Int, level:Int):Int
		return Std.int(value * Math.pow(2, Math.max(0, level - 1)));

	static function defaultGameConfig():BackendGameConfig
		return {
			initial_hp: 10,
			initial_coins: 10,
			new_round_coins: 5,
			max_units_on_board: 6,
			max_units_on_bench: 4,
			sell_refund_percent: 0.5,
			planning_time: 20,
			board_size_x: 7,
			board_size_y: 8
		}

	static function defaultUnitConfig(type:UnitType):UnitConfig {
		final cost = switch type {
			case ARCHITECT: 3;
			case BARRICADE: 2;
			case BERSERKER: 3;
			case BULLDOZER: 4;
			case CATAPULT: 4;
			case DRONE: 2;
			case GUNNER: 3;
			case MEDIC: 3;
			case PHANTOM: 5;
			case SCRAMBLER: 5;
			case SNIPER: 4;
			case TECHNICIAN: 3;
			case TURRET: 4;
			default: 3;
		}
		final name:String = type;
		return {
			name: name,
			hp: 100,
			attack: 0,
			attack_speed: 0.0,
			attack_range: 0,
			attack_type: "melee",
			crit_chance: 0.0,
			crit_damage: 2.0,
			move_speed: 0.0,
			cost: cost
		}
	}
}
