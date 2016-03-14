package utils;
import haxe.Timer;

#if neko
typedef Xml = neko.NativeXml;
#end

class Tools{
	/**
	得到 XML 的第一个指定名称的子元素的 innerData
	*/
	static public function firstInerData(x:Xml, name:String):String{
		var n = x.elementsNamed(name).next();
		return n != null ? getInnerData(n) : null;
	}

	/**
	copy from haxe.xml.Fast, 用于获得一个元素的 innerData
	*/
	static public function getInnerData(x:Xml):String{
		var it = x.iterator();
		if( !it.hasNext() ) return null;
		var v = it.next();
		var n = it.next();
		if( n != null ) {
			// handle <spaces>CDATA<spaces>
			if( v.nodeType == Xml.PCData && n.nodeType == Xml.CData && StringTools.trim(v.nodeValue) == "" ) {
				var n2 = it.next();
				if( n2 == null || (n2.nodeType == Xml.PCData && StringTools.trim(n2.nodeValue) == "" && it.next() == null) )
					return n.nodeValue;
			}
			return null;
		}
		if ( v.nodeType != Xml.PCData && v.nodeType != Xml.CData )
			return null;
		return v.nodeValue;
	}
	
	static public inline function i64(s:String):haxe.Int64{
		return try{
			haxe.Int64Helper.parseString(s);
		}catch(err:Dynamic){
			haxe.Int64.make(0,0);
		}
	}

	/**
	只针对包含了一个 TextNode 的简单 XML 元素, 或许会有 CData, 仅适用于从 XML 读取一个元素的值,如 MsgType

	用于当 服务器发消息过来时, 检测XML消息的 "MsgType", 以及是否包含有 "MsgId" 来区分普通消息
	*/
	static public function fastInner(x:String, name:String):String{
		var pstart = "<" + name;
		var pend = "</" + name;
		var p:Int, p2:Int;

		p = x.indexOf(pstart);
		if (p == -1) return null;
		p += pstart.length;

		p = x.indexOf(">", p);
		if (p == -1) return null;
		p += 1;

		p2 = x.indexOf(pend, p + 1);
		if (p2 == -1) return null;

		var inner = StringTools.trim( x.substring(p, p2) );
		var len = inner.length;
		if (len >= 12 && inner.substr(0, 9) == CDATA_L){ 	// "(<![CDATA[" +  "]]>").length == 12
			inner = inner.substr(9, len - 12);
		}
		return inner;
	}

	public static inline var CDATA_L = "<![CDATA[";
	public static inline var CDATA_R = "]]>";
}