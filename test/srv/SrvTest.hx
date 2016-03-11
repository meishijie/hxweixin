package;

import haxe.Int64;
import haxe.Json;
import haxe.unit.TestRunner;
import srv.Config;
import srv.Cache;
import srv.Data;
import utils.Msg;
import neko.Web;
import srv.data.WxPayDataBase;



class SrvTest extends haxe.unit.TestCase{

	public function testHelloWorld(){
		trace("hello world! isTora: " + Web.isTora);
		//trace("access_token: " + Cache.access);
		//trace("jsapi_ticket: " + Cache.ticket);
		
		trace(Config.WX_APPID + " - " + Config.WX_APPSECRET);
		
		assertTrue(true);
	}
	
	function testMsg(){
		trace("------------- testMsg -------------");
		var foo = new Foo(true, 101, Math.random(), "dontouch", 1);
		var s = trims( foo.toXMLString() );
		trace(escape(s));
		trace(foo.toUrlParams());
		foo.fromXMLString(s);

		var x = trims( foo.toXMLString() );
		trace(escape(x));
		Sys.println("toJSON: " + foo.toJson());
		foo.fromJson('{"c":0.192682669388513,"a":true,"b":101,"d":"dontouch","sign":"2594F21EA204B53D306F96BAF0171096"}');
		Sys.println("toJSON: " + foo.toJson());
		
		var text = new RecText();
		@:privateAccess text.MsgId = 1231231231; // Int64 没有默认的空值将报错
		trace("**EMPTY TOXMLSTRING**: " + escape( trims(text.toXMLString()) )); 
		text.fromXMLString(TEXTXML);
		trace(escape( trims(text.toXMLString()) ));
		trace(escape( trims(TEXTXML) ));
		assertTrue(x == s);	
		assertTrue(~/\s/g.replace(text.toXMLString(), "") == ~/\s/g.replace(TEXTXML, "") );
	}
	
	static function trims(str) return ~/\s/g.replace(str, "");
	
	static function escape(str:String) return StringTools.htmlEscape(str).split("\n").join("<br />");
	
	
	public static function main(){
		trace("init instance.. 你好, 世界<br />");
		//Web.cacheModule(run);
		run();
	}
	static function run(){
		var runner = new TestRunner();
		runner.add(new SrvTest());
		Sys.println('<meta charset="utf-8"/>');
		Sys.println("<pre>");
		runner.run();
		Sys.println("</pre>");
	}
	
	
	
	
	
	
	inline static var XML = "<xml>
  <name><![CDATA[ben]]></name>
  <some>1123</some>
  <sign>633F4DD867196F0AFFEE26BFCD295946</sign>
  <hello><![CDATA[world]]></hello>
</xml>";

	inline static var TEXTXML = "
 <xml>
 <ToUserName><![CDATA[toUser]]></ToUserName>
 <FromUserName><![CDATA[fromUser]]></FromUserName> 
 <CreateTime>1348831860</CreateTime>
 <MsgType><![CDATA[text]]></MsgType>
 <Content><![CDATA[这是一首简单的 some world]]></Content>
 <MsgId>1234567890123456</MsgId>
 </xml>	
";
}


@:needsign
@:needjson
class Foo extends Msg{
	var c:Float;
	var a:Bool;
	var b:Int;
	
	var d:String;
	@:nocdata public var sign(default, null):String;
	
	
	var i64:Int64;
	public function new(a, b, c, d, x){
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.i64 = x;
	}
}

class OptMsg<T:{}>{
	
	var values:T;
	
	public function new(v:T){
		values = v;
	}
	
	public function toXmlString():String{
		var keys = Reflect.fields(values);
		var buff = new StringBuf();
		buff.add("<xml>\n");
		for (k in keys){
			var v = Reflect.field(values, k);
			buff.add(Math.isNaN(Std.parseFloat(v)) ? '  <$k><![CDATA[$v]]></$k>\n' : '  <$k>$v</$k>\n');
		}
		buff.add("</xml>");
		return buff.toString();
	}
	
	public function fromXmlString(xml:String){
		for (el in Xml.parse(xml).firstElement().elements()){
			// 只取得第一个 文本元素的 nodeValue 值
			Reflect.setField(values, el.nodeName, el.firstChild().nodeValue); 
		}
	}
}
