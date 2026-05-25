package mutts.game;

class UnitCollection {
	public final units:Array<Unit> = [];
	public final maxUnits:Int;

	public function new(maxUnits:Int)
		this.maxUnits = maxUnits;

	public function canAccept():Bool
		return units.length < maxUnits;

	public function add(unit:Unit):Bool {
		if (units.length >= maxUnits)
			return false;
		units.push(unit);
		return true;
	}

	public function remove(unit:Unit):Bool
		return units.remove(unit);

	public function removeAt(index:Int):Null<Unit>
		return index < 0 || index >= units.length ? null : units.splice(index, 1)[0];

	public function contains(unit:Unit):Bool
		return units.indexOf(unit) >= 0;
}
