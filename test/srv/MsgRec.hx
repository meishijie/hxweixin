package;


import haxe.Json;
import haxe.unit.TestCase;
import haxe.Int64;
import utils.Msg;
import SrvTest.trims;
import SrvTest.escape;
import SrvTest.xmlEq;
import SrvTest.xmlOut;
import utils.Tools;

class MsgRec extends TestCase{
	
	function testMessage(){
		print("<br />");
		var empty = new Smp();
		print("**EMPTY TO JSON** " + xmlOut(empty.toJson()) + "<br />");
		print("**EMPTY TO XML** " + xmlOut(empty.toXMLString()) + "<br />");
		print("**EMPTY TO URL** " + xmlOut(empty.toUrlParams()) + "<br />");
		empty.no = 0; empty.ok = "1"; empty.okn = "ok";
		empty.i6n = 1123; empty.non = 0.1358796; empty.t = {one: 98, two: Math.random(), three: "hello world"};
		print("**TO JSON** " + xmlOut(empty.toJson()) + "<br />");
		print("**TO XML** " + xmlOut(empty.toXMLString()) + "<br />");
		print("**TO URL** " + xmlOut(empty.toUrlParams()) + "<br />");
		print("<br />");
		// 多重继承
		print("Bar: " + xmlOut(new Bar(1.121212).toXMLString()) + "<br />");
		print("Hue: " + xmlOut(new Hue(Math.PI, 201).toXMLString()) + "<br />");
		print("<br />");
		var fj = new Foo();	fj.i64 = 101;
		print("**EMPTY TO XML** " + xmlOut(fj.toXMLString()) + "<br />");
		print("**EMPTY TO JSON** " + xmlOut(fj.toJson()) + "<br />");
		print("**EMPTY TO URL** " + xmlOut(fj.toUrlParams() + "<br />"));
		
		print("-------- FROM JSON/XML -----------<br />");
		var f1 = new Foo();
		fj.fromObj(Json.parse('{"first":3.1415926,"second":101,"c":0.776620913398878,"a":true,"b":101,"d":"dontouch","sign":"2F2D66F3DA2B1AE695B1096F9797DC39","i64":"1","struct":{"hehe":123,"haha":1.2131,"depth":{"hight":"hhh"}}}'));
		print("**TO XML** " + xmlOut(fj.toXMLString()) + "<br />");
		print("**TO JSON** " + xmlOut(fj.toJson()) + "<br />");
		print("**TO URL** " + xmlOut(fj.toUrlParams()) + "<br />");
		
		var f2 = new Foo();
		fj.fromXML(Xml.parse('<xml><first>3.1415926</first><second>101</second><c>0.776620913398878</c><a>true</a><b>101</b><d><![CDATA[dontouch]]></d><sign>2F2D66F3DA2B1AE695B1096F9797DC39</sign><i64>1</i64><struct><hehe>123</hehe><haha>1.2131</haha><depth><hight><![CDATA[hhh]]></hight></depth></struct><nn><![CDATA[null]]></nn></xml>').firstElement());
		print("**TO XML** " + xmlOut(fj.toXMLString()) + "<br />");
		print("**TO JSON** " + xmlOut(fj.toJson()) + "<br />");
		print("**TO URL** " + xmlOut(fj.toUrlParams()) + "<br />");

		assertTrue(f1.toXMLString() == f2.toXMLString() && f1.toJson() == f2.toJson() && f1.toUrlParams() == f2.toUrlParams());
	}
}

@:needjson @:needsign
class Smp extends Msg{
	public var no:Int;
	public var ok:String;
	
	public var okn:Null<String>;
	public var non:Null<Float>;
	public var i6n:Null<Int64>;		// 
	public var t:{one:Int, two:Float, three:String};
	public function new(){
	}
}

class Bar extends utils.Msg{
	public var first(default, null):Float;
	public function new(f:Float){
		first = f;
	}
}

class Hue extends Bar{
	public var second(default, null):Int;
	public function new(f, s){
		super(f);
		second = s;
	}
}

@:needjson
@:needsign
class Foo extends Hue{
	public var c:Null<Float>;
	public var a:Null<Bool>;
	public var b:Int;
	var d:String;
	@:nocdata public var sign(default, null):String;
	public var i64:Null<Int64>;
	
	public var struct:Null<{hehe:Int, haha:Float, ?depth:{hight:String, ?low:String}}>;// = {hehe: 123, haha: 1.2131, depth:{hight: "hhh"}};
	public var some:Some;
	
	public var nn:String;
	
	public function new(){
		super(Math.PI, 201);
	}
}

typedef Some = {
	one:String,
	two:Int64
}