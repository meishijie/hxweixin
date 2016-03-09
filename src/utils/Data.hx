package utils;


class Data{
}


/**
可用于分别存 access_token 和 jsapi_ticket
*/
#if tora @:rtti #end
@:structInit
class Token{
	public var uid:String;
	public var time:Float;	// sec
	public function new(uid:String, time:Float){
		this.uid = uid;
		this.time = time; 	// if NaN???
	}
	public function toString():String{
		return uid + "," + time;
	}
	
	public static function fromString(s:String):Token{
		var a = s.split(",");
		return new Token(a[0], Std.parseFloat(a[1]));
	}
}