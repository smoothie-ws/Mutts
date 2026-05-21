package mutts.ui;

import s.assets.Image;
import s.ui.Element;
import mutts.ui.Menu;

abstract class Screen extends Element {
	public var hud:Element;
	public final menu:Menu;

	public function new() {
		super();
		addChild(menu = new Menu());
		menu.anchors.fill(this);
		menu.opacity = Game.settings.interfaceOpacity;
		menu.padding = Game.settings.interfacePadding;
	}

	public function showMenu(show:Bool) {
		menu.isVisible = show;
		if (hud != null)
			hud.isVisible = !menu.isVisible;
	}
}
