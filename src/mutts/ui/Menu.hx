package mutts.ui;

import s.Animation;
import s.Color;
import s.ui.Element;
import s.ui.elements.Label;
import s.ui.layouts.RowLayout;
import s.ui.layouts.ColumnLayout;

class Menu extends RowLayout {
	var titleLabel:Label;
	var contentElement:Element;

	public function setContent(content:MenuContent) {
		final offset = 250;
		Animation.mix(0.0, offset, 0.1, x -> {
			contentElement.opacity = titleLabel.opacity = (offset - x) / offset;
			titleLabel.translationX = x;
		}).onCompleted(() -> {
			contentElement.children.destroy();
			contentElement.addChild(content);
			content.anchors.fill(contentElement);
			titleLabel.text = content.title;
			Animation.mix(-offset, 0.0, 0.1, x -> {
				contentElement.opacity = titleLabel.opacity = (offset + x) / offset;
				titleLabel.translationX = x;
			}).start();
		}).start();
	}

	@:ui.markup override function markup():Element {
		@rectangle {
			$softness = 150;
			$color = rgba(0, 0, 0, 0.5);
			$bottom.margin = -150;
			$layout.alignment = AlignCenter;
			$layout.fillWidth = true;
			$layout.fillHeight = true;
			$layout.horizontalStretchFactor = 0.5;

			@layout.column {
				$margins = 150;
				$anchors.fill($parent);

				var logo = @image(s.assets.Image.load("logo")) {
					$fillMode = Contain;
					$layout.fillWidth = true;
					$layout.fillHeight = true;
					$layout.minimumHeight = 150;
					$layout.maximumHeight = 250;
				}

				@rectangle {
					$layout.fillWidth = true;
					$opacity = 0.5;
					$height = 1;
				}

				titleLabel = @markup(GameUI.label(White)) {
					$font.size = 64;
					$layout.fillWidth = true;
					$height = 50;
				}

				@rectangle {
					$layout.fillWidth = true;
					$opacity = 0.5;
					$height = 1;
				}

				contentElement = @element {
					$layout.fillWidth = true;
					$layout.fillHeight = true;
				}
			}
		}
	}
}
