package;

import haxe.Int64;
import haxe.Json;
import haxe.unit.TestRunner;
import srv.Config;
import srv.Cache;
import utils.Msg;
import neko.Web;




class SrvTest extends haxe.unit.TestCase{

	public function testHelloWorld(){
		trace("hello world! isTora: " + Web.isTora);
		//trace("access_token: " + Cache.access);
		//trace("jsapi_ticket: " + Cache.ticket);
		
		trace(Config.WX_APPID + " - " + Config.WX_APPSECRET);
		
		assertTrue(true);
	}
	
	public static function trims(str) return ~/\s/g.replace(str, "");
	
	public static function escape(str:String) return StringTools.htmlEscape(str).split("\n").join("<br />");
	
	public static function xmlEq(a:String, b:String):Bool return trims(a) == trims(b);
	
	public static function xmlOut(a:String, trim:Bool = true):String return trim ? escape(trims(a)) : escape(a);
	
	public static function main(){
		//Web.cacheModule(run);
		run();
	}
	static function run(){
		Sys.println('<html> <head> <meta charset="utf-8"/><title>this is a test</title></head><body>');
		Sys.println("<pre>");
		var runner = new TestRunner();
		runner.add(new SrvTest());
		runner.add(new MsgRec());
		runner.run();
		Sys.println("</pre></body></html>");
	}
}
