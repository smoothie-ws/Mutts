package mutts.ui.playground;

import s.Color;
import s.ui.Element;
import s.ui.Alignment;
import s.ui.Direction;
import s.ui.elements.Label;
import s.ui.shapes.Rectangle;

class PlaygroundPlayerCard extends Element {
	final num:Int;
	final color:Color;
	final direction:Direction;
	final nickname:String;
	final maxHealth:Int;
	var health:Int;
	var healthLabel:Label;
	var healthTrack:Rectangle;
	var healthFill:Rectangle;

	public function new(nickname:String, health:Int, maxHealth:Int, num:Int, color:Color, direction:Direction) {
		this.num = num;
		this.color = color;
		this.direction = direction;
		this.nickname = nickname;
		this.maxHealth = maxHealth;
		this.health = health;
		super();
	}

	public function setHealth(value:Int):Void {
		health = value;
		if (healthLabel != null)
			healthLabel.text = health + "/" + maxHealth;
		updateHealthBar();
	}

	function updateHealthBar():Void {
		if (healthTrack == null || healthFill == null)
			return;
		final p = maxHealth <= 0 ? 0.0 : Math.max(0.0, Math.min(1.0, health / maxHealth));
		healthFill.width = Math.max(0.0, (healthTrack.width - 2) * p);
	}

	override function update() {
		updateHealthBar();
		super.update();
	}

	@:ui.markup
	override function markup() {
		$height = 100;
		$width = 500;

		@markup(GameWidgets.panel(color)) {
			$anchors.fill($parent);

			@layout.row(direction) {
				$anchors.fill($parent);
				$spacing = 10;
				$margins = 15;

				@icon(s.assets.Image.load("player_icon" + num)) {
					$color = color;
					$sampling = Trilinear;
					$width = $height = 75;
				}

				@column {
					$alignment = AlignVCenter | (direction.matches(LeftToRight) ? AlignLeft : AlignRight);
					$layout.fillWidth = true;
					$layout.fillHeight = true;

					@layout.row {
						$layout.fillWidth = true;
						$height = 45;

						if (direction.matches(LeftToRight)) {
							@markup(GameWidgets.label(White, nickname)) {
								$font.size = 20;
								$alignment = AlignLeft | AlignVCenter;
								$layout.fillWidth = true;
							}

							healthLabel = @markup(GameWidgets.label(GameUI.colors.green, health + "/" + maxHealth)) {
								$width = 100;
								$font.size = 18;
								$alignment = AlignRight | AlignVCenter;
							}
						} else {
							healthLabel = @markup(GameWidgets.label(GameUI.colors.green, health + "/" + maxHealth)) {
								$width = 100;
								$font.size = 18;
								$alignment = AlignLeft | AlignVCenter;
							}

							@markup(GameWidgets.label(White, nickname)) {
								$font.size = 20;
								$alignment = AlignRight | AlignVCenter;
								$layout.fillWidth = true;
							}
						}
					}

					healthTrack = @rectangle {
						$height = 10;
						$radius = 20;
						$softness = 10;
						$color = rgba(color.r, color.g, color.b, 0.25);
						$layout.fillWidth = true;

						healthFill = @rectangle {
							$anchors.left = $parent.left;
							$anchors.top = $parent.top;
							$anchors.bottom = $parent.bottom;
							$margins = 1;
							$radius = 20;
							$softness = 3;
							$color = color;
						}
					}
				}
			}
		}
	}
}
