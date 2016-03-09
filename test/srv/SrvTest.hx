package;

import haxe.unit.TestRunner;
import srv.Config;
import srv.Cache;
import neko.Web;


class SrvTest extends haxe.unit.TestCase{

	public function testHelloWorld(){
		trace("hello world! isTora: " + Web.isTora);
		//trace("access_token: " + Cache.access);
		//trace("jsapi_ticket: " + Cache.ticket);
		
		trace(Config.WX_APPID + " - " + Config.WX_APPSECRET);
		assertTrue(true);
	}
	
	public static function main(){
		trace("init instance..<br />");
		Web.cacheModule(run);
		run();
	}
	static function run(){
		var runner = new TestRunner();
		runner.add(new SrvTest());
		Sys.println("<pre>");
		runner.run();
		Sys.println("</pre>");
	}
}