package mutts.net;

class Value {
	public static function field(raw:Dynamic, names:Array<String>):Dynamic {
		if (raw == null)
			return null;
		for (name in names) {
			final value = Reflect.field(raw, name);
			if (value != null)
				return value;
		}
		return null;
	}

	public static function str(raw:Dynamic, names:Array<String>):Null<String>
		return toString(field(raw, names));

	public static function id(raw:Dynamic, names:Array<String>):Null<String>
		return toId(field(raw, names));

	public static function int(raw:Dynamic, names:Array<String>):Null<Int> {
		final value = float(raw, names);
		return value == null ? null : Std.int(Math.floor(value));
	}

	public static function float(raw:Dynamic, names:Array<String>):Null<Float>
		return toFloat(field(raw, names));

	public static function strings(raw:Dynamic, names:Array<String>):Null<Array<String>> {
		final value = field(raw, names);
		if (!Std.isOfType(value, Array))
			return null;
		final values:Array<Dynamic> = cast value;
		return [for (item in values) if (item != null) Std.string(item)];
	}

	public static function toString(value:Dynamic):Null<String> {
		if (value == null)
			return null;
		final text = Std.string(value);
		return text == "" || text == "null" ? null : text;
	}

	public static function toId(value:Dynamic):Null<String> {
		if (value == null)
			return null;
		if (Std.isOfType(value, String) || Std.isOfType(value, Int) || Std.isOfType(value, Float) || Std.isOfType(value, Bool))
			return toString(value);
		final nested = field(value, ["id", "unit_id", "uuid"]);
		return nested == null ? toString(value) : toString(nested);
	}

	public static function toFloat(value:Dynamic):Null<Float> {
		if (value == null)
			return null;
		if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
			return value;
		final number = Std.parseFloat(Std.string(value));
		return Math.isNaN(number) ? null : number;
	}

	public static function setInt(target:Dynamic, name:String, value:Null<Int>):Void {
		if (value != null)
			Reflect.setField(target, name, value);
	}

	public static function sameId(a:Dynamic, b:Dynamic):Bool
		return a != null && b != null && Std.string(a) == Std.string(b);

	public static function seconds(value:Float):Float
		return value > 20 ? value / 1000 : value;

	public static function errorMessage(msg:Dynamic):String
		return msg.error ?? msg.message ?? msg.detail ?? "Backend rejected a game event.";
}
