package mutts.ui.menus;

import s.ui.Alignment;
import s.ui.elements.Label;
import s.ui.elements.Interactive;

class AuthContent extends MenuContent {
	var login:Bool = true;
	var loginInput:Interactive;
	var passwordInput:Interactive;
	var changeModeButton:Interactive;
	var proceedButton:Interactive;

	public function new() {
		super("AUTHORIZATION");
		Game.client.onFailed(showError);
	}

	@:ui.markup
	override function markup() {
		loginInput = @markup(GameUI.input(GameUI.colors.cyan, "LOGIN")) {
			$height = 50;
			$layout.fillWidth = true;
		}

		passwordInput = @markup(GameUI.input(GameUI.colors.cyan, "PASSWORD")) {
			$height = 50;
			$layout.fillWidth = true;
		}

		applySavedAuth();

		@column {
			$height = 245;
			$layout.fillWidth = true;
			$alignment = AlignTop | AlignHCenter;

			changeModeButton = @markup(GameUI.button(GameUI.colors.neonWhite, "SIGN UP")) {
				$width = 260;
				$height = 85;
				cast($findChild("label"), Label).font.size = 26;
				$layout.alignment = AlignCenter;
				$onMouseClicked(_ -> toggleMode());
			}

			proceedButton = @markup(GameUI.button(GameUI.colors.cyan, "LOG IN")) {
				$width = 330;
				$height = 105;
				cast($findChild("label"), Label).font.size = 32;
				$layout.alignment = AlignCenter;
				$onMouseClicked(_ -> proceed());
			}
		}
	}

	function proceed() {
		final username = getInputText(loginInput);
		final password = getInputText(passwordInput);
		if (login)
			if (Game.client.requestAuth(username, password))
				Game.saveAuth(username, password);
		else
			if (Game.client.requestRegister(username, password))
				Game.saveAuth(username, password);
	}

	function getInputText(input:Interactive):String
		return cast(input.findChild("text"), Label).text;

	function setInputText(input:Interactive, value:String):Void {
		final text:Label = cast input.findChild("text");
		final prompt:Label = cast input.findChild("prompt");
		text.text = value;
		text.isVisible = value.length > 0;
		prompt.isVisible = value.length == 0;
	}

	function applySavedAuth():Void {
		final auth = Game.savedAuth;
		if (auth == null)
			return;
		setInputText(loginInput, auth.login);
		setInputText(passwordInput, auth.password);
	}

	function showError(message:String)
		GameUI.showPopup(GameUI.colors.red, message, false, () -> {});

	function toggleMode() {
		login = !login;
		cast(changeModeButton.findChild("label"), Label).text = login ? "SIGN UP" : "LOG IN";
		cast(proceedButton.findChild("label"), Label).text = login ? "LOG IN" : "SIGN UP";
	}

	override function destroy() {
		Game.client.offFailed(showError);
		super.destroy();
	}
}
