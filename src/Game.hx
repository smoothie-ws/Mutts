package;

import haxe.Json;
import kha.StorageFile;
import s.App;
import s.app.Window;
import mutts.GameState;
import mutts.ui.GameUI;
import mutts.net.Types;
import mutts.net.GameClient;
import mutts.game.Match;

typedef GameSettings = {interfaceOpacity:Float, interfacePadding:Float}

@:app.title("Mutts")
@:app.window(width = 1920, height = 1080)
@:app.framebuffer(verticalSync = false)
class Game extends App {
	static var settingsFile:StorageFile;

	public static var state:GameState;
	public static var client:GameClient;
	public static var player:PlayerProfile;

	public static var settings:GameSettings;

	public static var match:Match;

	public static function main() {
		//  settings
		settingsFile = kha.Storage.namedFile("settings");
		var s = settingsFile.readString();
		settings = s == null ? getDefaultSettings() : Json.parse(s);

		// init
		state = new GameState();
		client = new GameClient();
		client.requestConfigs();
		GameUI.init(window);
		setSettings(settings);

		// auth();
		state.goto(GameState.connecting);
	}

	public static function setInterfaceOpacity(value:Float) {
		settings.interfaceOpacity = value;
		GameUI.screen.hud?.setOpacity(value);
		GameUI.screen.menu?.setOpacity(value);
	}

	public static function setInterfacePadding(value:Float) {
		settings.interfacePadding = value;
		GameUI.screen.hud?.setPadding(value);
		GameUI.screen.menu?.setPadding(value);
	}

	public static function setSettings(value:GameSettings) {
		setInterfaceOpacity(value.interfaceOpacity);
		setInterfacePadding(value.interfacePadding);
	}

	public static function restoreSettings()
		setSettings(getDefaultSettings());

	public static function getDefaultSettings():GameSettings
		return {
			interfaceOpacity: 1.0,
			interfacePadding: 0
		}

	public static function saveSettings()
		settingsFile.writeString(Json.stringify(settings));
}
