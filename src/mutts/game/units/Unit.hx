package mutts.game.entities;

abstract class Unit {
	@:signal function spawned();

	@:signal function killed();

	public function new() {}
}
