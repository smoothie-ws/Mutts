package mutts.ui.playground;

import s.Color;
import s.Easing;
import s.Animation;
import s.math.SMath;
import s.app.input.MouseButton;
import s.ui.elements.Interactive;
import s.ui.shapes.Rectangle;
import s.stage2d.Stage;
import s.stage2d.objects.Sprite;
import mutts.game.Unit;
import mutts.game.Match;
import mutts.net.Types.Action;

class PlaygroundUnit extends Interactive {
	public final unit:Unit;

	final sprite:Sprite;
	final moveUnit:Unit->Int->Int->Bool;
	final commitMove:Unit->Void;
	final sendToBench:Unit->Void;
	final mouseMoveHandler:Int->Int->Int->Int->Void;
	final minColumn:Int;
	final maxColumn:Int;

	var dragging:Bool = false;
	var dragStartRow:Int = 0;
	var dragStartColumn:Int = 0;
	var lastRow:Int = -1;
	var lastColumn:Int = -1;
	var lastStageWidth:Float = -1.0;
	var lastStageHeight:Float = -1.0;
	var lastStageScale:Float = -1.0;
	var spriteCenterX:Float = 0.0;
	var spriteCenterY:Float = 0.0;
	var spriteScale:Float = 1.0;
	var moveAnimation:Animation;
	var scaleAnimation:Animation;
	var actionAnimation:Animation;
	var healthTrack:Rectangle;
	var healthFill:Rectangle;

	public function new(unit:Unit, stage:Stage, moveUnit:Unit->Int->Int->Bool, commitMove:Unit->Void, sendToBench:Unit->Void, ?minColumn:Int = 0,
			?maxColumn:Int = Match.columns - 1) {
		this.unit = unit;
		this.sprite = new Sprite(unit.id.toLowerCase());
		this.sprite.stage = stage;
		this.moveUnit = moveUnit;
		this.commitMove = commitMove;
		this.sendToBench = sendToBench;
		this.minColumn = minColumn;
		this.maxColumn = maxColumn;
		this.mouseMoveHandler = updateDragPosition;
		super();

		cursor = Pointer;
		acceptedButtons = MouseButton.Left | MouseButton.Right;

		onMousePressed(b -> switch (b) {
			case Left:
				dragging = true;
				dragStartRow = unit.row;
				dragStartColumn = unit.column;
			case Right: sendToBench(unit);
			default:
		});
		onMouseReleased(b -> if (b == MouseButton.Left) {
			dragging = false;
			if (unit.row != dragStartRow || unit.column != dragStartColumn)
				commitMove(unit);
		});
		s.App.input.mouse.onMoved(mouseMoveHandler);

		onMouseEntered(() -> animateSpriteScale(1.1));
		onMouseExited(() -> animateSpriteScale(1.0));
		// press(Left, x, y);
	}

	public function place(row:Int, column:Int) {
		unit.row = row;
		unit.column = column;
		opacity = 1.0;
		sprite.opacity = 1.0;
		sprite.tint = White;
		syncFromUnit(true);
	}

	public function moveTo(row:Int, column:Int, animate:Bool = true):Void {
		if (unit.row == row && unit.column == column)
			return;

		unit.row = row;
		unit.column = column;
		syncFromUnit(true, animate);
	}

	public function syncStats(source:Unit, syncHealth:Bool = true):Void {
		if (syncHealth)
			unit.health = source.health;
		unit.maxHealth = source.maxHealth;
		unit.owner = source.owner;
		unit.location = source.location;
		updateHealthBar();
	}

	function updateDragPosition(mx:Int, my:Int, _:Int, _:Int):Void {
		if (!dragging || sprite.stage == null)
			return;

		var point = Match.pick(sprite.stage.screenToWorld(mx, my), minColumn, maxColumn);
		if (point != null && (point.row != unit.row || point.column != unit.column) && moveUnit(unit, point.row, point.column))
			syncFromUnit(true);
	}

	function syncFromUnit(force:Bool = false, animate:Bool = false):Void {
		if (sprite.stage == null)
			return;

		if (!force
			&& lastRow == unit.row
			&& lastColumn == unit.column
			&& lastStageWidth == sprite.stage.width
			&& lastStageHeight == sprite.stage.height
			&& lastStageScale == sprite.stage.stageScale)
			return;

		lastRow = unit.row;
		lastColumn = unit.column;
		lastStageWidth = sprite.stage.width;
		lastStageHeight = sprite.stage.height;
		lastStageScale = sprite.stage.stageScale;

		var point = Match.pointAt(unit.row, unit.column);
		var screenPoint = sprite.stage.worldToScreen(point);
		var uiTarget = vec2(screenPoint.x - width * 0.5, screenPoint.y - height * 0.5);
		moveAnimation?.stop();

		if (animate) {
			final uiFrom = vec2(x, y);
			final spriteFrom = vec2(spriteCenterX, spriteCenterY);
			moveAnimation = new Animation(0.22, t -> {
				final ui = mix(uiFrom, uiTarget, t);
				final center = mix(spriteFrom, point, t);
				x = ui.x;
				y = ui.y;
				spriteCenterX = center.x;
				spriteCenterY = center.y;
				applySpriteTransform();
			}).ease(Easing.OutQuint).start();
		} else {
			x = uiTarget.x;
			y = uiTarget.y;
			spriteCenterX = point.x;
			spriteCenterY = point.y;
			applySpriteTransform();
		}
	}

	function animateSpriteScale(to:Float):Void {
		scaleAnimation?.stop();
		scaleAnimation = Animation.mix(spriteScale, to, 0.15, v -> {
			spriteScale = v;
			applySpriteTransform();
		}).ease(Easing.OutQuint).start();
	}

	function applySpriteTransform():Void {
		sprite.setScale(spriteScale);
		sprite.x = spriteCenterX - spriteScale * 0.5;
		sprite.y = spriteCenterY - spriteScale * 0.5;
	}

	function updateHealthBar():Void {
		if (healthTrack == null || healthFill == null)
			return;

		final ownNickname = Game.player?.nickname;
		final color:Color = unit.owner != null && ownNickname != null && unit.owner != ownNickname ? GameUI.colors.red : GameUI.colors.cyan;
		final p = unit.maxHealth <= 0 ? 0.0 : Math.max(0.0, Math.min(1.0, unit.health / unit.maxHealth));
		healthTrack.color = rgba(color.r, color.g, color.b, 0.25);
		healthFill.color = color;
		healthFill.width = Math.max(0.0, (healthTrack.width - 2) * p);
	}

	public function playAction(action:Action, done:Void->Void):Void {
		actionAnimation?.stop();
		final from = vec2(spriteCenterX, spriteCenterY);
		final uiFrom = vec2(x, y);
		final scaleFrom = spriteScale;
		final target = getActionTarget(action);
		final duration = Math.max(0.01, action.duration);
		var appliedDamageStats = false;

		if (action.id == Spawn && target != null) {
			x = target.ui.x;
			y = target.ui.y;
			spriteCenterX = target.point.x;
			spriteCenterY = target.point.y;
			spriteScale = 0.0;
			opacity = 1.0;
			sprite.opacity = 1.0;
			sprite.tint = White;
			applySpriteTransform();
		}

		actionAnimation = new Animation(duration, t -> switch action.id {
			case Spawn:
				spriteScale = scaleFrom * t;
				applySpriteTransform();
			case Walk:
				if (target == null)
					spriteCenterY = from.y + Math.sin(t * Math.PI) * 0.15;
				else {
					final p = mix(from, target.point, t);
					final ui = mix(uiFrom, target.ui, t);
					x = ui.x;
					y = ui.y;
					spriteCenterX = p.x;
					spriteCenterY = p.y + Math.sin(t * Math.PI) * 0.08;
				}
				applySpriteTransform();
			case Attack:
				final direction = unit.column < Match.columns * 0.5 ? 1 : -1;
				spriteCenterX = from.x + Math.sin(t * Math.PI) * 0.25 * direction;
				applySpriteTransform();
			case Damage:
				if (!appliedDamageStats) {
					applyDamageStats(action);
					appliedDamageStats = true;
				}
				final pulse = Math.sin(t * Math.PI);
				spriteScale = scaleFrom * (1.0 + pulse * 0.08);
				sprite.tint = s.Color.rgba(1.0, 0.05, 0.05, pulse * 0.75);
				applySpriteTransform();
			case Death:
				final fade = 1.0 - t;
				spriteScale = scaleFrom * fade;
				opacity = fade;
				sprite.opacity = fade;
				applySpriteTransform();
			case Idle:
		}).ease(Easing.OutQuint).onCompleted(() -> {
			if (action.id == Walk && target != null) {
				if (target.row != null) {
					unit.row = target.row;
					lastRow = target.row;
				}
				if (target.column != null) {
					unit.column = target.column;
					lastColumn = target.column;
				}
				x = target.ui.x;
				y = target.ui.y;
				spriteCenterX = target.point.x;
				spriteCenterY = target.point.y;
			} else {
				spriteCenterX = from.x;
				spriteCenterY = from.y;
			}
			if (action.id == Spawn)
				spriteScale = scaleFrom;
			else if (action.id != Death)
				spriteScale = scaleFrom;
			if (action.id != Death) {
				opacity = 1.0;
				sprite.opacity = 1.0;
				sprite.tint = White;
			}
			applySpriteTransform();
			done();
		}).start();
	}

	function applyDamageStats(action:Action):Void {
		if (action.maxHealth != null)
			unit.maxHealth = action.maxHealth;
		if (action.health != null)
			unit.health = action.health;
		else if (action.damage != null)
			unit.health = Std.int(Math.max(0, unit.health - action.damage));
		updateHealthBar();
	}

	function getActionTarget(action:Action) {
		if (sprite.stage == null)
			return null;

		final row = action.row != null ? clampRow(action.row) : null;
		final column = action.column != null ? clampColumn(action.column) : null;
		final pointRow = clampRowFloat(row ?? action.x);
		final pointColumn = clampColumnFloat(column ?? action.y);
		if (pointRow == null || pointColumn == null)
			return null;

		final point = Match.pointAt(pointRow, pointColumn);
		final screenPoint = sprite.stage.worldToScreen(point);
		return {
			row: row,
			column: column,
			point: point,
			ui: vec2(screenPoint.x - width * 0.5, screenPoint.y - height * 0.5)
		};
	}

	static function clampRow(row:Int):Int
		return Std.int(Math.max(0, Math.min(Match.rows - 1, row)));

	static function clampColumn(column:Int):Int
		return Std.int(Math.max(0, Math.min(Match.columns - 1, column)));

	static function clampRowFloat(row:Null<Float>):Null<Float>
		return row == null ? null : Math.max(0.0, Math.min(Match.rows - 1, row));

	static function clampColumnFloat(column:Null<Float>):Null<Float>
		return column == null ? null : Math.max(0.0, Math.min(Match.columns - 1, column));

	override function update() {
		syncFromUnit();
		updateHealthBar();
		super.update();
	}

	override function destroy() {
		s.App.input.mouse.offMoved(mouseMoveHandler);
		moveAnimation?.stop();
		scaleAnimation?.stop();
		actionAnimation?.stop();
		sprite.stage = null;
		super.destroy();
	}

	@:ui.markup
	override function markup() {
		$width = 115;
		$height = 115;

		@layout.row {
			$anchors.left = $parent.left;
			$anchors.top = $parent.top;
			$anchors.right = $parent.right;
			$top.margin = -15;

			@markup(GameUI.label(White, Std.string(unit.level))) {
				$width = 25;
			}

			healthTrack = @rectangle {
				$layout.fillWidth = true;
				$height = 5;
				$radius = 50;
				$softness = 15;

				healthFill = @rectangle {
					$anchors.left = $parent.left;
					$anchors.top = $parent.top;
					$anchors.bottom = $parent.bottom;
					$margins = 1;
					$radius = 50;
					$softness = 2.5;
				}
			}
		}
	}
}
