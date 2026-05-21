package mutts.net;

import haxe.Json;
import s.Timer;
import s.net.ws.WebSocketClient;
import mutts.net.Types;

final HOST = "localhost:8080";
typedef Message = {type:String, data:Dynamic}

@:allow(Game)
class GameClient extends WebSocketClient {
	var mockPlayerHealth:Int = mutts.game.Match.maxHealth;
	var mockOpponentHealth:Int = mutts.game.Match.maxHealth;

	function new() {
		super(HOST, false);
		Timer.set(() -> opened(), 2);
	}

	@:signal public function auth(progile:PlayerProfile);

	@:signal public function playerStats(stats:PlayerStats);

	@:signal public function globalStats(stats:GlobalStats);

	@:signal public function gameReady(match:Match);

	@:signal public function roundReady(response:MatchRoundResponse);

	public function requestAuth(login:String, password:String) {
		// request("auth", {login: login, password: password});
		Timer.set(() -> text(Json.stringify({
			type: "auth",
			data: Json.stringify({nickname: "pisapopa", id: 1})
		})), 2);
	}

	public function requestLeague(id:Int) {
		// request("stats.player", {id: Game.player.id});

		Timer.set(() -> text(Json.stringify({
			type: "stats.player",
			data: Json.stringify({
				id: id,
				mmr: Std.int(Math.random() * 10000),
				win_count: Std.int(Math.random() * 1000),
				lose_count: Std.int(Math.random() * 1000)
			})
		})), 2);

		Timer.set(() -> text(Json.stringify({
			type: "stats.global",
			data: Json.stringify([
				{id: 0, nickname: "LIZA", mmr: 8000},
				{id: 1, nickname: "LIZA1", mmr: 7000},
				{id: 2, nickname: "LIZA2", mmr: 6000},
				{id: 3, nickname: "LIZA3", mmr: 5000},
				{id: 4, nickname: "LIZA4", mmr: 4000},
				{id: 5, nickname: "LIZA5", mmr: 2000},
			])
		})), 2);
	}

	public function requestGame() {
		// request("game.join", {id: Game.player.id});
		mockPlayerHealth = mutts.game.Match.maxHealth;
		mockOpponentHealth = mutts.game.Match.maxHealth;

		Timer.set(() -> text(Json.stringify({
			type: "game.ready",
			data: Json.stringify({
				opponent: {
					id: 1,
					nickname: "Opponent",
				},
				location: 0
			})
		})), 2);
	}

	public function requestRound(units:Array<UnitPlacement>) {
		// request("game.round", units);
		Timer.set(() -> roundReady(mockRound(units)), 0.25);
	}

	function request(type:String, data:Dynamic)
		send(Json.stringify({type: type, data: data}));

	function decode<T>(data:Dynamic):T
		return Std.isOfType(data, String) ? Json.parse(data) : data;

	function mockRound(units:Array<UnitPlacement>):MatchRoundResponse {
		var playerDamage = 0;
		for (unit in units)
			playerDamage += unit.level;
		final opponentDamage = units.length == 0 ? 2 : Std.random(3);
		mockOpponentHealth = Std.int(Math.max(0, mockOpponentHealth - playerDamage));
		mockPlayerHealth = Std.int(Math.max(0, mockPlayerHealth - opponentDamage));
		final battle:MatchBattle = [];

		for (unit in units) {
			final column = Std.int(Math.min(7, unit.column + 1));
			battle.push({
				id: unit.id,
				side: 0,
				level: unit.level,
				actions: [
					{id: Spawn, duration: 0.1, row: unit.row, column: unit.column},
					{id: Idle, duration: 0.15},
					{id: Walk, duration: 0.45, row: unit.row, column: column},
					{id: Attack, duration: 0.25},
					{id: Damage, duration: 0.18},
					{id: Idle, duration: 0.1}
				]
			});
		}

		for (enemy in [
			{id: -1, type: 1, level: 1, row: 2, column: 7},
			{id: -2, type: 6, level: 1, row: 5, column: 7}
		]) {
			final death = playerDamage > 0 && enemy.id == -1;
			final actions = [
				{id: Spawn, duration: 0.15, row: enemy.row, column: enemy.column},
				{id: Idle, duration: 0.25},
				{id: Walk, duration: 0.5, row: enemy.row, column: enemy.column - 2},
				{id: Attack, duration: 0.25},
				{id: Damage, duration: 0.2}
			];
			if (death)
				actions.push({id: Death, duration: 0.35});
			else
				actions.push({id: Idle, duration: 0.35});

			battle.push({
				id: enemy.id,
				type: enemy.type,
				level: enemy.level,
				side: 1,
				actions: actions
			});
		}

		return {
			battle: battle,
			result: {
				playerHealth: mockPlayerHealth,
				opponentHealth: mockOpponentHealth,
				winner: mockOpponentHealth <= 0 ? 0 : mockPlayerHealth <= 0 ? 1 : null
			}
		}
	}

	@:slot(text)
	function processText(text:String) {
		var msg:Message = Json.parse(text);

		switch msg.type {
			case "auth":
				auth(decode(msg.data));
			case "stats.player":
				playerStats(decode(msg.data));
			case "stats.global":
				globalStats(decode(msg.data));
			case "game.ready":
				gameReady(decode(msg.data));
			case "game.round":
				roundReady(decode(msg.data));
		}
	}
}
