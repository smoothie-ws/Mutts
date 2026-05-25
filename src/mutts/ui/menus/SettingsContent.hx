package mutts.ui.menus;

import Game.GameSettings;

class SettingsContent extends MenuContent {
	var settings:GameSettings;

	public function new() {
		getSettings();
		super("SETTINGS");
	}

	function getSettings()
		settings = {
			interfaceOpacity: Game.settings.interfaceOpacity,
			interfacePadding: Game.settings.interfacePadding
		}

	@:ui.markup
	override function markup() {
		spacing = 25;

		@markup(GameWidgets.label(White, "Interface")) {
			$layout.fillWidth = true;
			$font.size = 48;
			$alignment = AlignBottomCenter;
			$layout.alignment = AlignBottomCenter;
		}

		@layout.column {
			$layout.fillWidth = true;
			$layout.fillHeight = true;

			for (control in [
				{
					title: "Opacity",
					from: 0.5,
					to: 1.0,
					value: settings.interfaceOpacity,
					callback: Game.setInterfaceOpacity
				},
				{
					title: "Padding",
					from: 0.0,
					to: 50,
					value: settings.interfacePadding,
					callback: Game.setInterfacePadding
				}
			]) {
				@markup(GameWidgets.slider(GameUI.colors.cyan, control.title, control.from, control.to, control.value, control.callback)) {
					$layout.fillWidth = true;
				}
			}
		}

		@layout.row {
			$layout.fillWidth = true;
			$layout.fillHeight = true;

			@markup(GameWidgets.button(GameUI.colors.cyan, "Restore")) {
				$width = 260;
				$height = 85;
				$layout.minimumWidth = 260;
				$layout.maximumWidth = 260;
				$layout.minimumHeight = 85;
				$layout.maximumHeight = 85;
				cast($findChild("label"), s.ui.elements.Label).font.size = 26;
				$layout.alignment = AlignBottomCenter;
				$onMouseClicked(_ -> {
					Game.restoreSettings();
					getSettings();
					children.destroy();
					markup(this);
				});
			}

			@element $layout.fillWidth = true;

			@markup(GameWidgets.button(GameUI.colors.red, "Cancel")) {
				$width = 260;
				$height = 85;
				$layout.minimumWidth = 260;
				$layout.maximumWidth = 260;
				$layout.minimumHeight = 85;
				$layout.maximumHeight = 85;
				cast($findChild("label"), s.ui.elements.Label).font.size = 26;
				$layout.alignment = AlignBottomCenter;
				$onMouseClicked(_ -> {
					Game.setSettings(settings);
					Game.state.back();
				});
			}

			@markup(GameWidgets.button(GameUI.colors.green, "Save")) {
				$width = 260;
				$height = 85;
				$layout.minimumWidth = 260;
				$layout.maximumWidth = 260;
				$layout.minimumHeight = 85;
				$layout.maximumHeight = 85;
				cast($findChild("label"), s.ui.elements.Label).font.size = 26;
				$layout.alignment = AlignBottomCenter;
				$onMouseClicked(_ -> {
					Game.saveSettings();
					Game.state.back();
				});
			}
		}
	}
}
