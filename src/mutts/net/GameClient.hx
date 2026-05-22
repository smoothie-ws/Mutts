package mutts.net;

import haxe.Json;
import s.Timer;
import s.net.Http;
import s.net.ws.WebSocketClient;
import mutts.net.Types;

using StringTools;

final API_ORIGIN = "http://193.53.40.62:8000";
final WS_ORIGIN = "ws://193.53.40.62:8000";

@:allow(Game)
class GameClient implements s.shortcut.Shortcut {
	var socket:WebSocketClient;
	var searchTimer:Timer;
	var currentUser:BackendUser;
	var accessToken:String;
	var refreshToken:String;
	var pendingMatch:Match;
	var didAnnounceMatch:Bool = false;

	var mockPlayerHealth:Int = mutts.game.Match.maxHealth;
	var mockOpponentHealth:Int = mutts.game.Match.maxHealth;

	function new() {}

	@:signal public function auth(profile:PlayerProfile);

	@:signal public function playerStats(stats:PlayerStats);

	@:signal public function globalStats(stats:GlobalStats);

	@:signal public function gameReady(match:Match);

	@:signal public function roundReady(response:MatchRoundResponse);

	@:signal public function gameEvent(event:Dynamic);

	@:signal public function failed(message:String);

	public function requestAuth(login:String, password:String) {
		if (!validateCredentials(login, password))
			return;

		var params:Map<String, String> = [];
		params.set("username", login);
		params.set("password", password);

		final tokens:AuthTokens = postForm("/auth/token", params);
		if (tokens == null || tokens.access_token == null || tokens.access_token == "")
			return;

		accessToken = tokens.access_token;
		refreshToken = tokens.refresh_token;

		final user:BackendUser = getJson("/auth/me", true);
		if (user == null)
			return;

		currentUser = user;
		auth(profile(user));
	}

	public function requestRegister(login:String, password:String) {
		if (!validateCredentials(login, password))
			return;

		final user:BackendUser = postJson("/auth/register", {
			username: login,
			password: password
		});
		if (user != null)
			requestAuth(login, password);
	}

	public function requestLeague(id:Int) {
		final leaderboard:LeaderboardResponse = getJson("/leaderboard");
		if (leaderboard == null)
			return;

		var selected:BackendUser = null;
		final stats:GlobalStats = [];
		for (user in leaderboard.players) {
			stats.push({
				id: user.id,
				nickname: user.username,
				mmr: user.rating
			});
			if (user.id == id)
				selected = user;
		}

		if (selected == null && currentUser != null && currentUser.id == id)
			selected = currentUser;

		globalStats(stats);

		if (selected == null) {
			failed("The backend only exposes profile stats for leaderboard users.");
			return;
		}

		playerStats({
			id: selected.id,
			mmr: selected.rating,
			win_count: 0,
			lose_count: 0
		});
	}

	public function requestGame() {
		if (!isAuthenticated())
			return;

		cancelSearchTimer();
		closeSocket();
		mockPlayerHealth = mutts.game.Match.maxHealth;
		mockOpponentHealth = mutts.game.Match.maxHealth;

		final result:Dynamic = postEmpty("/matchmaking/join?access_token=" + accessToken.urlEncode());
		if (result != null)
			pollMatchStatus();
	}

	public function cancelSearch() {
		cancelSearchTimer();
		if (accessToken != null)
			postEmpty("/matchmaking/leave?access_token=" + accessToken.urlEncode());
	}

	public function closeGame() {
		cancelSearchTimer();
		closeSocket();
		pendingMatch = null;
		didAnnounceMatch = false;
	}

	public function placeUnit(unitType:String)
		sendGame({
			type: "place_unit",
			unit_type: unitType
		});

	public function moveUnit(unitId:String, x:Int, y:Int, location:String)
		sendGame({
			type: "move_unit",
			unit_id: unitId,
			x: x,
			y: y,
			location: location
		});

	public function sellUnit(unitId:String)
		sendGame({
			type: "sell_unit",
			unit_id: unitId
		});

	public function requestRound(units:Array<UnitPlacement>) {
		// Local matches still consume timeline actions; backend battle events use
		// another model, so the renderer keeps this compatibility fallback.
		Timer.set(() -> roundReady(mockRound(units)), 0.25);
	}

	function pollMatchStatus() {
		final status:QueueStatus = getJson("/matchmaking/status?access_token=" + accessToken.urlEncode());
		if (status == null)
			return;

		switch status.status {
			case "in_game":
				if (status.game_id == null)
					failed("Matchmaking reported a game without a game id.");
				else
					connectGameSocket(status.game_id);
			case "searching":
				searchTimer = Timer.set(pollMatchStatus, 1.0);
			case "idle":
				failed("Matchmaking queue is idle.");
			default:
				failed("Unknown matchmaking status: " + status.status);
		}
	}

	function connectGameSocket(gameId:String) {
		cancelSearchTimer();
		pendingMatch = null;
		didAnnounceMatch = false;

		socket = new WebSocketClient(WS_ORIGIN + "/ws/game/" + gameId + "?access_token=" + accessToken.urlEncode(), "GAME", false);
		socket.onText(processText);
		socket.connect();
	}

	function sendGame(event:Dynamic) {
		if (socket == null || !socket.running) {
			failed("Game WebSocket is not connected.");
			return;
		}

		socket.send(Json.stringify(event));
	}

	function receiveGameState(state:BackendGameState) {
		if (currentUser == null || state == null)
			return;

		final isPlayer1 = state.player1.username == currentUser.username;
		final opponent = isPlayer1 ? state.player2.username : state.player1.username;
		pendingMatch = {
			opponent: {
				id: -1,
				nickname: opponent
			},
			location: isPlayer1 ? 0 : 1
		};

		if (state.round > 0)
			announceMatch();
	}

	function announceMatch() {
		if (didAnnounceMatch || pendingMatch == null)
			return;

		didAnnounceMatch = true;
		gameReady(pendingMatch);
	}

	function profile(user:BackendUser):PlayerProfile
		return {
			id: user.id,
			nickname: user.username
		};

	function validateCredentials(login:String, password:String):Bool {
		if (login.length > 0 && password.length > 0)
			return true;

		failed("Login and password are required.");
		return false;
	}

	function isAuthenticated():Bool {
		if (accessToken != null)
			return true;

		failed("Authentication is required.");
		return false;
	}

	function authHeaders():Map<s.net.http.Header, String> {
		final headers:Map<s.net.http.Header, String> = [];
		headers.set("Authorization", "Bearer " + accessToken);
		return headers;
	}

	function getJson<T>(path:String, authenticated:Bool = false):Null<T>
		return decodeResponse(Http.request(API_ORIGIN, {
			path: path,
			headers: authenticated ? authHeaders() : []
		}));

	function postEmpty<T>(path:String):Null<T>
		return decodeResponse(Http.request(API_ORIGIN, {
			path: path,
			method: Post
		}));

	function postForm<T>(path:String, params:Map<String, String>):Null<T>
		return decodeResponse(Http.request(API_ORIGIN, {
			path: path,
			method: Post,
			params: params
		}));

	function postJson<T>(path:String, data:Dynamic):Null<T> {
		final headers:Map<s.net.http.Header, String> = [];
		headers.set("Content-Type", "application/json");
		return decodeResponse(Http.request(API_ORIGIN, {
			path: path,
			method: Post,
			headers: headers,
			data: Json.stringify(data)
		}));
	}

	function decodeResponse<T>(response:s.net.HttpResponse):Null<T> {
		if (response == null) {
			failed("Backend did not return a response.");
			return null;
		}

		final status:Int = response.status;
		if (response.error != null || status < 200 || status >= 300) {
			failed(response.error ?? 'HTTP $status: ${response.statusText}');
			return null;
		}

		final body = response.data ?? response.bytes?.toString();
		if (body == null || body == "")
			return cast {};

		try {
			return Json.parse(body);
		} catch (e:Dynamic) {
			failed("Backend returned invalid JSON: " + Std.string(e));
			return null;
		}
	}

	function cancelSearchTimer() {
		searchTimer?.stop();
		searchTimer = null;
	}

	function closeSocket() {
		if (socket == null)
			return;

		if (socket.running)
			socket.close();
		socket = null;
	}

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

	function processText(text:String) {
		var msg:Dynamic = Json.parse(text);
		gameEvent(msg);

		switch msg.type {
			case "game_state":
				receiveGameState(msg.state);
			case "planning_phase_start":
				announceMatch();
			default:
				if (msg.success == false)
					failed(msg.error ?? "Backend rejected a game event.");
		}
	}
}
