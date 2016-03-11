package utils;
import haxe.macro.PositionTools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.xml.Fast;

using haxe.macro.TypeTools;

typedef MField = {
	ct: ComplexType,
	field: Field,
	cdata:Bool
}
#end

/**
自动解析 FVar,FProp("default",_) 字段,只处理 String, Int/Float, Bool 这些简单类型,

 - 不处理例如 Null<Int> 可为 null 的字段

 - 不处理 _ 打头的字段和静态字段

 - 不支持 Int64, 考虑用 @:nocdata 的 String 代替, 如果不需要计算数值的话

*/
#if !macro
@:autoBuild(utils.Msg.build())
#end
class Msg{

	#if macro
	static var fields:Array<Field>;

	static function _toXml(mf:Array<MField>, pos:Position):Void{
		var buff = new StringBuf();
		buff.add('{ return "<xml>\n" +');
		for(m in mf){
			var tag = m.field.name;
			var lt = '"  <$tag>"';
			var rt = '"</$tag>\n"';
			switch(m.ct){
				case TPath(p):
					var type = p.sub == null ? p.name : p.sub;
					switch(type){	// toXmlString
						case "Bool" | "Int" | "Float":
							buff.add('$lt + $tag + $rt + ');
						case "String":
							if(m.cdata){
								lt = '"  <$tag><![CDATA["';
								rt = '"]]></$tag>\n"';
							}
							buff.add('$lt + $tag + $rt + ');
						//case "Array":
						//	buff.add('($tag != null ? [ for(v in $tag) $lt + v +$rt].join("") + "\n" : "" ) +');
						default:
					}
				default:
			}
		}

		buff.add('"</xml>"; }');

		fields.push({
			name: "toXMLString",
			doc: "...",
			access: [APublic],
			pos: pos,
			kind: FFun( {
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static function _toJson(mf:Array<MField>,pos:Position):Void{
		var buff = new Array<String>();
		for(m in mf){
			var tag = m.field.name;
			switch(m.ct){
				case TPath(p):
					var type = p.sub == null ? p.name : p.sub;
					switch(type){
						case "Bool" | "Int" | "Float":
							buff.push('\'"$tag":\' + $tag');	// '"a":' + $a
						case "String":
							buff.push('\'"$tag":"\' + $tag + \'"\'');
						default:
					}
				default:
			}
		}
		//trace(buff.join('+","+'));
		var code = '{return "{" + ' + buff.join('+","+') +  ' + "}";}';

		fields.push({
			name: "toJson",
			doc: "toJson string",
			access: [APublic],
			pos: pos,
			kind: FFun( {
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(code, pos)
			})
		});
	}
	
	static function _fromXml(mf:Array<MField>, pos:Position):Void{
		var buff = new StringBuf();
		buff.add("{var f = new haxe.xml.Fast( Xml.parse(xml).firstElement() );");
		for (m in mf){
			var tag = m.field.name;
			switch(m.ct){
				case TPath(p):
					var type = p.sub == null ? p.name : p.sub;
					switch (type) {
						case "Bool":	buff.add('$tag = f.node.resolve("$tag").innerData == "true";');
						case "Int":		buff.add('$tag = Std.parseInt(f.node.resolve("$tag").innerData);');
						case "Float":	buff.add('$tag = Std.parseFloat(f.node.resolve("$tag").innerData);');
						case "String":	buff.add('$tag = f.node.resolve("$tag").innerData;');
						default:
					}
				default:
			}
		}
		buff.add("}");

		fields.push({
			name: "fromXMLString",
			doc:"",
			access: [APublic],		// 由于 static 类型的需要获得构造方法的参数顺序因此复杂度太高
			pos: pos,
			kind: FFun({
				ret: macro :Void,
				args: [{
					name: "xml",
					type: macro :String
				}],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static function _fromJson(mf:Array<MField>, pos:Position):Void{
		var buff = new StringBuf();
		buff.add("{ var o = haxe.Json.parse(json);");
		for(m in mf){
			var tag = m.field.name;
						switch(m.ct){
				case TPath(p):
					var type = p.sub == null ? p.name : p.sub;
					switch (type) {
						case "Bool", "Int", "Float", "String":
							buff.add('$tag = o.$tag;');
						default:
					}
				default:
			}
		}
		buff.add("}");

		fields.push({
			name: "fromJson",
			doc:"from JSON String.",
			access: [APublic],
			pos: pos,
			kind: FFun({
				ret: macro :Void,
				args: [{
					name: "json",
					type: macro :String
				}],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static inline var SIGN = "sign";
	static inline var KEY = "key";
	static function _toUrl(mf:Array<MField>, pos:Position):Void{
		var buff = new StringBuf();
		var a = [];
		for (m in mf) {
			var tag = m.field.name;
			if (tag == SIGN) continue;
			if (tag == KEY) Context.warning("see \"_makeSign()\"...",pos);

			switch (m.ct) {
				case TPath(p):
					var type = p.sub == null ? p.name : p.sub;
					switch (type) {
						case "Bool" | "Int" | "Float" | "String":
							a.push('"$tag=" + $tag');	// '"a=" + a'   '+"&"+'  '"b=" + b'
						default:
					}
				default:
			}
		}

		buff.add("return " + a.join('+"&"+'));

		fields.push({
			name: "toUrlParams",
			doc: "e.g: a=1&b=2&c=3",
			access: [APublic],
			pos: pos,
			kind: FFun({
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static function _makeSign(pos:Position):Void{
		var buff = new StringBuf();
		buff.add('{
			var url = toUrlParams() + "&key=" + srv.Config.WX_KEY;
			return haxe.crypto.Md5.encode(url).toUpperCase();
		}');

		fields.push({
			name: "makeSign",
			access: [APublic],
			pos: pos,
			kind: FFun({
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static function fullType(t:BaseType):String{
		var name = t.module == t.name ? t.name : t.module + "." + t.name;
		if (t.pack != null && t.pack.length > 0) {
			name = t.pack.join(".") + "." + name;
		}
		return name;
	}

	static function filter(fs:Array<Field>, out:Array<MField>):Void{
		for (f in fs){

			if (f.name.charCodeAt(0) == "_".code || f.access.indexOf(AStatic) != -1) continue;

			var cdata = true;

			for (m in f.meta){
				if (m.name == ":skip") continue;
				if (m.name == ":nocdata") cdata = false;
			}

			switch(f.kind){
				case FVar(t, _) | FProp("default", _, t, _):
					if (t != null)
						out.push({
							ct: t,
							field:f,
							cdata:cdata
						});
				default:
			}
		}
	}

	public static function build(){

		fields = Context.getBuildFields();

		var cls:ClassType = Context.getLocalClass().get();
		cls.meta.add(":final", [], Context.currentPos());

		var mf:Array<MField> = [];

		if(cls.superClass != null){
			var sup:ClassType = cls.superClass.t.get();
			var cfs = sup.fields.get();
			filter([for (cf in cfs) @:privateAccess TypeTools.toField(cf)], mf);
		}

		filter(fields, mf);

		_toXml(mf, PositionTools.here());			// toXmlString, 需要保持原有的字段排序.

		_fromXml(mf, PositionTools.here()); 		// fromXmlString

		if (cls.meta.has(":needjson")){				// 如果 -dce full 服务器能正常, 可以注释掉这条件
			_toJson(mf, PositionTools.here());		// toJson
			_fromJson(mf, PositionTools.here());	// formJson
		}

		if(cls.meta.has(":needsign")){

			mf.sort(function(a, b){					// TODO: ??? ksort 键值按字典排序
				return a.field.name > b.field.name ? 1 : -1;
			});
			_toUrl(mf, PositionTools.here());		// toUrlParams
			_makeSign(PositionTools.here());		// makeSign
		}
		return fields;
	}
	#end
}