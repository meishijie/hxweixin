package utils;

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
}