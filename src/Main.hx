package;

import s.ui.WindowScene;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
@:app.framebuffer(verticalSync = false)
class Main extends s.App {
	public static function main() {
		mutts.ui.UI.markup(new WindowScene(window).root);
	}
}
