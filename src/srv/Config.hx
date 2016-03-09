package srv;

import neko.Web;

class Config{

	public static var DIR;
	
	static function initConfig(){
		var cwd = Web.getCwd();
		DIR = cwd + "../";
		var data;
		try{ 
			data = sys.io.File.getContent(DIR + "config.xml");
		}catch(e:Dynamic){
			data = sys.io.File.getContent(DIR + "cfg/" + "config.xml");
		}
		return Xml.parse(data).firstElement();
	}
	
	static var xml = initConfig();
	
	public static function get(att:String, ?def):String{
		var v = xml.get(att);
		if (v == null)
				v = def;
		if (v == null)	
				throw "Missing config attribute " + att;
		return v;
	}
	
	public static var LANG = get("lang");
	public static var WX_APPID = get("appID");
	public static var WX_APPSECRET = get("appsecret");
	public static var TPL = DIR + "tpl/" + LANG + "/";
	
	public static var USE_HTACCESS = get("htaccess", "0") == "1";
	
	public static function getSection(name:String, ?def:String):String{
		var e = xml.elementsNamed(name).next();
		if (e == null)
				return def;
		var b = new StringBuf();
		for (x in e)				// innerHTML, CDATA 也将是带着标签
				b.add(x.toString());	
		return b.toString();
	}
}