package mutts.game;

import mutts.net.Types.Action;
import mutts.net.Types.ActionType;
import mutts.net.Types.MatchBattle;
import mutts.net.Types.UnitTimeline;
import mutts.net.Value;

class BattleEvents {
	public static function normalize(event:Dynamic, match:Match):MatchBattle {
		final raw = Value.field(event, ["events", "battle_events", "battle", "timelines"]);
		if (!Std.isOfType(raw, Array))
			return [];

		final items:Array<Dynamic> = cast raw;
		if (items.length == 0)
			return [];

		if (Reflect.hasField(items[0], "actions"))
			return [
				for (item in items) {
					final timeline = timeline(item, match);
					if (timeline.id != "" && timeline.actions.length > 0)
						timeline;
				}
			];

		return flat(items, match);
	}

	static function timeline(raw:Dynamic, match:Match):UnitTimeline {
		final id = Value.id(raw, ["id", "unit_id", "actor_id", "unit"]) ?? "";
		final timeline:UnitTimeline = {id: id, actions: []};
		enrich(timeline, raw, match);

		final rawActions = Value.field(raw, ["actions", "events"]);
		if (Std.isOfType(rawActions, Array))
			for (rawAction in (cast rawActions : Array<Dynamic>))
				timeline.actions.push(action(id, rawAction, match));
		return timeline;
	}

	static function flat(items:Array<Dynamic>, match:Match):MatchBattle {
		final timelines = new Map<String, UnitTimeline>();
		final lastTimes = new Map<String, Float>();

		for (item in items) {
			final type = type(Value.field(item, ["action", "event", "type", "event_type", "action_type", "kind", "name"]));
			final timestamp = time(item);
			final duration = duration(item, type);
			final actor = Value.id(item, ["unit_id", "actor_id", "source_id", "attacker_id", "unit", "actor", "source", "attacker", "id"]);
			final target = Value.id(item, ["target_id", "victim_id", "defender_id", "target", "victim", "defender"]);

			switch type {
				case Attack:
					if (actor != null)
						add(timelines, lastTimes, actor, {id: Attack, duration: duration}, timestamp, item, match);
					if (target != null)
						add(timelines, lastTimes, target, {id: Damage, duration: defaultDuration(Damage)}, timestamp, item, match);
				case Damage | Death:
					final id = target ?? actor;
					if (id != null)
						add(timelines, lastTimes, id, {id: type, duration: duration}, timestamp, item, match);
				case Walk | Spawn:
					if (actor != null) {
						final action:Action = {id: type, duration: duration};
						position(actor, action, item, match);
						add(timelines, lastTimes, actor, action, timestamp, item, match);
					}
				case Idle:
					if (actor != null)
						add(timelines, lastTimes, actor, {id: Idle, duration: duration}, timestamp, item, match);
			}
		}
		return [for (timeline in timelines) timeline];
	}

	static function action(unitId:String, raw:Dynamic, match:Match):Action {
		final id = type(Value.field(raw, ["id", "type", "action", "event", "event_type", "action_type", "kind", "name"]));
		final rawDuration = Value.float(raw, ["duration", "time", "length"]);
		final action:Action = {id: id, duration: Value.seconds(rawDuration ?? defaultDuration(id))};
		position(unitId, action, raw, match);
		return action;
	}

	static function add(timelines:Map<String, UnitTimeline>, lastTimes:Map<String, Float>, unitId:String, action:Action,
			timestamp:Null<Float>, raw:Dynamic, match:Match):Void {
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
		final data = Value.field(raw, ["unit", "source_unit", "actor_unit"]) ?? raw;
		final type = Value.str(data, ["type", "unit_type"]);
		final level = Value.int(data, ["level", "unit_level"]);
		final side = Value.int(raw, ["side", "team"]);
		if (type != null)
			timeline.type = cast type.toUpperCase();
		if (level != null)
			timeline.level = level;
		if (side != null)
			timeline.side = side;
	}

	static function position(unitId:String, action:Action, raw:Dynamic, match:Match):Void {
		final row = Value.int(raw, ["row", "x", "position_x", "to_x", "target_x"]);
		final column = Value.int(raw, ["column", "y", "position_y", "to_y", "target_y"]);
		if (row != null && row >= 0 && row < Match.rows)
			action.row = row;
		if (column != null)
			action.column = match.battleColumn(unitId, column);
	}

	static function time(raw:Dynamic):Null<Float> {
		final value = Value.float(raw, ["timestamp", "time", "time_offset", "offset", "t"]);
		return value == null ? null : Value.seconds(value);
	}

	static function duration(raw:Dynamic, id:ActionType):Float {
		final value = Value.float(raw, ["duration", "length"]);
		return value == null ? defaultDuration(id) : Value.seconds(value);
	}

	static function type(value:Dynamic):ActionType {
		if (value == null)
			return Idle;
		if (Std.isOfType(value, Int))
			return cast value;

		return switch Std.string(value).toLowerCase() {
			case "0" | "spawn" | "spawned" | "unit_spawned": Spawn;
			case "2" | "walk" | "move" | "moving" | "movement" | "unit_moved": Walk;
			case "3" | "attack" | "attacked" | "unit_attacked": Attack;
			case "4" | "damage" | "damaged" | "hit" | "unit_damaged": Damage;
			case "5" | "death" | "dead" | "die" | "died" | "unit_died" | "unit_killed": Death;
			default: Idle;
		}
	}

	static function defaultDuration(id:ActionType):Float
		return switch id {
			case Spawn: 0.18;
			case Walk: 0.35;
			case Attack: 0.22;
			case Damage: 0.18;
			case Death: 0.35;
			case Idle: 0.12;
		}
}
