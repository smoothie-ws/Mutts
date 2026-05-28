package mutts.ui.menus;

class ConnectingContent extends MenuContent {
	public function new() {
		super("CONNECTING...");
		GameUI.loading(this, GameUI.colors.cyan);
	}
}
