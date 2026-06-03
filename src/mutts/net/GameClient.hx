package mutts.net;

import haxe.Json;
import s.Timer;
import s.net.Http;
import s.net.ws.WebSocketClient;
import mutts.game.BackendState;
import mutts.game.GameConfigs;
import mutts.game.UnitType;
import mutts.net.Types;

using StringTools;

final WS_ORIGIN = "ws://193.53.40.62:8000";
final BACKEND_ORIGIN = "http://193.53.40.62:8000";

@:allow(Game)
class GameClient implements s.shortcut.Shortcut {
	final api:BackendApi;
	var socket:WebSocketClient;
	var searchTimer:Timer;
	var currentUsername:String;
	var pendingMatch:Match;
	var didAnnounceMatch:Bool = false;
	var searchId:Int = 0;

	function new()
		api = new BackendApi(BACKEND_ORIGIN, message -> failed(message));

	@:signal public function auth(profile:PlayerProfile);

	@:signal public function globalStats(stats:GlobalStats);

	@:signal public function userStatistics(stats:BackendUser);

	@:signal public function gameReady(match:Match);

	@:signal public function gameEvent(event:Dynamic);

	@:signal public function failed(message:String);

	public function requestConfigs():Void {
		final unitConfigs:Array<UnitConfig> = api.get("/unit-configs", false, false);
		if (unitConfigs != null)
			GameConfigs.setUnitConfigs(unitConfigs);

		final gameConfig:BackendGameConfig = api.get("/game-config", false, false);
		if (gameConfig != null)
			GameConfigs.setGameConfig(gameConfig);
	}

	public function requestAuth(login:String, password:String, reportError:Bool = true):Bool {
		if (!validateCredentials(login, password, reportError))
			return false;

		var params:Map<String, String> = [];
		params.set("username", login);
		params.set("password", password);

		final tokens:AuthTokens = api.postForm("/auth/token", params, reportError);
		if (tokens == null || tokens.access_token == null || tokens.access_token == "")
			return false;

		api.setTokens(tokens);

		final user:BackendUser = api.get("/auth/me", true, reportError);
		if (user != null) {
			currentUsername = user.username;
			auth(profile(user));
			return true;
		}

		currentUsername = login;
		auth({
			id: 0,
			nickname: login
		});
		return true;
	}

	public function requestRegister(login:String, password:String):Bool {
		if (!validateCredentials(login, password))
			return false;

		final user:BackendUser = api.postJson("/auth/register", {
			username: login,
			password: password
		});
		if (user != null)
			return requestAuth(login, password);
		return false;
	}

	public function requestLeague() {
		final response:LeaderboardResponse = api.get("/leaderboard");
		if (response == null || response.players == null)
			return;

		final stats:GlobalStats = [
			for (player in response.players)
				{
					id: player.id,
					nickname: player.username,
					mmr: player.rating,
					win_count: player.win_count,
					lose_count: player.lose_count,
					draw_count: player.draw_count
				}
		];
		globalStats(stats);
	}

	public function requestUserStatistics(player:GlobalStat):Void {
		if (!isAuthenticated())
			return;

		final fallback = fallbackStatistics(player);
		final path = "/user/statistics?username=" + player.nickname.urlEncode();
		api.getAsync(path, true, (stats:BackendUser) -> {
			if (stats != null && sameStatisticsUser(stats, player)) {
				userStatistics(stats);
				return;
			}

			api.getAsync("/user/statistics", true, (ownStats:BackendUser) -> {
				userStatistics(ownStats != null && sameStatisticsUser(ownStats, player) ? ownStats : fallback);
			}, () -> false);
		}, () -> false);
	}

	public function requestGame() {
		if (!isAuthenticated())
			return;

		final id = ++searchId;
		cancelSearchTimer();
		closeSocket();

		// Join matchmaking queue - backend will automatically create game when 2 players found.
		joinMatchmaking(id);
	}

	public function reconnectGame() {
		if (!isAuthenticated())
			return;

		final id = ++searchId;
		cancelSearchTimer();
		closeSocket();
		connectExistingMatch(id, "Unable to reconnect to the current match.");
	}

	public function cancelSearch() {
		++searchId;
		cancelSearchTimer();
		if (api.hasToken())
			api.postEmptyAsync(api.tokenPath("/matchmaking/leave"), _ -> {}, () -> false);
	}

	public function closeGame() {
		++searchId;
		cancelSearchTimer();
		closeSocket();
		pendingMatch = null;
		didAnnounceMatch = false;
	}

	public function logout():Void {
		closeGame();
		cancelSearch();
		api.clearTokens();
		currentUsername = null;
		pendingMatch = null;
		didAnnounceMatch = false;
	}

	public function placeUnit(unitType:UnitType)
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

	function pollMatchStatus(id:Int) {
		searchTimer = null;

		if (!isCurrentSearch(id) || !isAuthenticated())
			return;

		api.getAsync(api.tokenPath("/matchmaking/status"), false, (status:QueueStatus) -> {
			if (!isCurrentSearch(id) || status == null)
				return;

			if (connectStatusGame(status))
				return;

			scheduleMatchStatusPoll(id);
		}, () -> isCurrentSearch(id));
	}

	function joinMatchmaking(id:Int) {
		api.postEmptyAsync(api.tokenPath("/matchmaking/join"), (status:QueueStatus) -> {
			if (!isCurrentSearch(id) || status == null)
				return;

			if (connectStatusGame(status))
				return;

			if (isAlreadyInGame(status.message) || isAlreadyInGame(status.status)) {
				connectExistingMatch(id);
				return;
			}

			scheduleMatchStatusPoll(id);
		}, () -> false, message -> {
			if (!isCurrentSearch(id))
				return;

			if (isAlreadyInGame(message)) {
				connectExistingMatch(id, message);
				return;
			}

			connectExistingMatch(id, message);
		});
	}

	function connectExistingMatch(id:Int, ?fallbackError:String) {
		api.getAsync(api.tokenPath("/matchmaking/status"), false, (status:QueueStatus) -> {
			if (!isCurrentSearch(id) || status == null)
				return;

			if (connectStatusGame(status))
				return;

			if (fallbackError != null) {
				failed(fallbackError);
				return;
			}

			scheduleMatchStatusPoll(id);
		}, () -> isCurrentSearch(id));
	}

	function connectStatusGame(status:QueueStatus):Bool {
		if (status == null || status.game_id == null || status.game_id == "")
			return false;

		connectGameSocket(status.game_id);
		return true;
	}

	function connectGameSocket(gameId:String) {
		cancelSearchTimer();
		closeSocket();
		pendingMatch = null;
		didAnnounceMatch = false;

		socket = new WebSocketClient(WS_ORIGIN + "/ws/game/" + gameId + "?access_token=" + api.encodedToken(), "GAME", false);
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
		if (currentUsername == null || state == null)
			return;

		final isPlayer1 = state.player1.username == currentUsername;
		final opponent = isPlayer1 ? state.player2.username : state.player1.username;
		pendingMatch = {
			opponent: {
				id: -1,
				nickname: opponent
			},
			location: isPlayer1 ? 0 : 1,
			state: state
		};

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

	function fallbackStatistics(player:GlobalStat):BackendUser
		return {
			id: player.id,
			username: player.nickname,
			rating: player.mmr,
			win_count: player.win_count,
			lose_count: player.lose_count,
			draw_count: player.draw_count
		};

	function sameStatisticsUser(stats:BackendUser, player:GlobalStat):Bool
		return stats.username == player.nickname || stats.id == player.id;

	function validateCredentials(login:String, password:String, reportError:Bool = true):Bool {
		if (login.length > 0 && password.length > 0)
			return true;

		if (reportError)
			failed("Login and password are required.");
		return false;
	}

	function isAuthenticated():Bool {
		if (api.hasToken())
			return true;

		failed("Authentication is required.");
		return false;
	}

	function isCurrentSearch(id:Int):Bool
		return searchId == id;

	function isAlreadyInGame(message:Null<String>):Bool {
		if (message == null)
			return false;
		final normalized = message.toLowerCase();
		return normalized.indexOf("already") != -1 && normalized.indexOf("game") != -1;
	}


	function cancelSearchTimer() {
		searchTimer?.stop();
		searchTimer = null;
	}

	function scheduleMatchStatusPoll(id:Int)
		searchTimer = Timer.set(() -> pollMatchStatus(id), 1.0);

	function closeSocket() {
		if (socket == null)
			return;

		if (socket.running)
			socket.close();
		socket = null;
	}

	function processText(text:String) {
		var msg:Dynamic = Json.parse(text);

		switch msg.type {
			case "game_state":
				receiveGameState(msg.state);
			case "planning_phase_start":
				ensurePendingMatch();
				BackendState.apply(pendingState(), msg);
				announceMatch();
			case "battle_events":
				if (msg.state != null)
					receiveGameState(msg.state);
				else
					BackendState.apply(pendingState(), msg);
			case "game_over":
				BackendState.apply(pendingState(), msg);
				closeGame();
			case "error":
				failed(Value.errorMessage(msg));
			default:
				if (msg.success == false)
					failed(Value.errorMessage(msg));
				else
					BackendState.apply(pendingState(), msg);
		}
		gameEvent(msg);
	}

	function ensurePendingMatch():Void {
		if (pendingMatch != null)
			return;

		pendingMatch = {
			opponent: {
				id: -1,
				nickname: "Opponent"
			},
			location: 0,
			state: null
		};
	}

	function pendingState():Null<BackendGameState>
		return pendingMatch?.state;
}
