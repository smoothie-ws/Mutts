package mutts.ui.playground;

import s2d.Element;

class Playground extends Element {
	@ui.markup
	function build() {
		@Element(width = 2) {
			@Element(width = parent.width) {}
		}
	}
}
