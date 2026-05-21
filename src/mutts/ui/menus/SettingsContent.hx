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
			soundsEffects: Game.settings.soundsEffects,
			soundsMusic: Game.settings.soundsMusic,
			interfaceOpacity: Game.settings.interfaceOpacity,
			interfacePadding: Game.settings.interfacePadding
		}

	@:ui.markup
	override function markup() {
		for (section in [
			{
				title: "Sounds",
				controls: [
					{
						title: "Effects",
						from: 0.,
						to: 100.,
						value: settings.soundsEffects,
						callback: Game.setSoundsEffects
					},
					{
						title: "Music",
						from: 0.,
						to: 100.,
						value: settings.soundsMusic,
						callback: Game.setSoundsMusic
					},
				]
			},
			{
				title: "Interface",
				controls: [
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
					},
				]
			},
		]) {
			@markup(GameWidgets.label(White, section.title)) {
				$layout.fillWidth = true;
				$font.size = 48;
				$alignment = AlignCenter;
				$layout.alignment = AlignCenter;
			}

			@layout.column {
				$layout.fillWidth = true;
				$layout.fillHeight = true;

				for (control in section.controls) {
					@markup(GameWidgets.slider(GameUI.colors.cyan, control.title, control.from, control.to, control.value, control.callback)) {
						$layout.fillWidth = true;
					}
				}
			}
		}

		@layout.row {
			$layout.fillWidth = true;
			$height = 100;

			@markup(GameWidgets.button(White, "Restore"))
			$onMouseClicked(_ -> {
				Game.restoreSettings();
				getSettings();
				children.destroy();
				markup(this);
			});

			@element $layout.fillWidth = true;

			@markup(GameWidgets.button(White, "Cancel"))
			$onMouseClicked(_ -> {
				Game.setSettings(settings);
				Game.state.back();
			});

			@markup(GameWidgets.button(White, "Save"))
			$onMouseClicked(_ -> {
				Game.saveSettings();
				Game.state.back();
			});
		}
	}
}
