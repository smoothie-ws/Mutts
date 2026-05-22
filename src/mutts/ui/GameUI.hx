package mutts.ui;

import s.Animation;
import haxe.Constraints;
import s.app.Window;
import s.ui.Scene;
import mutts.ui.Screen;
import mutts.ui.screens.MainScreen;

class GameUI {
	static var scene:Scene;

	public static final colors = {
		cyan: 0xff2ae4f1,
		red: 0xffe4236a,
		green: 0xff2af1bf,
		yellow: 0xfffcf376
	}

	public static var screen(default, null):Screen;

	public static function init(window:Window) {
		scene = new Scene(window);
		scene.color = Black;
		setScreen(MainScreen);
	}

	public static function showPopup(color:s.Color, text:String, declinable:Bool, accepted:Void->Void, ?declined:Void->Void)
		GameWidgets.popup(scene, color, text, declinable, accepted, declined);

	@:generic
	public static function setScreen<T:Constructible<Void->Void> & Screen>(screen:Class<T>, ?callback:Void->Void) {
		function set() {
			GameUI.screen = new T();
			GameUI.screen.parent = scene;
			GameUI.screen.anchors.fill(scene);
			if (callback != null)
				callback();
		}

		if (GameUI.screen != null)
			Animation.mix(1.0, 0.0, 0.25, GameUI.screen.setOpacity).onCompleted(() -> {
				GameUI.screen.destroy();
				set();
				Animation.mix(0.0, 1.0, 0.25, GameUI.screen.setOpacity).start();
			}).start();
		else
			set();
	}

	@:generic
	public static function setScreenMenuContent<T:Constructible<Void->Void> & MenuContent>(content:Class<T>)
		GameUI.screen.menu.setContent(new T());
}
