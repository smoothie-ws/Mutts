package mutts.ui.menus;

class ConnectingContent extends MenuContent {
	public function new() {
		super("CONNECTING...");
		GameWidgets.loading(this, GameUI.colors.cyan);
	}
}
