package mutts.ui.playground;

import s.Easing;
import s.Animation;
import s.math.SMath;
import s.app.input.MouseButton;
import s.ui.elements.Interactive;
import s.stage2d.Stage;
import s.stage2d.objects.Sprite;
import mutts.game.Unit;
import mutts.game.Match;
import mutts.game.MatchPlayground;
import mutts.net.Types.Action;

class PlaygroundUnit extends Interactive {
	public final unit:Unit;
	final sprite:Sprite;
	final moveUnit:Unit->Int->Int->Bool;
	final commitMove:Unit->Void;
	final sendToBench:Unit->Void;
	final mouseMoveHandler:Int->Int->Int->Int->Void;

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

	public function new(unit:Unit, stage:Stage, moveUnit:Unit->Int->Int->Bool, commitMove:Unit->Void, sendToBench:Unit->Void) {
		this.unit = unit;
		this.sprite = new Sprite(unit.id.toLowerCase());
		this.sprite.stage = stage;
		this.moveUnit = moveUnit;
		this.commitMove = commitMove;
		this.sendToBench = sendToBench;
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
		syncFromUnit(true);
	}

	function updateDragPosition(mx:Int, my:Int, _:Int, _:Int):Void {
		if (!dragging || sprite.stage == null)
			return;

		var point = Match.pick(sprite.stage.screenToWorld(mx, my), MatchPlayground.columns);
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

		var point = Match.points[unit.row][unit.column];
		var screenPoint = sprite.stage.worldToScreen(point);
		var uiTarget = vec2(screenPoint.x - width * 0.5, screenPoint.y - height * 0.5);
		moveAnimation?.stop();

		if (animate) {
			final uiFrom = vec2(x, y);
			final spriteFrom = vec2(spriteCenterX, spriteCenterY);
			moveAnimation = new Animation(0.15, t -> {
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

	public function playAction(action:Action, done:Void->Void):Void {
		actionAnimation?.stop();
		final from = vec2(spriteCenterX, spriteCenterY);
		final uiFrom = vec2(x, y);
		final scaleFrom = spriteScale;
		final target = getActionTarget(action);
		final duration = Math.max(0.01, action.duration);

		if (action.id == Spawn && target != null) {
			x = target.ui.x;
			y = target.ui.y;
			spriteCenterX = target.point.x;
			spriteCenterY = target.point.y;
			spriteScale = 0.0;
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
				spriteScale = scaleFrom * (1.0 + Math.sin(t * Math.PI * 2) * 0.08);
				applySpriteTransform();
			case Death:
				spriteScale = scaleFrom * (1.0 - t * 0.5);
				applySpriteTransform();
			case Idle:
		}).ease(Easing.OutQuint).onCompleted(() -> {
			if (action.id == Walk && target != null) {
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
			applySpriteTransform();
			done();
		}).start();
	}

	function getActionTarget(action:Action) {
		if (action.row == null || action.column == null || sprite.stage == null)
			return null;
		if (action.row < 0 || action.row >= Match.rows || action.column < 0 || action.column >= Match.columns)
			return null;

		final point = Match.points[action.row][action.column];
		final screenPoint = sprite.stage.worldToScreen(point);
		return {
			row: action.row,
			column: action.column,
			point: point,
			ui: vec2(screenPoint.x - width * 0.5, screenPoint.y - height * 0.5)
		};
	}

	override function update() {
		syncFromUnit();
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

			@markup(GameWidgets.label(White, Std.string(unit.level))) {
				$width = 25;
			}

			@markup(GameWidgets.progress(GameUI.colors.green)) {
				$layout.fillWidth = true;
			}
		}
	}
}
