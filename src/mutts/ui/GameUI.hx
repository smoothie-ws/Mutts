package mutts.ui;

import haxe.Constraints;
import s.Color;
import s.Easing;
import s.Animation;
import s.ui.Scene;
import s.ui.Shapes;
import s.ui.Markup;
import s.app.Window;
import mutts.ui.Screen;
import mutts.ui.screens.MainScreen;

class GameUI implements Markup {
	static var scene:Scene;

	public static final colors = {
		cyan: 0xff2ae4f1,
		red: 0xffe4236a,
		green: 0xff2af1bf,
		yellow: 0xfffcf376,
		neonWhite: 0xffe8feff
	}

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
				$color = 0xFF180508;
				$radius = 0;
				$height = 350;
				$anchors.fillWidth($parent);
				$anchors.centerIn($parent);

				@markup(panel(GameUI.colors.cyan)) {
					$left.margin = -50;
					$right.margin = -50;
					$anchors.fill($parent);

					@layout.column {
						$width = 900;
						$height = 260;
						$anchors.centerIn($parent);

						@label(text) {
							$color = White;
							$width = 900;
							$height = 140;
							$elideMode = ElideRight;
							$alignment = AlignCenter;
							$font.family = "Michroma";
							$font.size = 72;
							$font.bold = true;
							$font.weight = 1000;
							$layout.fillWidth = true;
							$layout.alignment = AlignCenter;
						}

						@layout.row {
							$height = 120;
							$layout.fillWidth = true;
							$layout.alignment = AlignCenter;

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

			var hovered = new s.shortcut.signals.Signal<Bool->Void>();

			$onMouseEntered(() -> hovered(true));
			$onMouseExited(() -> hovered(false));

			@image(s.assets.Image.load("frame")) {
				$anchors.fill($parent);
				$opacity = 0.75;
				$color = color;
				$sampling = Trilinear;
				$fillMode = Cover;

				hovered.connect(b -> s.Animation.mix($opacity, b ? 1.0 : 0.75, 0.1, x -> $opacity = x).start());

				@image(s.assets.Image.load("frame_corners")) {
					$anchors.fill($parent);
					$sampling = Trilinear;
					$fillMode = Cover;
					$setScale(1.1);
					$opacity = 0.0;
					$color = color;

					hovered.connect(b -> s.Animation.mix($scaleX, b ? 1 : 1.1, 0.1, x -> $setScale(x)).start());
					hovered.connect(b -> s.Animation.mix($opacity, b ? 1.0 : 0.0, 0.1, x -> $opacity = x).start());
				}

				@markup(label(color, text)) "label" = {
					$anchors.fill($parent);
					hovered.connect(b -> s.Animation.mixColor($color, b ? s.Color.White : color, 0.25, x -> $color = x).ease(s.Easing.OutCirc).start());
				}
			}
		}
	}

	@:ui.markup
	public static function unitSlot(color:s.Color, text:String):s.ui.elements.Interactive {
		@interactive {
			$width = 150;
			$height = 150;
			$cursor = Pointer;
			$layout.alignment = AlignCenter;
			$layout.minimumWidth = 125;
			$layout.maximumWidth = 170;
			$layout.minimumHeight = 125;
			$layout.maximumHeight = 170;

			var hovered = new s.shortcut.signals.Signal<Bool->Void>();
			hovered.connect(b -> s.Animation.mix($scaleX, b ? 1.05 : 1, 0.1, x -> $setScale(x)).start());

			@image(s.assets.Image.load("frame_square")) {
				$anchors.fill($parent);
				$opacity = 0.75;
				$color = color;
				$margins = -15;
				$sampling = Trilinear;
				$fillMode = Cover;

				hovered.connect(b -> s.Animation.mix($opacity, b ? 1.0 : 0.75, 0.1, x -> $opacity = x).start());

				@image(s.assets.Image.load("frame_square_corners")) {
					$anchors.fill($parent);
					$sampling = Trilinear;
					$fillMode = Cover;
					$setScale(1.1);
					$opacity = 0.0;
					$color = color;

					hovered.connect(b -> s.Animation.mix($scaleX, b ? 1 : 1.1, 0.1, x -> $setScale(x)).start());
					hovered.connect(b -> s.Animation.mix($opacity, b ? 1.0 : 0.0, 0.1, x -> $opacity = x).start());
				}
			}

			@markup(label(color, text)) "label" = {
				$height = 38;
				$font.size = 24;
				$anchors.left = $parent.left;
				$anchors.right = $parent.right;
				$anchors.bottom = $parent.bottom;
				$bottom.margin = 6;
				hovered.connect(b -> s.Animation.mixColor($color, b ? s.Color.White : color, 0.25, x -> $color = x).ease(s.Easing.OutCirc).start());
			}

			$onMouseEntered(() -> hovered(true));
			$onMouseExited(() -> hovered(false));
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

			var promptLabel = @markup(label(color, prompt)) "prompt" = {
				$opacity = 0.5;
				$anchors.fill($parent);
				$font.letterSpacing = 15;
			}

			var textLabel = @markup(label(color, "")) "text" = {
				$anchors.fill($parent);
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

	public static var screen(default, null):Screen;

	public static function init(window:Window) {
		scene = new Scene(window);
		scene.color = Black;
		setScreen(MainScreen);
	}

	public static function showPopup(color:s.Color, text:String, declinable:Bool, accepted:Void->Void, ?declined:Void->Void)
		GameUI.popup(scene, color, text, declinable, accepted, declined);

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
