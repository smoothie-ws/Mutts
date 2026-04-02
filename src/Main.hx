package;

import s.assets.Image;
import s.ui.Alignment;
import s.ui.elements.Text;
import s.App;
import s.Timer;
import s.math.SMath;
import s.Interpolation;
import s.animation.ColorAnimation;
import s.ui.WindowScene;

@:app.title("Mutts")
@:app.window(width = 750, height = 500)
@:app.framebuffer(verticalSync = false)
class Main extends s.App {
	public static function main() {
		mutts.ui.UI.markup(new WindowScene(window).root);
	}
}
