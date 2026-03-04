package mutts.ui.playground;

@:ui.short(playground)
class Playground extends s2d.Element {
	@:ui.markup
	function build() {
		@element(width = 2, {
			height: 10,
			onHeightChanged: v -> trace(parent.height)
		}) {}
		@ground(width = parent.width) {
			for (i in 0...10)
				@image(height = 2) {}
		}
	}
}

@:ui.shortcut(ground)
class Ground extends s2d.Element {}
