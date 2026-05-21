package mutts.game;

class MatchPlayground extends UnitCollection {
	public static inline final rows:Int = 8;
	public static inline final columns:Int = 4;
	public static inline final maxGroundUnits:Int = 6;

	public function new()
		super(maxGroundUnits);

	override public function canAccept(unit:Unit):Bool
		return canMerge(unit) || units.length < maxUnits && randomFreeCell() != null;

	override public function add(unit:Unit):Bool {
		if (tryMerge(unit))
			return true;
		final cell = randomFreeCell();
		if (units.length >= maxUnits || cell == null)
			return false;
		unit.row = cell.row;
		unit.column = cell.column;
		units.push(unit);
		return true;
	}

	public function move(unit:Unit, row:Int, column:Int):Bool {
		final occupant = getAt(row, column);
		if (!contains(unit) || !isValidCell(row, column) || occupant != null && occupant != unit)
			return false;
		unit.row = row;
		unit.column = column;
		return true;
	}

	public function getAt(row:Int, column:Int):Null<Unit> {
		for (unit in units)
			if (unit.row == row && unit.column == column)
				return unit;
		return null;
	}

	function randomFreeCell():Null<{row:Int, column:Int}> {
		final cells = [
			for (row in 0...rows)
				for (column in 0...columns)
					if (getAt(row, column) == null)
						{row: row, column: column}
		];
		return cells.length == 0 ? null : cells[Std.random(cells.length)];
	}

	function isValidCell(row:Int, column:Int):Bool
		return row >= 0 && row < rows && column >= 0 && column < columns;
}
