package mutts.ui.menus;

import s.ui.Alignment;
import s.ui.elements.Label;
import s.ui.positioners.Column;
import mutts.net.Types;

class LeagueContent extends MenuContent {
	var ratingLabel:Label;
	var winsLabel:Label;
	var lossesLabel:Label;
	var winrateLabel:Label;
	var totalLabel:Label;

	var globalColumn:Column;

	public function new() {
		super("LEAGUE");

		Game.client.onPlayerStats(setStats);
		Game.client.onGlobalStats(setGlobalStats);
		Game.client.requestLeague(Game.player.id);
	}

	@:ui.markup
	override function markup() {
		@layout.column {
			$layout.fillWidth = true;
			$layout.fillHeight = true;

			@element {
				$margins = 25;
				$layout.fillWidth = true;
				$layout.fillHeight = true;

				@markup(GameWidgets.loading(GameUI.colors.cyan)) {
					$anchors.vCenter = $parent.vCenter;
					Game.client.onGlobalStats(_ -> $destroy());
				}

				globalColumn = @column {
					$spacing = 10;
					$anchors.fill($parent);
				}
			}

			@markup(GameWidgets.panel(GameUI.colors.cyan)) {
				$height = 100;
				$layout.fillWidth = true;

				@layout.row {
					$anchors.fill($parent);

					@markup(GameWidgets.label(White, "NICKNAME")) {
						$layout.fillWidth = true;
						$layout.horizontalStretchFactor = 2 / 3;
					}

					@layout.column {
						$spacing = 0;
						$layout.fillWidth = true;
						$layout.fillHeight = true;

						@layout.row {
							$opacity = 0.5;
							$layout.alignment = AlignBottom;
							$layout.fillWidth = true;
							$layout.fillHeight = true;
							$layout.verticalStretchFactor = 2 / 3;

							for (title in ["MMR", "W", "L", "WR", "T"]) {
								@markup(GameWidgets.label(White, title)) {
									$alignment = AlignHCenter | AlignBottom;
									$layout.alignment = AlignBottom;
									$font.size = 18;
									$layout.fillWidth = true;
								}
							}
						}

						@layout.row {
							$layout.alignment = AlignTop;
							$layout.fillWidth = true;
							$layout.fillHeight = true;

							ratingLabel = @markup(GameWidgets.label(White, "MMR")) {
								$alignment = AlignHCenter | AlignTop;
								$layout.alignment = AlignTop;
								$layout.fillWidth = true;
							}

							winsLabel = @markup(GameWidgets.label(White, "WINS")) {
								$alignment = AlignHCenter | AlignTop;
								$layout.alignment = AlignTop;
								$layout.fillWidth = true;
							}

							lossesLabel = @markup(GameWidgets.label(White, "LOSSES")) {
								$alignment = AlignHCenter | AlignTop;
								$layout.alignment = AlignTop;
								$layout.fillWidth = true;
							}

							winrateLabel = @markup(GameWidgets.label(White, "WINRATE")) {
								$alignment = AlignHCenter | AlignTop;
								$layout.alignment = AlignTop;
								$layout.fillWidth = true;
							}

							totalLabel = @markup(GameWidgets.label(White, "TOTAL")) {
								$alignment = AlignHCenter | AlignTop;
								$layout.alignment = AlignTop;
								$layout.fillWidth = true;
							}
						}
					}
				}
			}
		}
	}

	public function setStats(stats:PlayerStats) {
		ratingLabel.text = Std.string(stats.mmr);
		winsLabel.text = Std.string(stats.win_count);
		lossesLabel.text = Std.string(stats.lose_count);

		var total = stats.win_count + stats.lose_count;
		var winrate = Math.round(total > 0 ? stats.win_count * 100 / total : 0) / 100;
		winrateLabel.text = Std.string(winrate);
		totalLabel.text = Std.string(total);
	}

	override function destroy() {
		super.destroy();
		Game.client.offPlayerStats(setStats);
		Game.client.offGlobalStats(setGlobalStats);
	}

	public function setGlobalStats(stats:GlobalStats)
		markupGlobalStats(globalColumn, stats);

	@:ui.markup
	function markupGlobalStats(stats:GlobalStats) {
		$children.destroy();

		for (i in 0...stats.length) {
			var stat = stats[i];
			@markup(GameWidgets.panel(switch i {
				case 0: 0xFFFFC13B;
				case 1: 0xFFE9FBFF;
				case 2: 0xFFC9630F;
				default: 0xFF68387E;
			})) {
				$height = 75;
				$anchors.fillWidth($parent);

				@interactive {
					$cursor = Pointer;
					$anchors.fill($parent);
					$onMouseClicked(b->Game.client.requestLeague(stat.id));
				}

				@layout.row {
					$anchors.fill($parent);

					for (s in ["#" + Std.string(i + 1), stat.nickname, Std.string(stat.mmr)]) {
						@markup(GameWidgets.label(White, s)) {
							$font.size = 18;
							$layout.fillWidth = true;
							$layout.fillHeight = true;
						}
					}
				}
			}
		}
	}
}
