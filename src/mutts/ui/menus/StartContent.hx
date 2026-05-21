package mutts.ui.menus;

class StartContent extends MenuContent {
	public function new()
		super("START");

	@:ui.markup
	override function markup() {
		@label("Connecting to server...") {
			$anchors.fill($parent);
			$color = White;
			$font.size = 32;
			$alignment = AlignCenter;
		}
	}
}
