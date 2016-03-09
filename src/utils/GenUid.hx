package utils;

/**
https://github.com/fi11/gen-uid
*/
class GenUid{

	#if macro
	static var lut:Array<String> = [for (i in 0...256) StringTools.hex(i, 2)];
	#else
	static var lut:Array<String> = lutInit();
	#end
	
	public static function v4():String{
		var d0 = Std.int(Math.random() * 0x7fffffff);
		var d1 = Std.int(Math.random() * 0x7fffffff);
		var d2 = Std.int(Math.random() * 0x7fffffff);
		var d3 = Std.int(Math.random() * 0x7fffffff);
		return lut[d0&0xff] + lut[d0>>8&0xff] + lut[d0>>16&0xff] + lut[d0>>24&0xff] +
			'-' +lut[d1&0xff] + lut[d1>>8&0xff] +
			'-' + lut[d1>>16&0x0f|0x40] + lut[d1>>24&0xff] +
			'-' + lut[d2&0x3f|0x80] + lut[d2>>8&0xff] +
			'-' + lut[d2>>16&0xff] + lut[d2>>24&0xff] + lut[d3&0xff] + lut[d3>>8&0xff] + lut[d3>>16&0xff] + lut[d3>>24&0xff];		
	}
	
	public static function token(isShort:Bool = true):String {
		var d0 = Std.int(Math.random() * 0x7fffffff);
		var d1 = Std.int(Math.random() * 0x7fffffff);	
		var short = lut[d0 >> 16 & 0xff] + lut[d0 >> 24 & 0xff] + lut[d1 & 0xff] + lut[d1 >> 8 & 0xff];
		return isShort ? short : lut[d1>>16&0xff] + lut[d1>>24&0xff];
	}
	
	macro static function lutInit() return macro $v{[for (i in 0...256) StringTools.hex(i, 2)]};
}