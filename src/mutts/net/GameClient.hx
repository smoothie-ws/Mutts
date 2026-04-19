package mutts.net;

import haxe.Json;
import s.net.ws.WebSocketClient;
import mutts.game.GameState;

final HOST = "localhost:8080";

typedef Message = {
	type:String,
	data:Dynamic
}

@:allow(Game)
class GameClient extends WebSocketClient {
	function new() {
		super(HOST, false);
	}

	public function requestAuth(login:String, password:String)
		request("auth", {login: login, password: password});

	public function requestStats(login:String)
		request("stats", {login: login});

	function request(type:String, data:{})
		send(Json.stringify({type: type, data: Json.stringify(data)}));

	@:slot(text)
	function processText(text:String) {
		var msg:Message = Json.parse(text);
		switch msg.type {
			case "auth":
				Game.state.goto(GameState.main);
			case "stats":
				Game.state.goto(GameState.main);
		}
	}
}
