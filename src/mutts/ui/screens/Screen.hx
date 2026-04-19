package mutts.ui.screens;

import s.assets.Image;
import s.ui.elements.ImageElement;

abstract class Screen extends ImageElement {
	public function new(source:Image) {
		super(source);
		fillMode = Cover;
	}
}
