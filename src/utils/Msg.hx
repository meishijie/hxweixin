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

 - 尝试添加 Int64 类型用于检测微信MsgId的重排问题.

 - 如果在类添上 `@:skip`将不再构建这个类, 这个可用于多继承中间的类

 - 允许多重继承

*/
#if !macro
@:autoBuild(utils.MsgBuild.make())
#end
class Msg{
}

class MsgBuild {
	#if macro
	static var fields:Array<Field>;
	static var supers:Array<String>;

	static function _toXml(mf:Array<MField>, pos:Position, fname = "toXMLString"):Void{
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
						case "Bool" | "Int" | "Float" | "Int64":
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
			name: fname,
			doc: "...",
			access: supers.indexOf(fname) == -1 ? [APublic] : [APublic, AOverride],
			pos: pos,
			kind: FFun( {
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static function _toJson(mf:Array<MField>,pos:Position, fname = "toJson"):Void{
		var buff = new Array<String>();
		for(m in mf){
			var tag = m.field.name;
			switch(m.ct){
				case TPath(p):
					var type = p.sub == null ? p.name : p.sub;
					switch(type){
						case "Bool" | "Int" | "Float":
							buff.push('\'"$tag":\' + $tag');	// '"a":' + $a
						case "String" | "Int64":				// 暂时将 Int64 转换成字符串形式
							buff.push('\'"$tag":"\' + $tag + \'"\'');
						default:
					}
				default:
			}
		}
		//trace(buff.join('+","+'));
		var code = '{return "{" + ' + buff.join('+","+') +  ' + "}";}';

		fields.push({
			name: fname,
			doc: "toJson string",
			access: supers.indexOf(fname) == -1 ? [APublic] : [APublic, AOverride],
			pos: pos,
			kind: FFun( {
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(code, pos)
			})
		});
	}
	
	static function _fromXml(mf:Array<MField>, pos:Position, fname = "fromXML"):Void{
		var buff = new StringBuf();
		buff.add("{");
		for (m in mf){
			var tag = m.field.name;
			switch(m.ct){
				case TPath(p):
					var type = p.sub == null ? p.name : p.sub;
					switch (type) {
						case "Bool":	buff.add('$tag = utils.Tools.firstInerData(_x, "$tag") == "true";');
						case "Int":		buff.add('$tag = Std.parseInt(utils.Tools.firstInerData(_x, "$tag"));');
						case "Float":	buff.add('$tag = Std.parseFloat(utils.Tools.firstInerData(_x, "$tag"));');
						case "String":	buff.add('$tag = utils.Tools.firstInerData(_x, "$tag");');
						case "Int64":	buff.add('$tag = utils.Tools.i64( utils.Tools.firstInerData(_x, "$tag") );');
						default:
					}
				default:
			}
		}
		buff.add("}");

		fields.push({
			name: fname,
			doc:"",
			access: supers.indexOf(fname) == -1 ? [APublic] : [APublic, AOverride],		// 由于 static 类型的需要获得构造方法的参数顺序因此复杂度太高
			pos: pos,
			kind: FFun({
				ret: macro :Void,
				args: [{
					name: "_x",
					type: macro :Xml
				}],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static function _fromJson(mf:Array<MField>, pos:Position, fname = "fromJson"):Void{
		var buff = new StringBuf();
		buff.add("{ var _o = haxe.Json.parse(json);");
		for(m in mf){
			var tag = m.field.name;
						switch(m.ct){
				case TPath(p):
					var type = p.sub == null ? p.name : p.sub;
					switch (type) {
						case "Bool", "Int", "Float", "String":
							buff.add('$tag = _o.$tag;');
						case "Int64":
							buff.add('$tag = utils.Tools.i64(_o.$tag);');
						default:
					}
				default:
			}
		}
		buff.add("}");

		fields.push({
			name: fname,
			doc:"from JSON String.",
			access: supers.indexOf(fname) == -1 ? [APublic] : [APublic, AOverride],
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
	static function _toUrl(mf:Array<MField>, pos:Position, fname = "toUrlParams"):Void{
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
						case "Bool" | "Int" | "Float" | "String" | "Int64":
							a.push('"$tag=" + $tag');	// '"a=" + a'   '+"&"+'  '"b=" + b'
						default:
					}
				default:
			}
		}

		buff.add("return " + a.join('+"&"+'));

		fields.push({
			name: fname,
			doc: "e.g: a=1&b=2&c=3",
			access: supers.indexOf(fname) == -1 ? [APublic] : [APublic, AOverride],
			pos: pos,
			kind: FFun({
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static function _makeSign(pos:Position, fname = "makeSign"):Void{
		var buff = new StringBuf();
		buff.add('{
			var url = toUrlParams() + "&key=" + srv.Config.WX_KEY;
			return haxe.crypto.Md5.encode(url).toUpperCase();
		}');

		fields.push({
			name: fname,
			access: supers.indexOf(fname) == -1 ? [APublic] : [APublic, AOverride],
			pos: pos,
			kind: FFun({
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static function _makeEq(mf:Array<MField>, pos:Position, fname1 = "eqById", fname2 = "eqByNameNTime"):Void{
		var hasId = false;
		var hasName = false;
		var hasStamp = false;
		for (m in mf){
			var name = m.field.name;
			if(name == "MsgId"){
				hasId = true;
				break;
			}else if(name == "FromUserName"){
				hasName = true;
			}else if(name == "CreateTime"){
				hasStamp = true;
			}
		}
		if(hasId){
			fields.push({
				name: fname1,
				access: supers.indexOf(fname1) == -1 ? [APublic] : [APublic, AOverride],
				pos: pos,
				kind: FFun({
					ret: macro :Bool,
					args:[{
						name: "i64",
						type: macro :haxe.Int64
					}],
					expr: macro {
						return $i{"MsgId"} == $i{"i64"};
					}
				})
			});
		}else if(hasName && hasStamp){
			fields.push({
				name: fname2,
				access: supers.indexOf(fname2) == -1 ? [APublic] : [APublic, AOverride],
				pos: pos,
				kind: FFun({
					ret: macro :Bool,
					args:[{
						name: "name",
						type: macro :String
					},{
						name: "stamp",
						type: macro :Float
					}],
					expr: macro {
						return $i{"FromUserName"} == $i{"name"} && $i{"CreateTime"} == $i{"stamp"};
					}
				})
			});
		}
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

	static function recAllFields(cls:ClassType, out:Array<MField>):Void{
		if(cls.superClass != null){
			recAllFields(cls.superClass.t.get(), out);
		}
		var cfs = cls.fields.get().filter(function(f):Bool{
			switch(f.kind){
				case FVar(_,_):
					return true;
				default:
					supers.push(f.name);
					return false;
			}
		});

		filter([for (cf in cfs) @:privateAccess TypeTools.toField(cf)], out);
	}

	public static function make(){

		var cls:ClassType = Context.getLocalClass().get();

		if (cls.meta.has(":skip")) return null;		// 跳过

		fields = Context.getBuildFields();

		supers = [];

		var mf:Array<MField> = [];

		if (cls.superClass != null) recAllFields(cls.superClass.t.get(), mf);

		filter(fields, mf);

		_toXml(mf, PositionTools.here());			// toXmlString, 需要保持原有的字段排序.

		_fromXml(mf, PositionTools.here()); 		// fromXmlString

		_makeEq(mf, PositionTools.here());

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