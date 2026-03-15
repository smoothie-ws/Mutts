package mutts.game.units;

abstract class Unit {
	@:signal public function spawned();

	@:signal public function killed();

	public function new() {}
}
