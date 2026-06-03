package mutts.ui.screens;

import s.Timer;
import s.stage2d.Stage;
import mutts.game.Match;
import mutts.game.Unit;
import mutts.game.UnitType;
import mutts.net.Types.Action;
import mutts.net.Types.ActionType;
import mutts.net.Types.MatchBattle;
import mutts.net.Types.UnitTimeline;
import mutts.ui.playground.PlaygroundUnit;

class MatchBattlePlayer {
	final match:Void->Match;
	final stage:Stage;
	final sprites:Array<PlaygroundUnit>;
	final finish:Int->Int->Void;
	final queue:Array<MatchBattle> = [];

	var playing:Bool = false;
	var pendingEnd:Null<{playerHealth:Int, opponentHealth:Int}>;

	public function new(match:Void->Match, stage:Stage, sprites:Array<PlaygroundUnit>, finish:Int->Int->Void) {
		this.match = match;
		this.stage = stage;
		this.sprites = sprites;
		this.finish = finish;
	}

	public function reset():Void {
		playing = false;
		queue.resize(0);
		pendingEnd = null;
	}

	public function play(battle:MatchBattle):Void {
		if (battle.length == 0)
			return;

		queue.push(battle);
		if (!playing)
			next();
	}

	public function syncPositions(animate:Bool = true):Void {
		final current = match();
		if (current == null)
			return;

		for (unit in current.battleUnits()) {
			final sprite = unit.serverId == null ? null : find(unit.serverId);
			if (sprite == null) {
				final created = new PlaygroundUnit(unit, stage, (_, _, _) -> false, _ -> {}, _ -> {});
				stage.addChild(created);
				created.place(unit.row, unit.column);
				sprites.push(created);
			} else {
				sprite.syncStats(unit);
				sprite.moveTo(unit.row, unit.column, animate);
			}
		}
	}

	public function end(playerHealth:Int, opponentHealth:Int):Void {
		if (playing || queue.length > 0)
			pendingEnd = {playerHealth: playerHealth, opponentHealth: opponentHealth};
		else
			finish(playerHealth, opponentHealth);
	}

	function next():Void {
		final battle = queue.shift();
		if (battle == null) {
			playing = false;
			finishPendingEnd();
			return;
		}

		playing = true;
		run(battle, next);
	}

	function run(battle:MatchBattle, done:Void->Void):Void {
		var pending = 0;
		for (timeline in battle) {
			if (timeline.actions.length == 0)
				continue;
			pending++;
			timelineActions(timeline, timeline.actions.copy(), () -> if (--pending == 0) done());
		}
		if (pending == 0)
			Timer.set(done, 0.25);
	}

	function timelineActions(timeline:UnitTimeline, actions:Array<Action>, done:Void->Void):Void {
		final action = actions.shift();
		if (action == null) {
			done();
			return;
		}

		final sprite = spriteFor(timeline, action);
		if (sprite == null)
			Timer.set(() -> timelineActions(timeline, actions, done), Math.max(0.01, action.duration));
		else
			sprite.playAction(action, () -> {
				if (action.id == ActionType.Death) {
					sprites.remove(sprite);
					sprite.destroy();
				}
				timelineActions(timeline, actions, done);
			});
	}

	function spriteFor(timeline:UnitTimeline, action:Action):Null<PlaygroundUnit> {
		final found = find(timeline.id);
		if (found != null) {
			final current = match().battleUnit(timeline.id);
			if (current != null) {
				final syncHealth = action.id != ActionType.Damage || action.health != null || action.damage == null;
				found.syncStats(current, syncHealth);
			}
			return found;
		}

		var unit = match().battleUnit(timeline.id);
		if (unit == null) {
			unit = Unit.create(timeline.type ?? UnitType.BERSERKER, timeline.level ?? 1);
			unit.serverId = timeline.id;
		}

		final row = validRow(action.row) ? action.row : unit.row;
		final column = validColumn(action.column) ? action.column : unit.column;
		unit.row = validRow(row) ? row : 0;
		unit.column = validColumn(column) ? column : (timeline.side == 0 ? 0 : Match.columns - 1);

		final sprite = new PlaygroundUnit(unit, stage, (_, _, _) -> false, _ -> {}, _ -> {});
		stage.addChild(sprite);
		sprite.place(unit.row, unit.column);
		sprites.push(sprite);
		return sprite;
	}

	function find(id:String):Null<PlaygroundUnit> {
		for (sprite in sprites)
			if (sprite.unit.serverId == id)
				return sprite;
		return null;
	}

	function finishPendingEnd():Void {
		if (pendingEnd == null)
			return;

		final end = pendingEnd;
		pendingEnd = null;
		finish(end.playerHealth, end.opponentHealth);
	}

	static function validRow(row:Null<Int>):Bool
		return row != null && row >= 0 && row < Match.rows;

	static function validColumn(column:Null<Int>):Bool
		return column != null && column >= 0 && column < Match.columns;
}
