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
		loginInput = @markup(GameWidgets.input(GameUI.colors.cyan, "LOGIN")) {
			$height = 50;
			$layout.fillWidth = true;
		}

		passwordInput = @markup(GameWidgets.input(GameUI.colors.cyan, "PASSWORD")) {
			$height = 50;
			$layout.fillWidth = true;
		}

		@column {
			$height = 245;
			$layout.fillWidth = true;
			$alignment = AlignTop | AlignHCenter;

			changeModeButton = @markup(GameWidgets.button(GameUI.colors.neonWhite, "SIGN UP")) {
				$width = 260;
				$height = 85;
				cast($findChild("label"), Label).font.size = 26;
				$layout.alignment = AlignCenter;
				$onMouseClicked(_ -> toggleMode());
			}

			proceedButton = @markup(GameWidgets.button(GameUI.colors.cyan, "LOG IN")) {
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
			Game.client.requestAuth(username, password);
		else
			Game.client.requestRegister(username, password);
	}

	function getInputText(input:Interactive):String
		return cast(input.findChild("text"), Label).text;

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
