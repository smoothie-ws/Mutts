package mutts.game.units;

abstract class Unit implements s.shortcut.Shortcut {
	@:signal public function spawned();

	@:signal public function killed();

	public function new() {}
}
