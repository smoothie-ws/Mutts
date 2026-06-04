package mutts.ui.screens;

import s.Animation;
import s.Easing;
import s.assets.Image;
import s.ui.Element;
import s.ui.Alignment;
import s.ui.elements.ImageElement;
import s.ui.elements.Label;
import s.ui.layouts.RowLayout;
import s.ui.layouts.ColumnLayout;
import s.app.input.MouseButton;
import s.stage2d.Stage;
import s.stage2d.objects.Sprite;
import mutts.GameState;
import mutts.game.BattleEvents;
import mutts.game.Unit;
import mutts.game.MatchPhase;
import mutts.game.Match;
import mutts.net.Value;
import mutts.ui.playground.PlaygroundUnit;
import mutts.ui.playground.PlaygroundPlayerCard;

class MatchScreen extends Screen {
	var stage:Stage;
	var opponentCard:PlaygroundPlayerCard;
	var playerCard:PlaygroundPlayerCard;
	var roundLabel:Label;
	var phaseLabel:Label;
	var timeLabel:Label;
	var balanceLabel:Label;
	var blockedOverlay:ImageElement<Image>;
	var introOverlay:Element;
	var introLabel:Label;

	var shopLayout:RowLayout;
	var benchLayout:ColumnLayout;
	var groundSprites:Array<PlaygroundUnit> = [];
	var battlePlayer:MatchBattlePlayer;
	var pendingBuySlot:Null<Int>;
	var introDismissed:Bool = false;
	var introCanDismiss:Bool = false;
	var introAnimation:Animation;
	var introScaleAnimation:Animation;
	var hudAnimation:Animation;
	var destroyed:Bool = false;

	public function new() {
		Game.client.onGameEvent(onGameEvent);
		Game.client.onFailed(showError);

		super();
		battlePlayer = new MatchBattlePlayer(() -> Game.match, stage, groundSprites, finishBattle);
		showMenu(false);
		setTime(Game.match.timer);
		refreshMatch();
		syncIntroVisibility(false);
	}

	public function setRound(round:Int)
		roundLabel.text = "ROUND " + Std.int(Math.max(1, round));

	public function setPhase(phase:MatchPhase) {
		phaseLabel.text = phase;
		if (blockedOverlay != null)
			blockedOverlay.opacity = phase == Preparation ? 0.25 : 0.0;
	}

	public function setTime(time:Int)
		timeLabel.text = Std.string(time);

	function setTimeText(text:String)
		timeLabel.text = text;

	public function setBalance(balance:Int)
		balanceLabel.text = "$" + balance;

	function setHealth() {
		playerCard.setHealth(Game.match.playerHealth);
		opponentCard.setHealth(Game.match.opponentHealth);
	}

	function buyUnit(i:Int) {
		if (pendingBuySlot != null || !Game.match.canBuy(i))
			return;

		final unit:Unit = Game.match.shop[i];
		pendingBuySlot = i;
		buildShop(shopLayout);
		Game.client.placeUnit(unit.type);
	}

	function takeUnit(i:Int) {
		final unit = Game.match.take(i);
		if (unit != null) {
			if (unit.serverId != null)
				Game.client.moveUnit(unit.serverId, unit.row, Game.match.boardY(unit.column), "board");
			refreshPlayground();
		}
	}

	function sellUnit(i:Int) {
		final unit = i < 0 || i >= Game.match.bench.length ? null : Game.match.bench[i];
		if (unit?.serverId != null)
			Game.client.sellUnit(unit.serverId);
	}

	function rebuildGround() {
		for (sprite in groundSprites)
			sprite.destroy();
		groundSprites.resize(0);

		final battle = Game.match.phase == Battle;
		final units = battle ? Game.match.battleUnits() : Game.match.ground;
		for (unit in units) {
			var sprite = battle ? new PlaygroundUnit(unit, stage, (_, _, _) -> false, _ -> {},
				_ -> {}) : new PlaygroundUnit(unit, stage, moveGroundUnit, commitGroundUnitMove, moveUnitToBench, Game.match.ownBoardMinColumn(),
					Game.match.ownBoardMaxColumn());
			stage.addChild(sprite);
			sprite.place(unit.row, unit.column);
			groundSprites.push(sprite);
		}
	}

	function refreshPlayground() {
		setBalance(Game.match.balance);
		buildShop(shopLayout);
		buildBench(benchLayout);
		rebuildGround();
	}

	function refreshMatch() {
		setRound(Game.match.round);
		setPhase(Game.match.phase);
		setHealth();
		refreshPlayground();
		syncIntroVisibility(true);
	}

	function moveGroundUnit(unit:Unit, row:Int, column:Int):Bool {
		return Game.match.moveGroundUnit(unit, row, column);
	}

	function commitGroundUnitMove(unit:Unit):Void {
		if (unit.serverId != null)
			Game.client.moveUnit(unit.serverId, unit.row, Game.match.boardY(unit.column), "board");
	}

	function moveUnitToBench(unit:Unit):Void {
		if (Game.match.moveToBench(unit)) {
			if (unit.serverId != null)
				Game.client.moveUnit(unit.serverId, Game.match.benchSlot(unit), 0, "bench");
			refreshPlayground();
		}
	}

	function finishBattle(playerHealth:Int, opponentHealth:Int) {
		if (destroyed || Game.match.phase == Preparation)
			return;

		Game.match.finishServerBattle(playerHealth, opponentHealth);
		refreshMatch();
	}

	function onGameEvent(event:Dynamic) {
		if (destroyed)
			return;

		switch event.type {
			case "game_state":
				pendingBuySlot = null;
				Game.match.syncGameState(event.state);
				if (isStartedGameState(event.state))
					introCanDismiss = true;
				setTime(Game.match.timer);
				refreshMatch();
			case "planning_phase_start":
				battlePlayer.reset();
				introCanDismiss = true;
				Game.match.beginServerPlanning(event);
				setTime(Game.match.timer);
				refreshMatch();
			case "timer_update":
				if (Game.match.phase == Preparation) {
					introCanDismiss = true;
					Game.match.timer = event.time_left;
					setTime(Game.match.timer);
					syncIntroVisibility(true);
				}
			case "unit_placed":
				if (isOwnEvent(event)) {
					final shopSlot = pendingBuySlot;
					pendingBuySlot = null;
					Game.match.applyUnitPlaced(event.unit, event.coins_left, shopSlot);
					refreshPlayground();
				}
			case "auto_merge":
				final merged = event.merged_unit ?? event.unit;
				final unitField = event.merged_unit != null ? "merged_unit" : "unit";
				final sourceIds:Array<String> = event.source_unit_ids ?? event.source_ids;
				if (merged != null && isOwnEvent(event, unitField)) {
					final shopSlot = pendingBuySlot;
					pendingBuySlot = null;
					Game.match.applyAutoMerge(merged, event.coins_left, sourceIds, shopSlot);
					refreshPlayground();
				}
			case "unit_moved":
				if (event.player == Game.player.nickname && Game.match.applyUnitMoved(event.unit_id, event.x, event.y, event.location))
					refreshPlayground();
			case "unit_sold":
				if (event.player == Game.player.nickname && Game.match.applyUnitSold(event.unit_id, event.coins_left))
					refreshPlayground();
			case "battle_phase_start":
				battlePlayer.reset();
				introCanDismiss = true;
				Game.match.beginServerBattle();
				Game.match.round = event.round;
				setTimeText("");
				refreshMatch();
			case "battle_events":
				if (event.state != null)
					Game.match.syncGameState(event.state);
				final battle = BattleEvents.normalize(event, Game.match);
				Game.match.applyBattlePreview(battle);
				if (battle.length > 0)
					battlePlayer.play(battle);
				else
					battlePlayer.syncPositions(false);
			case "battle_phase_end":
				Game.match.applyBattlePhaseEnd(event);
				battlePlayer.end(Game.match.playerHealth, Game.match.opponentHealth);
			case "game_over":
				Game.match.winner = event.winner == Game.player.nickname ? 0 : event.winner == "draw" ? null : 1;
				if (event.winner == "draw")
					GameUI.showPopup(GameUI.colors.yellow, "DRAW", false, () -> Game.state.goto(GameState.main));
				else
					showMatchWinner();
			default:
		}
	}

	function isOwnEvent(event:Dynamic, unitField:String = "unit"):Bool {
		if (event.player == Game.player.nickname)
			return true;

		final unit:Dynamic = Reflect.field(event, unitField);
		return unit != null && unit.owner == Game.player.nickname;
	}

	function showMatchWinner() {
		if (destroyed || Game.match.winner == null)
			return;

		final name = Game.match.winner == 0 ? Game.player.nickname : Game.match.opponent.nickname;
		function toMain() {
			Game.state.goto(GameState.main);
		}
		GameUI.showPopup(GameUI.colors.green, "WINNER: " + name, false, toMain);
	}

	function showError(message:String) {
		if (destroyed)
			return;

		pendingBuySlot = null;
		if (Game.match != null)
			refreshPlayground();
		GameUI.showPopup(GameUI.colors.red, message, false, () -> {});
	}

	function syncIntroVisibility(animate:Bool):Void {
		final active = shouldShowIntro();
		if (active) {
			if (introLabel != null)
				introLabel.text = introText();
			if (introOverlay != null) {
				introOverlay.isVisible = true;
				introOverlay.opacity = 1.0;
			}
			if (introLabel != null && introScaleAnimation == null)
				introScaleAnimation = Animation.mix(1.0, 1.5, 5.0, x -> introLabel.setScale(x)).ease(Easing.OutCubic).start();
			if (hud != null) {
				hud.opacity = 0.0;
				hud.isVisible = false;
			}
			if (stage != null)
				stage.opacity = 0.72;
			return;
		}

		if (introDismissed) {
			if (hud != null && !menu.isVisible) {
				hud.isVisible = true;
				hud.opacity = Game.settings.interfaceOpacity;
			}
			if (stage != null)
				stage.opacity = 1.0;
			if (introOverlay != null)
				introOverlay.isVisible = false;
			introScaleAnimation?.stop();
			introScaleAnimation = null;
			return;
		}

		if (hud != null && !menu.isVisible) {
			hud.isVisible = true;
			hudAnimation?.stop();
			if (animate)
				hudAnimation = Animation.mix(hud.opacity, Game.settings.interfaceOpacity, 0.25, x -> hud.opacity = x).ease(Easing.OutCubic).start();
			else
				hud.opacity = Game.settings.interfaceOpacity;
		}

		if (stage != null) {
			if (animate)
				Animation.mix(stage.opacity, 1.0, 0.35, x -> stage.opacity = x).ease(Easing.OutCubic).start();
			else
				stage.opacity = 1.0;
		}

		if (introOverlay != null && introOverlay.isVisible) {
			introAnimation?.stop();
			introScaleAnimation?.stop();
			introScaleAnimation = null;
			if (animate) {
				introAnimation = Animation.mix(introOverlay.opacity, 0.0, 0.25, x -> introOverlay.opacity = x)
					.ease(Easing.OutCubic)
					.onCompleted(() -> introOverlay.isVisible = false)
					.start();
			} else {
				introOverlay.opacity = 0.0;
				introOverlay.isVisible = false;
			}
		}
		introDismissed = true;
	}

	function shouldShowIntro():Bool
		return !introCanDismiss && !introDismissed && Game.match != null && Game.match.round <= 0;

	function isStartedGameState(state:Dynamic):Bool {
		if (state == null)
			return false;

		final phase = Value.str(state, ["phase"]);
		if (phase != null) {
			final normalized = phase.toLowerCase();
			if (normalized != "waiting" && normalized != "pending" && normalized != "created")
				return true;
		}

		final timer = Value.int(state, ["timer", "time_left"]);
		return timer != null && timer > 0;
	}

	function introText():String
		return Game.player.nickname + " VS " + Game.match.opponent.nickname;

	@:ui.markup override function markup() {
		stage = @stage2d {
			$anchors.fill($parent);
			$stageScale = 10;

			@Sprite("playground") {
				$x = -$parent.stageScale;
				$y = -$parent.stageScale;
				$scaleX = $parent.stageScale * 2.0;
				$scaleY = $parent.stageScale * 2.0;
			}
		}

		blockedOverlay = @image(Image.load("background_red")) {
			$opacity = 0.25;
			$anchors.fill($parent);
			$sampling = Trilinear;
			$fillMode = Cover;
		}

		hud = @layout {
			$anchors.fill($parent);
			$opacity = Game.match.round <= 0 ? 0.0 : Game.settings.interfaceOpacity;
			$isVisible = Game.match.round > 0;
			$padding = Game.settings.interfacePadding;

			@layout.row {
				$height = 130;
				$layout.fillWidth = true;
				$layout.alignment = AlignHCenter | AlignTop;
				$spacing = 25;

				opponentCard = @PlaygroundPlayerCard(Game.match.opponent.nickname, Game.match.opponentHealth, Match.maxHealth, 1, GameUI.colors.red,
					RightToLeft) {
						$layout.alignment = AlignCenter;
					}

				@column {
					$width = 500;
					$alignment = AlignCenter;
					$layout.alignment = AlignCenter;

					roundLabel = @markup(GameUI.label(White, "")) {
						$font.size = 24;
						$font.bold = true;
						$anchors.fillWidth($parent);
					}

					phaseLabel = @markup(GameUI.label(White, "")) {
						$font.size = 48;
						$font.bold = true;
						$anchors.fillWidth($parent);
					}

					timeLabel = @markup(GameUI.label(White, "")) {
						$anchors.fillWidth($parent);
					}
				}

				playerCard = @PlaygroundPlayerCard(Game.player.nickname, Game.match.playerHealth, Match.maxHealth, 2, GameUI.colors.cyan, LeftToRight) {
					$layout.alignment = AlignCenter;
				}
			}

			@markup(shopMarkup()) {}

			@markup(benchMarkup()) {}
		}

		introOverlay = @element {
			$anchors.fill($parent);
			$opacity = Game.match.round <= 0 ? 1.0 : 0.0;
			$isVisible = Game.match.round <= 0;

			@rectangle {
				$anchors.fill($parent);
				$color = 0x59000000;
				$radius = 0;
			}

			@column {
				$width = 1400;
				$height = 180;
				$anchors.centerIn($parent);
				$alignment = AlignCenter;

				introLabel = @markup(GameUI.label(White, introText())) {
					$width = 1400;
					$height = 100;
					$font.size = 56;
					$font.weight = 2500;
					$elideMode = ElideMiddle;
					$setScale(1.0);
				}
			}
		}
	}

	@:ui.markup function buildShop() {
		$children.destroy();

		for (i in 0...Game.match.shop.length) {
			var unit:Unit = Game.match.shop[i];
			var canBuy = pendingBuySlot == null && Game.match.canBuy(i);

			@markup(GameUI.unitSlot(GameUI.colors.cyan, "$" + unit.price)) {
				$isEnabled = canBuy;
				$opacity = canBuy ? 1.0 : 0.5;
				$onMousePressed(_->buyUnit(i));

				var label = cast($findChild("label"), s.ui.elements.Label);
				label.margins = 0;
				label.alignment = AlignHCenter | AlignBottom;

				@image(Image.load(unit.id.toLowerCase() + "_icon")) {
					$anchors.left = $parent.left;
					$anchors.right = $parent.right;
					$anchors.top = $parent.top;
					$anchors.bottom = label.top;
					$fillMode = Contain;
					$margins = 8;
					$bottom.margin = 0;
				}
			}
		}
	}

	@:ui.markup function buildBench() {
		$children.destroy();

		for (i in 0...Game.match.bench.length) {
			var unit:Unit = Game.match.bench[i];
			var canTake = Game.match.canTake(i);

			@markup(GameUI.unitSlot(GameUI.colors.cyan, "")) {
				$acceptedButtons = MouseButton.Left | MouseButton.Right;
				$opacity = canTake ? 1.0 : 0.5;
				$onMousePressed(b -> switch (b) {
					case Left: takeUnit(i);
					case Right: sellUnit(i);
					default:
				});

				@image(Image.load(unit.id.toLowerCase() + "_icon")) {
					$anchors.fill($parent);
					$fillMode = Contain;
					$margins = 12;
				}

				@markup(GameUI.label(White, Std.string(unit.level))) {
					$width = 35;
					$height = 35;
					$font.size = 18;
					$anchors.left = $parent.left;
					$anchors.top = $parent.top;
				}

				@markup(GameUI.label(GameUI.colors.green, "$" + unit.getSellPrice())) {
					$width = 75;
					$height = 35;
					$font.size = 18;
					$alignment = AlignRightTop;
					$margins = 5;
					$anchors.right = $parent.right;
					$anchors.top = $parent.top;
				}
			}
		}
	}

	@:ui.markup function shopMarkup() {
		shopLayout = @layout.row {
			$layout.fillWidth = true;
			$layout.fillHeight = true;
			$layout.horizontalStretchFactor = 1 / 2;
			$layout.verticalStretchFactor = 1 / 6;
			$layout.alignment = AlignHCenter | AlignBottom;
		}

		balanceLabel = @markup(GameUI.label(White, Std.string(Game.match.balance))) {
			$anchors.vCenter = shopLayout.vCenter;
			$anchors.left = shopLayout.right;
			$width = 500;
			$font.size = 48;
			$font.bold = true;
			$font.weight = 2500;
			$alignment = AlignLeft;
		}
	}

	@:ui.markup function benchMarkup() {
		benchLayout = @layout.column {
			$layout.fillWidth = true;
			$layout.fillHeight = true;
			$layout.horizontalStretchFactor = 1 / 10;
			$layout.verticalStretchFactor = 1 / 2;
			$layout.alignment = AlignVCenter | AlignRight;
		}
	}

	override function destroy() {
		destroyed = true;
		battlePlayer?.reset();
		for (sprite in groundSprites)
			sprite.destroy();
		groundSprites.resize(0);
		introAnimation?.stop();
		introScaleAnimation?.stop();
		hudAnimation?.stop();
		Game.client.offGameEvent(onGameEvent);
		Game.client.offFailed(showError);
		super.destroy();
	}
}
