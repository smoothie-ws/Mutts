package mutts.ui.screens;

import s.assets.Image;
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

	var shopLayout:RowLayout;
	var benchLayout:ColumnLayout;
	var groundSprites:Array<PlaygroundUnit> = [];
	var battlePlayer:MatchBattlePlayer;
	var pendingBuySlot:Null<Int>;

	public function new() {
		Game.client.onGameEvent(onGameEvent);
		Game.client.onFailed(showError);

		super();
		battlePlayer = new MatchBattlePlayer(() -> Game.match, stage, groundSprites, finishBattle);
		showMenu(false);
		setTime(Game.match.timer);
		refreshMatch();
	}

	public function setRound(round:Int)
		roundLabel.text = "ROUND " + round;

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
			var sprite = battle
				? new PlaygroundUnit(unit, stage, (_, _, _) -> false, _ -> {}, _ -> {})
				: new PlaygroundUnit(unit, stage, moveGroundUnit, commitGroundUnitMove, moveUnitToBench);
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
		Game.match.finishServerBattle(playerHealth, opponentHealth);
		refreshMatch();

		if (Game.match.winner != null)
			showMatchWinner();
	}

	function onGameEvent(event:Dynamic) {
		switch event.type {
			case "game_state":
				pendingBuySlot = null;
				Game.match.syncGameState(event.state);
				setTime(Game.match.timer);
				refreshMatch();
			case "planning_phase_start":
				Game.match.beginServerPlanning(event.round);
				Game.match.timer = event.time_left;
				setTime(Game.match.timer);
				refreshMatch();
			case "timer_update":
				if (Game.match.phase == Preparation) {
					Game.match.timer = event.time_left;
					setTime(Game.match.timer);
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
				Game.match.beginServerBattle();
				Game.match.round = event.round;
				setTimeText("");
				refreshMatch();
			case "battle_events":
				battlePlayer.play(BattleEvents.normalize(event, Game.match));
			case "battle_phase_end":
				final ownHp = Game.match.location == 0 ? event.player1_hp : event.player2_hp;
				final enemyHp = Game.match.location == 0 ? event.player2_hp : event.player1_hp;
				battlePlayer.end(ownHp, enemyHp);
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
		final name = Game.match.winner == 0 ? Game.player.nickname : Game.match.opponent.nickname;
		function toMain() {
			Game.state.goto(GameState.main);
		}
		GameUI.showPopup(GameUI.colors.green, "WINNER: " + name, false, toMain);
	}

	function showError(message:String) {
		pendingBuySlot = null;
		if (Game.match != null)
			refreshPlayground();
		GameUI.showPopup(GameUI.colors.red, message, false, () -> {});
	}

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
			$opacity = Game.settings.interfaceOpacity;
			$padding = Game.settings.interfacePadding;

			@layout.row {
				$height = 130;
				$layout.fillWidth = true;
				$layout.alignment = AlignHCenter | AlignTop;
				$spacing = 25;

				opponentCard = @PlaygroundPlayerCard(Game.match.opponent.nickname, Game.match.opponentHealth, Match.maxHealth, 1, GameUI.colors.red, RightToLeft) {
					$layout.alignment = AlignCenter;
				}

				@column {
					$width = 500;
					$alignment = AlignCenter;
					$layout.alignment = AlignCenter;

					roundLabel = @markup(GameWidgets.label(White, "")) {
						$font.size = 24;
						$font.bold = true;
						$anchors.fillWidth($parent);
					}

					phaseLabel = @markup(GameWidgets.label(White, "")) {
						$font.size = 48;
						$font.bold = true;
						$anchors.fillWidth($parent);
					}

					timeLabel = @markup(GameWidgets.label(White, "")) {
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
	}

	@:ui.markup function buildShop() {
		$children.destroy();

		for (i in 0...Game.match.shop.length) {
			var unit:Unit = Game.match.shop[i];
			var canBuy = pendingBuySlot == null && Game.match.canBuy(i);

			@markup(GameWidgets.unitSlot(GameUI.colors.cyan, "$" + unit.price)) {
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

			@markup(GameWidgets.unitSlot(GameUI.colors.cyan, "")) {
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

				@markup(GameWidgets.label(White, Std.string(unit.level))) {
					$width = 35;
					$height = 35;
					$font.size = 18;
					$anchors.left = $parent.left;
					$anchors.top = $parent.top;
				}

				@markup(GameWidgets.label(GameUI.colors.green, "$" + unit.getSellPrice())) {
					$width = 75;
					$height = 35;
					$font.size = 18;
					$alignment = AlignRightCenter;
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

		balanceLabel = @markup(GameWidgets.label(White, Std.string(Game.match.balance))) {
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
		Game.client.offGameEvent(onGameEvent);
		Game.client.offFailed(showError);
		super.destroy();
	}
}
