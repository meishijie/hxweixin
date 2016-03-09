package srv;

import haxe.Timer;
import haxe.Json;
import sys.io.Process;
import neko.Lib;
import neko.Web;
import utils.Tools;
import utils.Data;

/*
private typedef AccessObj = {
	?access_token:Null<String>,
	?expires_in:Int,
	?errcode:Int,
	?errmsg:String
}

private typedef TicketObj = {
	?ticket:Null<String>,
	?expires_in:Int,
	?errcode:Int,
	?errmsg:String
}
*/

@:enum private abstract TokenType(Int) to Int{
	var ACCESS = 0;
	var TICKET = 1;
}


/**
将 access_token 和 jsapi_ticket 于服务器的内存.

**Note:** 如果没有启用 tora 必须用 Web.cacheModule 缓存模块

 - 目前使用新建一个 process 来运行 curl(cygwin) 以发送 HTTPS 请求, 未来再改成 hxssl 的方式
*/
class Cache{
	#if tora
	static var access_share(default, null) = new tora.Share<Token>("wx_token", function(){
		return new Token("", 0);
	}, Token);
	
	static var ticket_share(default, null) = new tora.Share<Token>("wx_ticket", function(){
		return new Token("", 0);
	}, Token);
	#end
	
	
	static var cur_token:Array<Token> = [null, null];	// 将二个 token 放一起, 方便后边的作引用传参数,
	
	public static var access(get, null):Null<String>;
	static function get_access(){
		return get(#if tora access_share, #end ACCESS, 'https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=${Config.WX_APPID}&secret=${Config.WX_APPSECRET}');
	}
	
	public static var ticket(get, null):Null<String>;
	static function get_ticket(){
		var acc = get_access();
		return acc == null ? null : get(#if tora ticket_share, #end TICKET,'https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=$acc&type=wx_card');
	}
	
	static function get(#if tora share:tora.Share<Token>, #end index:TokenType, url:String):Null<String>{
	#if tora
		var t:Token;
		var commit = true;
		if(cur_token[index] == null){
			t = share.get(true);
		}else{
			t = cur_token[index];
			commit = false;
		}	
	#else
		var t:Token = cur_token[index];
		if (t == null) t = new Token("", 0);
	#end
		var now = Timer.stamp();
		
		if (now >= (t.time + EXPIRES)){
			var uid:Null<String> = null;
			var obj:{?errcode:Int, ?errmsg:String, ?expires_in:Int};
			var f = index == TokenType.ACCESS ? "access_token" : "ticket";
			var fail:Int = 0;
			
			while (true){
				obj = curl(url);
				if (obj != null) uid = Reflect.field(obj, f);	// 超时, 没有网络, 将返回 null
				if (uid == null){
					Web.logMessage(obj == null ? "probable timeout" : obj.errcode + ": " + obj.errmsg);
					fail += 1;
					if (fail >= FAILTRY){						// 单个实例, 尝试 2 次
						t = null;
						break;
					} 					
					Sys.sleep(0.2);	
				}else{
					t.uid = uid;
					t.time = now;
					cur_token[index] = t;
				#if tora
					commit = true;
					share.set(t);
				#end
					break;
				}
			}
		}
	#if tora
		if(commit) share.commit();
	#end
		return t == null ? null : t.uid;
	}
	
	
	public static inline var EXPIRES:Float = 7000;	// sec
	public static inline var FAILTRY:Float = 2;
	
	//TODO: 未来替换成 hxssl 的 https 请求
	public static function curl(url:String):Dynamic{	
		var p = new Process("curl", ["--connect-timeout", "8", url]);
		if(p != null && p.exitCode() == 0){
			return Json.parse( neko.Lib.stringReference(p.stdout.readAll()) );
		}
		return null;
	}
}