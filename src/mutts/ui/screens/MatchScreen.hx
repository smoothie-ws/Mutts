package mutts.ui.screens;

import s.assets.Image;
import s.Timer;
import s.ui.Alignment;
import s.ui.elements.ImageElement;
import s.ui.elements.Label;
import s.ui.layouts.RowLayout;
import s.ui.layouts.ColumnLayout;
import s.app.input.MouseButton;
import s.stage2d.Stage;
import s.stage2d.objects.Sprite;
import mutts.GameState;
import mutts.game.Unit;
import mutts.game.MatchPhase;
import mutts.game.Match;
import mutts.net.Types.Action;
import mutts.net.Types.MatchBattle;
import mutts.net.Types.MatchRoundResponse;
import mutts.net.Types.MatchRoundResult;
import mutts.net.Types.UnitTimeline;
import mutts.ui.playground.PlaygroundUnit;
import mutts.ui.playground.PlaygroundPlayerCard;

class MatchScreen extends Screen {
	static inline final preparationTime:Int = 20;

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
	var roundTimer:Timer;
	var nextRoundTimer:Timer;
	var timeLeft:Int = 0;

	public function new() {
		// temp
		if (Game.player == null)
			Game.player = {id: 0, nickname: "Player"};
		if (Game.match == null)
			Game.match = new Match({id: 1, nickname: "Opponent"}, 0);
		Game.client.onRoundReady(onRoundReady);

		super();
		showMenu(false);

		buildShop(shopLayout);
		buildBench(benchLayout);
		rebuildGround();
		startRound();
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
		if (Game.match.buy(i) != null)
			refreshPlayground();
	}

	function takeUnit(i:Int) {
		if (Game.match.take(i) != null)
			refreshPlayground();
	}

	function sellUnit(i:Int) {
		if (Game.match.sell(i) != null)
			refreshPlayground();
	}

	function rebuildGround() {
		for (sprite in groundSprites)
			sprite.destroy();
		groundSprites.resize(0);

		for (unit in Game.match.ground) {
			var sprite = new PlaygroundUnit(unit, stage, moveGroundUnit, moveUnitToBench);
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

	function moveGroundUnit(unit:Unit, row:Int, column:Int):Bool
		return Game.match.moveGroundUnit(unit, row, column);

	function moveUnitToBench(unit:Unit):Void {
		if (Game.match.moveToBench(unit))
			refreshPlayground();
	}

	function startRound() {
		if (!Game.match.startRound())
			return;
		setRound(Game.match.round);
		setPhase(Game.match.phase);
		setHealth();
		setTimer(preparationTime);
		refreshPlayground();
	}

	function setTimer(seconds:Int) {
		roundTimer?.stop();
		timeLeft = seconds;
		setTime(timeLeft);
		roundTimer = Timer.set(tickTimer, 1.0);
	}

	function tickTimer() {
		if (Game.match.phase != Preparation)
			return;
		setTime(--timeLeft);
		if (timeLeft <= 0)
			submitPlacement();
		else
			roundTimer = Timer.set(tickTimer, 1.0);
	}

	function submitPlacement() {
		if (Game.match.phase != Preparation)
			return;
		roundTimer?.stop();
		final placement = Game.match.submitPlacement();
		if (placement == null)
			return;
		setPhase(Game.match.phase);
		setTimeText("...");
		refreshPlayground();
		Game.client.requestRound(placement);
	}

	function onRoundReady(response:MatchRoundResponse) {
		if (!Game.match.beginBattle())
			return;
		setPhase(Game.match.phase);
		setTimeText("");
		refreshPlayground();
		playBattle(response.battle, () -> finishRound(response.result));
	}

	function playBattle(battle:MatchBattle, done:Void->Void) {
		var pending = 0;
		for (timeline in battle) {
			pending++;
			playTimeline(timeline, timeline.actions.copy(), () -> if (--pending == 0) done());
		}
		if (pending == 0)
			Timer.set(done, 0.25);
	}

	function playTimeline(timeline:UnitTimeline, actions:Array<Action>, done:Void->Void):Void {
		final action = actions.shift();
		if (action == null) {
			done();
			return;
		}

		final sprite = action.id == Spawn ? ensureBattleSprite(timeline, action) : findGroundSprite(timeline.id);
		if (sprite == null) {
			Timer.set(() -> playTimeline(timeline, actions, done), Math.max(0.01, action.duration));
			return;
		}

		sprite.playAction(action, () -> playTimeline(timeline, actions, done));
	}

	function ensureBattleSprite(timeline:UnitTimeline, action:Action):PlaygroundUnit {
		final found = findGroundSprite(timeline.id);
		if (found != null)
			return found;

		final side = timeline.side ?? 1;
		final row = action.row ?? 0;
		final column = action.column ?? (side == 0 ? 0 : Match.columns - 1);
		final unit = Unit.create(cast(timeline.type ?? 0), timeline.level ?? 1);
		unit.matchId = timeline.id;
		unit.row = row;
		unit.column = column;

		final sprite = new PlaygroundUnit(unit, stage, (_, _, _) -> false, _ -> {});
		stage.addChild(sprite);
		sprite.place(row, column);
		groundSprites.push(sprite);
		return sprite;
	}

	function findGroundSprite(id:Int):Null<PlaygroundUnit> {
		for (sprite in groundSprites)
			if (sprite.unit.matchId == id)
				return sprite;
		return null;
	}

	function finishRound(result:MatchRoundResult) {
		if (!Game.match.finishRound(result))
			return;
		setPhase(Game.match.phase);
		setHealth();
		refreshPlayground();

		if (Game.match.winner != null)
			showMatchWinner();
		else
			nextRoundTimer = Timer.set(() -> {
				if (Game.match.nextRound())
					startRound();
			}, 2.0);
	}

	function showMatchWinner() {
		final name = Game.match.winner == 0 ? Game.player.nickname : Game.match.opponent.nickname;
		function toMain() {
			Game.state.goto(GameState.main);
		}
		GameUI.showPopup(GameUI.colors.green, "WINNER: " + name, false, toMain);
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
				$height = 100;
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
			var canBuy = Game.match.canBuy(i);
			var color = Game.match.willBuyMerge(i) ? GameUI.colors.yellow : GameUI.colors.cyan;

			@markup(GameWidgets.button(color, "$" + unit.price)) {
				$isEnabled = canBuy;
				$opacity = canBuy ? 1.0 : 0.5;
				$layout.alignment = AlignCenter;
				$layout.fillWidth = true;
				$layout.fillHeight = true;
				$layout.minimumWidth = 100;
				$layout.maximumWidth = 200;
				$layout.minimumHeight = 100;
				$layout.maximumHeight = 200;
				$onMousePressed(_->buyUnit(i));

				var label = cast($findChild("label"), s.ui.elements.Label);
				label.margins = 15;
				label.alignment = AlignHCenter | AlignBottom;

				@image(Image.load(unit.id + "_icon")) {
					$anchors.fill($parent);
					$fillMode = Contain;
					$margins = 15;
					$bottom.margin = 50;
				}
			}
		}
	}

	@:ui.markup function buildBench() {
		$children.destroy();

		for (i in 0...Game.match.bench.length) {
			var unit:Unit = Game.match.bench[i];
			var canTake = Game.match.canTake(i);

			@markup(GameWidgets.button(GameUI.colors.cyan, "")) {
				$acceptedButtons = MouseButton.Left | MouseButton.Right;
				$opacity = canTake ? 1.0 : 0.5;
				$layout.alignment = AlignCenter;
				$layout.fillWidth = true;
				$layout.fillHeight = true;
				$layout.minimumWidth = 100;
				$layout.maximumWidth = 200;
				$layout.minimumHeight = 100;
				$layout.maximumHeight = 200;
				$onMousePressed(b -> switch (b) {
					case Left: takeUnit(i);
					case Right: sellUnit(i);
					default:
				});

				@image(Image.load(unit.id + "_icon")) {
					$anchors.fill($parent);
					$fillMode = Contain;
					$margins = 15;
				}

				@markup(GameWidgets.label(White, Std.string(unit.level))) {
					$width = 35;
					$height = 35;
					$font.size = 18;
					$anchors.left = $parent.left;
					$anchors.top = $parent.top;
					$left.margin = 10;
					$top.margin = 10;
				}

				@markup(GameWidgets.label(GameUI.colors.green, "$" + unit.getSellPrice())) {
					$width = 75;
					$height = 35;
					$font.size = 18;
					$anchors.right = $parent.right;
					$anchors.top = $parent.top;
					$right.margin = 10;
					$top.margin = 10;
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
		Game.client.offRoundReady(onRoundReady);
		roundTimer?.stop();
		nextRoundTimer?.stop();
		super.destroy();
	}
}
