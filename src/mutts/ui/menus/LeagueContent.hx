package mutts.ui.menus;

import mutts.GameState;
import s.ui.elements.Label;
import s.ui.positioners.Column;
import mutts.net.Types;

class LeagueContent extends MenuContent {
	var globalColumn:Column;

	public function new() {
		super("LEAGUE");

		Game.client.onGlobalStats(setGlobalStats);
		Game.client.requestLeague();
	}

	@:ui.markup
	override function markup() {
		globalColumn = @column {
			$spacing = 10;
			$layout.fillWidth = true;
			$layout.fillHeight = true;
			$bottom.margin = 100;
		}
		@markup(GameUI.button(GameUI.colors.green, "RETURN")) {
			$width = 200;
			$height = 85;
			$layout.alignment = AlignCenter;
			cast($findChild("label"), Label).font.size = 24;
			$onMouseClicked(_->Game.state.goto(GameState.main));
		}
	}

	override function destroy() {
		super.destroy();
		Game.client.offGlobalStats(setGlobalStats);
	}

	public function setGlobalStats(stats:GlobalStats)
		markupGlobalStats(globalColumn, stats);

	@:ui.markup
	function markupGlobalStats(stats:GlobalStats) {
		$children.destroy();

		for (i in 0...stats.length) {
			var stat = stats[i];
			@markup(GameUI.panel(switch i {
				case 0: 0xFF2CE2BE;
				case 1: 0xFF1CBCC8;
				case 2: 0xFF1B8591;
				default: 0xFF0F4867;
			})) {
				$height = 75;
				$anchors.fillWidth($parent);

				@layout.row {
					$anchors.fill($parent);

					for (s in ["#" + Std.string(i + 1), stat.nickname, Std.string(stat.mmr)]) {
						@markup(GameUI.label(White, s)) {
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
