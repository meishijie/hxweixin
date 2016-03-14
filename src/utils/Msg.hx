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

 - 尝试添加 Int64 类型用于检测微信MsgId的重排问题. 当 Int64 为空时, 如果没有指定 `Null<Int64>` 则在 toXMLString, toJSON, toURLParams 时将出错

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

	/**
	*
	* @param ct
	* @param buff
	* @param tag
	* @param cdata = true	针对 String 类型,是否添加 `<![CDATA[ ]]>`
	* @param space = "  "	美化输出字符打印
	* @param opt = false	如果为 true, 则当值为 null 时将不会输出到 XML 中去
	* @param context = ""
	*/
	static function _toXmlRec(ct:ComplexType, buff:StringBuf, tag:String, cdata = true, opt = false, context = "", space = "  "):Void{
		var lt = '"$space<$tag>"';
		var rt = '"</$tag>\n"';
		var value = context + tag;
		switch (ct) {
			case TPath({name: "Null", params:[TPType(t)]}):
				_toXmlRec(t, buff, tag, cdata, true, context, space);
			case TPath(p):
				var ts = p.sub == null ? p.name : p.sub;
				switch(ts){
					case "Bool" | "Int" | "Float" | "Int64":
						buff.add(opt ? '(${value} != null ? ($lt + ${value} + $rt) : "" ) + ' : '$lt + ${value} + $rt + ');		
					case "String":
						if(cdata){
							lt = '"  <$tag><![CDATA["';
							rt = '"]]></$tag>\n"';
						}
						buff.add(opt ? '(${value} != null ? ($lt + ${value} + $rt) : "" ) + ' : '$lt + ${value} + $rt + ');
					default:
				}
			case TAnonymous(a):
				buff.add('$space ( $value != null ? ');
				buff.add('"$space<$tag>\n" + ');
				for(f in a){
					switch(f.kind){
						case FVar(t, _):
							_toXmlRec(t, buff, f.name, true, hasMeta(f.meta, ":optional"), value + ".", space + "  ");
						default:
					}
				}
				buff.add('"$space</$tag>\n"');
				buff.add('$space : "") + ');
			default:
		}
	}
	static function _toXml(mf:Array<MField>, pos:Position, fname = "toXMLString"):Void{
		var buff = new StringBuf();
		buff.add('{ return "<xml>\n" +');
		for(m in mf){
			_toXmlRec(m.ct, buff, m.field.name, m.cdata );
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

	/**
	buff 由于移除最后一个 , 号有些麻烦, 因此改用 Array<String> 来拼接字符串
	*/
	static function _toJsonRec(ct:ComplexType, buff:StringBuf, tag:String, opt = false, context = "", space = "  "):Void{
		var value = context + tag;
		switch (ct) {
			case TPath({name: "Null", params:[TPType(t)]}):
				_toJsonRec(t, buff, tag, true, context, space);
			case TPath(p):
				var ts = p.sub == null ? p.name : p.sub;
				switch(ts){
					case "Bool" | "Int" | "Float":
						buff.add(opt ? '\n+$space(${value} != null ? \',"$tag":\' + ${value} : "")' : '\n+$space\',"$tag":\' + ${value}');
					case "String" | "Int64":
						buff.add(opt ? '\n+$space(${value} != null ? \',"$tag":\' + \'"\' + ${value} + \'"\': "")' : '\n+$space\',"$tag":\' + \'"\' + ${value} + \'"\'');
					default:
				}
			case TAnonymous(a):
				var sub = new StringBuf();
				buff.add('\n+$space ($value != null ? ');
				for(f in a){
					switch(f.kind){
						case FVar(t, _):
							_toJsonRec(t, sub, f.name,hasMeta(f.meta, ":optional"), value + ".", space + "  ");
						default:
					}
				}
				if (sub.length > 0 ){
					var ss = sub.toString();
					var pi = ss.indexOf(",");
					if (pi > -1) ss = ss.substr(0, pi) + ss.substr(pi + 1);
					buff.add('\n$space\',"$tag":{\'' + ss  +'\n+ $space"}"');
				}else{
					buff.add('\n$space\',"$tag":{}\'');
				}
				buff.add(' : "")');
			default:
		}
	}
	static function _toJson(mf:Array<MField>,pos:Position, fname = "toJson"):Void{
		var buff = new StringBuf();
		for (m in mf){
			_toJsonRec(m.ct, buff, m.field.name, hasMeta(m.field.meta, ":optional"));
		}
		var code = buff.toString();
		var pi = code.indexOf(",");
		if (pi > -1) code = code.substr(0, pi) + code.substr(pi + 1);

		code = '{return "{"' +  code   + '\n+"}";\n}';

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

	static function _fromXmlRec(ct:ComplexType, buff:StringBuf, tag:String, context = "", root = "_x", space = "  "):Void{
		var value = context + tag;
		switch (ct) {
			case TPath({name: "Null", params:[TPType(t)]}):
				_fromXmlRec(t, buff, tag, context);

			case TPath(p):
				var ts = p.sub == null ? p.name : p.sub;
				switch(ts){
					case "Bool": 	buff.add('$space${value} = utils.Tools.firstInerData($root, "$tag") == "true";\n');
					case "Int":		buff.add('$space${value} = cast utils.Tools.firstInerData($root, "$tag");\n');
					case "Float":	buff.add('$space${value} = cast utils.Tools.firstInerData($root, "$tag");\n');
					case "String":	buff.add('$space${value} = utils.Tools.firstInerData($root, "$tag");\n');
					case "Int64":	buff.add('$space${value} = utils.Tools.i64(utils.Tools.firstInerData($root, "$tag"));\n');
					default:
				}

			case TAnonymous(a):
				var subroot =  tag + root;
				buff.add('${space}if(${value} == null) ${value} = cast {};\n');
				buff.add('${space}{\n ${space}  var ${subroot} = ${root}.elementsNamed("$tag").next();\n');
				buff.add('${space}  if(${subroot} != null){\n');
				for(f in a){
					switch(f.kind){
						case FVar(t, _):
							_fromXmlRec(t, buff, f.name, value + ".", subroot, "   " + space);
						default:
					}
				}

				buff.add('${space}  }\n${space}}\n');
			default:
		}
	}

	static function _fromXml(mf:Array<MField>, pos:Position, fname = "fromXML"):Void{
		var buff = new StringBuf();
		buff.add("{\n");
		for (m in mf){
			_fromXmlRec(m.ct, buff, m.field.name);
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

	static function _fromJsonRec(ct:ComplexType, buff:StringBuf, tag:String, context = "", root = "_o.", space = "  "):Void{
		var value = context + tag;
		var tar = root + tag;
		switch (ct) {
			case TPath({name: "Null", params:[TPType(t)]}):
				_fromJsonRec(t, buff, tag, context, root, space);
			case TPath(p):
				var ts = p.sub == null ? p.name : p.sub;
				switch (ts) {
					case "Bool", "Int", "Float", "String":
						buff.add('$space$value = $tar;\n');
					case "Int64":
						buff.add('$space$value = utils.Tools.i64($tar);\n');
					default:
				}
			case TAnonymous(a):
				buff.add('$space if($tar != null){\n');
				buff.add('$space$space if($value == null) $value = cast {};\n');
				for(f in a){
					switch(f.kind){
						case FVar(t, _):
							_fromJsonRec(t, buff, f.name, value + ".", tar + ".", space + space + "  ");
						default:
					}
				}
				buff.add('$space}\n');
			default:
		}
	}
	static function _fromJson(mf:Array<MField>, pos:Position, fname = "fromObj"):Void{
		var buff = new StringBuf();
		buff.add("{\n");
		for(m in mf){
			_fromJsonRec(m.ct, buff, m.field.name);
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
					name: "_o",
					type: macro :Dynamic
				}],
				expr: Context.parseInlineString(buff.toString(), pos)
			})
		});
	}

	static inline var SIGN = "sign";
	static inline var KEY = "key";
	static function _toUrlRec(ct:ComplexType, buff:StringBuf, tag:String, opt = false, context = ""):Void{
		var value = context + tag;
		switch (ct) {
			case TPath({name: "Null", params:[TPType(t)]}):
				_toUrlRec(t, buff, tag, true, context);
			case TPath(p):
				var ts = p.sub == null ? p.name : p.sub;
				switch (ts) {
					case "Bool" | "Int" | "Float" | "String" | "Int64":
						buff.add(opt ? '($value == null ? "" : "&$tag=" + $value) + ' : '"&$tag=" + $value + ');
					default:
				}
			case TAnonymous(a):
//				trace("toUrlParams: (TAnonymous) does not implement yet");
				// TODOS: 未来如果微信会把多层 XML 转换成 search 时再改这里
			default:
		}
	}
	static function _toUrl(mf:Array<MField>, pos:Position, fname = "toUrlParams"):Void{
		var buff = new StringBuf();
		for (m in mf) {
			var tag = m.field.name;
			if (tag == SIGN) continue;
			if (tag == KEY) Context.warning("see \"_makeSign()\"...", pos);
			_toUrlRec(m.ct, buff, tag);
		}

		var code = buff.toString();
		if (code.length >= 3) code = code.substr(0, code.length -3);	// remove ' + '
		code = '{return ($code).substr(1);}';
		fields.push({
			name: fname,
			doc: "e.g: a=1&b=2&c=3",
			access: supers.indexOf(fname) == -1 ? [APublic] : [APublic, AOverride],
			pos: pos,
			kind: FFun({
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(code, pos)
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

	static function hasMeta(meta:Metadata, name:String):Bool{
		for (m in meta)
			if (m.name == name)
				return true;
		return false;
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
		//trace([for(f in fields) f.name]);
		return fields;
	}
	#end
}