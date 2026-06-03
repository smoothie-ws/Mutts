package mutts.game;

import mutts.net.Types.Action;
import mutts.net.Types.ActionType;
import mutts.net.Types.MatchBattle;
import mutts.net.Types.UnitTimeline;
import mutts.net.Value;

class BattleEvents {
	public static function normalize(event:Dynamic, match:Match):MatchBattle {
		final raw = Reflect.field(event, "events");
		if (!Std.isOfType(raw, Array))
			return [];

		final items:Array<Dynamic> = cast raw;
		return items.length == 0 ? [] : flat(items, match);
	}

	static function flat(items:Array<Dynamic>, match:Match):MatchBattle {
		final timelines = new Map<String, UnitTimeline>();
		final lastTimes = new Map<String, Float>();

		for (item in items) {
			final actionType = type(Value.str(item, ["type"]));
			final timestamp = time(item);
			final duration = duration(item, actionType);
			final actorId = Value.id(item, ["unit_id"]);
			final targetId = Value.id(item, ["target_id"]);

			switch actionType {
				case Walk:
					if (actorId != null) {
						final action:Action = {id: Walk, duration: duration};
						position(actorId, action, item, match);
						add(timelines, lastTimes, actorId, action, timestamp, item, match);
					}
				case Attack:
					if (actorId != null)
						add(timelines, lastTimes, actorId, {id: Attack, duration: duration}, timestamp, item, match);
					if (targetId != null) {
						final action:Action = {id: Damage, duration: defaultDuration(Damage)};
						damageStats(action, item);
						add(timelines, lastTimes, targetId, action, timestamp, item, match);
					}
				case Death:
					final id = actorId ?? targetId;
					if (id != null)
						add(timelines, lastTimes, id, {id: Death, duration: duration}, timestamp, item, match);
				case Damage:
					final id = targetId ?? actorId;
					if (id != null) {
						final action:Action = {id: Damage, duration: duration};
						damageStats(action, item);
						add(timelines, lastTimes, id, action, timestamp, item, match);
					}
				case Spawn | Idle:
			}
		}

		return [for (timeline in timelines) if (timeline.actions.length > 0) timeline];
	}

	static function add(timelines:Map<String, UnitTimeline>, lastTimes:Map<String, Float>, unitId:String, action:Action, timestamp:Null<Float>, raw:Dynamic,
			match:Match):Void {
		final timeline = get(timelines, unitId, raw, match);
		if (timestamp != null) {
			final last = lastTimes.exists(unitId) ? lastTimes.get(unitId) : 0.0;
			final gap = timestamp - last;
			if (gap > 0.01)
				timeline.actions.push({id: Idle, duration: gap});
			lastTimes.set(unitId, Math.max(last, timestamp + action.duration));
		}
		timeline.actions.push(action);
	}

	static function get(timelines:Map<String, UnitTimeline>, unitId:String, raw:Dynamic, match:Match):UnitTimeline {
		var timeline = timelines.get(unitId);
		if (timeline == null) {
			timeline = {id: unitId, actions: []};
			final unit = match.battleUnit(unitId);
			if (unit != null) {
				timeline.type = unit.type;
				timeline.level = unit.level;
			}
			timelines.set(unitId, timeline);
		}
		enrich(timeline, raw, match);
		return timeline;
	}

	static function enrich(timeline:UnitTimeline, raw:Dynamic, match:Match):Void {
		final unit = match.battleUnit(timeline.id);
		if (unit != null) {
			timeline.type = unit.type;
			timeline.level = unit.level;
		}

		final side = Value.int(raw, ["side", "team"]);
		if (side != null)
			timeline.side = side;
	}

	static function position(unitId:String, action:Action, raw:Dynamic, match:Match):Void {
		final rawPosition = Reflect.field(raw, "position");
		var x = Value.float(raw, ["x", "position_x"]);
		var y = Value.float(raw, ["y", "position_y"]);
		if (Std.isOfType(rawPosition, Array)) {
			final position:Array<Dynamic> = cast rawPosition;
			if (position.length > 0)
				x = Value.toFloat(position[0]) ?? x;
			if (position.length > 1)
				y = Value.toFloat(position[1]) ?? y;
		}

		if (x != null) {
			action.x = x;
			action.row = Std.int(Math.floor(x));
		}
		if (y != null) {
			final displayY = match.battleY(unitId, y);
			action.y = displayY;
			action.column = Std.int(Math.floor(displayY));
		}
	}

	static function damageStats(action:Action, raw:Dynamic):Void {
		final health = Value.int(raw, ["target_hp", "target_health", "target_remaining_hp", "target_hp_after", "remaining_hp", "hp_after", "new_hp"]);
		if (health != null)
			action.health = health;

		final maxHealth = Value.int(raw, ["target_max_hp", "target_max_health", "max_hp"]);
		if (maxHealth != null)
			action.maxHealth = maxHealth;

		final damage = Value.int(raw, ["damage", "damage_amount", "amount"]);
		if (damage != null)
			action.damage = damage;
	}

	static function time(raw:Dynamic):Null<Float>
		return Value.float(raw, ["time"]);

	static function duration(raw:Dynamic, id:ActionType):Float {
		final value = Value.float(raw, ["duration"]);
		return value == null ? defaultDuration(id) : Value.seconds(value);
	}

	static function type(value:Null<String>):ActionType {
		if (value == null)
			return Idle;
		return switch value.toLowerCase() {
			case "movement": Walk;
			case "attack": Attack;
			case "damage": Damage;
			case "death": Death;
			default: Idle;
		}
	}

	static function defaultDuration(id:ActionType):Float
		return switch id {
			case Spawn: 0.18;
			case Walk: 0.16;
			case Attack: 0.22;
			case Damage: 0.18;
			case Death: 0.35;
			case Idle: 0.12;
		}
}
