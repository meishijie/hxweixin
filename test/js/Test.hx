package;


import haxe.Timer;
import utils.Msg;
import utils.GenUid;
import utils.Data;
import js.Wx;

class Test{

	public static function main(){
		testGenUid();
		testExternWx();
		testMsg();

	}
	
	
	static function testExternWx(){
		var t = new Token(GenUid.v4(), Timer.stamp());
		var f = Token.fromString(t.toString());
		trace("ToKen:" + f.toString() == t.toString());
	}
	
	static function testGenUid(){
		for(i in 0...2){
			trace("random id: " + GenUid.v4() + " - short: " + GenUid.token());
		}
	}
	
	static function testMsg(){
		var foo = new Foo(true, 101, 0.96456456466, "dontouch");
		var s = ~/\s/g.replace(foo.toXMLString(), "");
		trace(s);
		
		foo.fromXMLString(Xml.parse(s));
		var x = ~/\s/g.replace(foo.toXMLString(), "");
		trace(x);
		trace("testMsg: " + (x == s));
	}
}

@:structInit
class Foo extends Msg{
	var a:Bool;
	var b:Int;
	var c:Float;
	@:cdata var d:String;
	public function new(a, b, c, d){
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
	}
}