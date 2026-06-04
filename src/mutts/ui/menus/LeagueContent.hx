package mutts.ui.menus;

import mutts.GameState;
import s.ui.elements.Label;
import s.ui.elements.Interactive;
import s.ui.positioners.Column;
import mutts.net.Types;

class LeagueContent extends MenuContent {
	static inline var ROW_HEIGHT = 75.0;
	static inline var ROW_SPACING = 10.0;
	static inline var SCROLL_STEP = 45.0;

	var statsViewport:Interactive;
	var globalColumn:Column;
	var scrollOffset = 0.0;
	var contentHeight = 0.0;

	public function new() {
		super("LEAGUE");

		Game.client.onGlobalStats(setGlobalStats);
		Game.client.onUserStatistics(showUserStatistics);
		Game.client.requestLeague();
	}

	@:ui.markup
	override function markup() {
		statsViewport = @interactive {
			$clip = true;
			$propagateMouseEvents = true;
			$layout.fillWidth = true;
			$layout.fillHeight = true;
			$bottom.margin = 100;
			$onMouseScrolled(delta -> scrollBy(delta * SCROLL_STEP));

			globalColumn = @column {
				$spacing = ROW_SPACING;
				$anchors.fillWidth($parent);
			}
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
		Game.client.offUserStatistics(showUserStatistics);
	}

	public function setGlobalStats(stats:GlobalStats)
		markupGlobalStats(globalColumn, stats);

	function showUserStatistics(stats:BackendUser):Void
		GameUI.showStatisticsPopup(stats);

	function scrollBy(delta:Float) {
		if (statsViewport == null)
			return;

		final maxOffset = Math.max(0.0, contentHeight - statsViewport.height);
		scrollOffset = Math.max(0.0, Math.min(scrollOffset + delta, maxOffset));
		globalColumn.y = -scrollOffset;
	}

	function updateContentHeight(itemCount:Int) {
		contentHeight = itemCount <= 0 ? 0.0 : itemCount * ROW_HEIGHT + (itemCount - 1) * ROW_SPACING;
		globalColumn.height = contentHeight;
		scrollOffset = 0.0;
		scrollBy(0.0);
	}

	@:ui.markup
	function markupGlobalStats(stats:GlobalStats) {
		$children.destroy();
		updateContentHeight(stats.length);

		for (i in 0...stats.length) {
			var stat = stats[i];
			@interactive {
				$cursor = Pointer;
				$propagateMouseEvents = true;
				$height = ROW_HEIGHT;
				$anchors.fillWidth($parent);

				$onMouseClicked(_ -> Game.client.requestUserStatistics(stat));

				@markup(GameUI.panel(switch i {
					case 0: 0xFF2CE2BE;
					case 1: 0xFF1CBCC8;
					case 2: 0xFF1B8591;
					default: 0xFF0F4867;
				})) {
					$anchors.fill($parent);

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
}
