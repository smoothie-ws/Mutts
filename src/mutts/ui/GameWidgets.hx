package mutts.ui;

import s.Color;
import s.Easing;
import s.Animation;
import s.ui.Shapes;
import s.ui.Markup;

class GameWidgets implements Markup {
	@:ui.markup
	public static function loading(color:s.Color):Rectangle {
		@markup(progress(color)) {
			function startLoading() {
				if ($parent.width <= 0)
					return;

				s.App.offUpdate(startLoading);

				new Animation(2, t -> {
					var x = Math.pow(t - 0.5, 2) * 4;
					$opacity = 1 - x;
					$width = ($parent.width - $parent.width * x);
					if (t >= 0.5)
						$x = $parent.width - $width;
				}).onCompleted(() -> $x = 0).ease(Easing.InOutQuart).loop().start();
			}

			s.App.onUpdate(startLoading);
		}
	}

	@:ui.markup
	public static function progress(color:s.Color):Rectangle {
		@rectangle {
			$height = 5;
			$radius = 50;
			$softness = 15;
			$color = rgba(color.r, color.g, color.b, 0.5);

			@rectangle {
				$anchors.fill($parent);
				$margins = 1;
				$color = color;
				$softness = 2.5;
			}
		}
	}

	@:ui.markup
	public static function popup(color:s.Color, text:String, declinable:Bool, accepted:Void->Void, ?declined:Void->Void) {
		var p = @interactive {
			$anchors.fill($parent);

			Animation.mix(0.0, 1.0, 0.15, x -> $opacity = x).start();

			@rectangle {
				$color = 0xFF180D05;
				$radius = 0;
				$height = 350;
				$anchors.fillWidth($parent);
				$anchors.centerIn($parent);

				@markup(panel(GameUI.colors.cyan)) {
					$left.margin = -50;
					$right.margin = -50;
					$anchors.fill($parent);

					@layout.column {
						$width = 550;
						$anchors.fillHeight($parent);
						$anchors.hCenter = $parent.hCenter;

						@markup(label(White, text)) {
							$font.size = 32;
							$layout.fillWidth = true;
							$layout.fillHeight = true;
						}

						@layout.row {
							$layout.fillWidth = true;
							$layout.fillHeight = true;

							if (declinable) {
								@markup(button(GameUI.colors.red, "NO")) {
									$layout.alignment = AlignCenter;
									$onMouseClicked(_ -> Animation.mix(1.0, 0.0, 0.15, x -> p.opacity = x).onCompleted(() -> {
										p.destroy();
										if (declined != null)
											declined();
									}).start());
								}

								@markup(button(GameUI.colors.green, "YES")) {
									$layout.alignment = AlignCenter;
									$onMouseClicked(_ -> {
										p.destroy();
										accepted();
									});
								}
							} else {
								@markup(button(GameUI.colors.green, "OK")) {
									$layout.alignment = AlignCenter;
									$onMouseClicked(_ -> {
										p.destroy();
										accepted();
									});
								}
							}
						}
					}
				}
			}
		}
	}

	@:ui.markup
	public static function label(color:s.Color, ?text:String):s.ui.elements.Label {
		@label(text) {
			$color = color;
			$width = 150;
			$height = 50;
			$shearX = -0.2;
			$elideMode = ElideRight;
			$alignment = AlignCenter;
			$font.family = "Michroma";
			$font.size = 32;
			$font.bold = true;
			$font.weight = 1000;
		}
	}

	@:ui.markup
	public static function panel(color:s.Color, radius:Int = 0):s.ui.shapes.Rectangle {
		@rectangle(radius) {
			$shearX = -0.2;
			$color = Black;
			$color.a = 0.15;
			$border.color = color;
			$border.width = 2;
			$border.softness = 2;

			final n = 2;
			for (i in 0...n) {
				@rectangle(radius) {
					$color = "transparent";
					$border.color = color;
					$border.color.s = (n - i) / n;
					$border.color.a = 0.75;
					$border.width = 2;
					$border.softness = 5 * (n - i);
					$anchors.fill($parent);
				}
			}
		}
	}

	@:ui.markup
	public static function button(color:s.Color, text:String):s.ui.elements.Interactive {
		var radius = 0;

		@interactive {
			$width = 225;
			$height = 75;
			$cursor = Pointer;
			$shearX = -0.2;

			var hovered = new s.shortcut.signals.Signal<Bool->Void>();
			hovered.connect(b -> s.Animation.mix($scaleX, b ? 1.1 : 1, x -> $setScale(x)).ease(s.Easing.OutElastic).start());

			$onMouseEntered(() -> hovered(true));
			$onMouseExited(() -> hovered(false));

			@rectangle(radius) {
				$anchors.fill($parent);
				$color = Black;
				$color.a = 0.35;
				$border.color = color;
				$border.width = 2;
				$border.softness = 2;

				final n = 2;
				for (i in 0...n) {
					@rectangle(radius) {
						$color = "transparent";
						$border.color = color;
						$border.color.s = (n - i) / n;
						$border.color.a = 0.75;
						$border.width = 2;
						$border.softness = 5 * (n - i);
						$anchors.fill($parent);

						hovered.connect(b -> s.Animation.mix($border.width, b ? 5.0 : 2.0, 0.5, x -> $border.width = x).ease(s.Easing.OutElastic).start());
					}
				}

				@markup(label(color, text)) "label" = {
					$anchors.fill($parent);
					hovered.connect(b -> s.Animation.mixColor($color, b ? s.Color.White : color, 0.25, x -> $color = x).ease(s.Easing.OutCirc).start());
				}
			}
		}
	}

	@:ui.markup
	public static function slider(color:s.Color, text:String, from:Float, to:Float, value:Float, callback:Float->Void):s.ui.layouts.RowLayout {
		@layout.row {
			$height = 75;

			@markup(label(White, text)) {}

			@markup(label(White, Std.string(from))) $width = 75;

			@slider {
				$from = from;
				$to = to;
				$value = value;
				$onValueChanged(callback);
				$cursor = Pointer;

				$layout.fillWidth = true;
				$layout.fillHeight = true;
				$layout.verticalStretchFactor = 0.5;

				$backgroundInset = 10;
				$background.color = Black;
				$background.radius = 50;

				$contentPadding = 10;
				$content.color = color;
				$content.color.a = 0.35;
				$content.radius = 50;
				$content.softness = 5;

				$onMouseEntered(() -> s.Animation.mix(10, 7.5, 0.5, x -> $contentPadding = x).ease(s.Easing.OutElastic).start());
				$onMouseExited(() -> s.Animation.mix(7.5, 10, 0.5, x -> $contentPadding = x).ease(s.Easing.OutElastic).start());

				$content.addChild({
					var r = new Rectangle();
					r.anchors.fill($content);
					r.margins = 5;
					r.color = color;
					r.softness = 2.5;
					$onMousePressed(b -> s.Animation.mixColor(color, White, 0.15, x -> r.color = x).start());
					$onMouseReleased(b -> s.Animation.mixColor(White, color, 0.15, x -> r.color = x).start());
					r;
				});
			}

			@markup(label(White, Std.string(to))) $width = 75;
		}
	}

	@:ui.markup
	public static function input(color:s.Color, prompt:String):s.ui.elements.Interactive {
		@interactive {
			$cursor = Pointer;
			$opacity = 0.5;

			var promptLabel = @markup(label(color, prompt)) {
				$opacity = 0.5;
				$anchors.fill($parent);
				$shearX = 0.0;
				$font.letterSpacing = 15;
			}

			var textLabel = @markup(label(color, "")) "text" = {
				$anchors.fill($parent);
				$shearX = 0.0;
				$font.letterSpacing = 15;

				@rectangle "underline" = {
					$color = color;
					$height = 2;
					$isVisible = false;
					$anchors.fillWidth($parent);
					$anchors.top = $parent.bottom;
				}
			}

			var underline = cast(textLabel.findChild("underline"), Rectangle);

			$onUpdated(() -> {
				if (@:privateAccess $isFocusedDirty) {
					underline.isVisible = $isFocused;
					$opacity = $isFocused ? 1.0 : 0.5;
				}
			});

			function updateText()
				textLabel.isVisible = !(promptLabel.isVisible = textLabel.text.length == 0);

			$onKeyboardTyped(c -> {
				textLabel.text += c;
				updateText();
			});
			$onKeyboardKeyPressed(Backspace, () -> {
				textLabel.text = textLabel.text.substr(0, textLabel.text.length - 1);
				updateText();
			});
		}
	}
}
