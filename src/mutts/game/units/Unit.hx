package mutts.game.units;

abstract class Unit {
	@:signal function spawned();

	@:signal function killed();

	public function new() {}
}
