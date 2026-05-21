package mutts.game;

class UnitCollection {
	public final units:Array<Unit> = [];
	public final maxUnits:Int;

	public function new(maxUnits:Int)
		this.maxUnits = maxUnits;

	public function canAccept(unit:Unit):Bool
		return canMerge(unit) || units.length < maxUnits;

	public function add(unit:Unit):Bool {
		if (tryMerge(unit))
			return true;
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

	public function canMerge(unit:Unit):Bool
		return findMergeTarget(unit) != null;

	public function tryMerge(unit:Unit):Bool {
		final target = findMergeTarget(unit);
		if (target == null)
			return false;
		target.levelUp();
		mergeCascade(target);
		return true;
	}

	function mergeCascade(unit:Unit):Void {
		while (true) {
			final target = findMergeTarget(unit, unit);
			if (target == null)
				return;
			units.remove(target);
			unit.levelUp();
		}
	}

	function findMergeTarget(unit:Unit, ?except:Unit):Null<Unit> {
		for (target in units)
			if (target != except && target.canMergeWith(unit))
				return target;
		return null;
	}
}
