package mutts.ui.menus;

import s.ui.Alignment;
import s.ui.elements.Label;
import s.ui.elements.Interactive;

class AuthContent extends MenuContent {
	var login:Bool = true;
	var changeModeButton:Interactive;
	var proceedButton:Interactive;

	public function new()
		super("AUTHORIZATION");

	@:ui.markup
	override function markup() {
		@row {
			$height = 100;
			$alignment = AlignCenter;
			$anchors.fillWidth($parent);

			@markup(GameWidgets.label(White, "LOGIN")) {
				$font.size = 24;
				$width = 200;
			}

			@rectangle {
				$height = 50;
				$width = 200;
			}
		}

		@row {
			$height = 100;
			$alignment = AlignCenter;
			$anchors.fillWidth($parent);

			@markup(GameWidgets.label(White, "PASSWORD")) {
				$font.size = 24;
				$width = 200;
			}

			@rectangle {
				$height = 50;
				$width = 200;
			}
		}

		@column {
			$height = 200;
			$layout.fillWidth = true;
			$alignment = AlignTop | AlignHCenter;

			changeModeButton = @markup(GameWidgets.button(GameUI.colors.yellow, "SIGN UP")) {
				$setScale(0.5);
				$layout.alignment = AlignCenter;
				$onMouseClicked(_ -> toggleMode());
			}

			proceedButton = @markup(GameWidgets.button(GameUI.colors.cyan, "LOG IN")) {
				$layout.alignment = AlignCenter;
				$onMouseClicked(b -> Game.client.requestAuth("login", "password"));
			}
		}
	}

	function toggleMode() {
		if (login) {
			login = false;
			cast(changeModeButton.findChild("label"), Label).text = "LOG IN";
			cast(proceedButton.findChild("label"), Label).text = "SIGN UP";
		} else {
			login = true;
			cast(changeModeButton.findChild("label"), Label).text = "SIGN UP";
			cast(proceedButton.findChild("label"), Label).text = "LOG IN";
		}
	}
}
