package utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.xml.Fast;
#end

/**
将成员属性在输出时自动转换成 XML 形式, (FVar,FProp), 只处理 String, Int/Float, Bool 这些简单属性
*/
#if !macro
@:autoBuild(utils.Msg.build())
#end
class Msg{
	#if macro
	public static function build(){
		var fields:Array<Field> = Context.getBuildFields();
		var pos = Context.currentPos();

		var code = new StringBuf();
		var from = new Array<Expr>();
		code.add('{ return "<xml>\n" +');
		for (f in fields){
			var cdata = false;
			for (m in f.meta){
				if (m.name == ":skip") continue;
				if (m.name == ":cdata") cdata = true;
			}
			
			if (f.access.indexOf(AStatic) != -1) continue;
		
			switch(f.kind){
				case FVar(t, _) | FProp("default", _, t, _):
					if (t != null)
						export(f, t, code, from, cdata);	
				default:
			}
		}
		code.add('"</xml>"; }');
		
		fields.push({
			name: "toXMLString",
			doc: "...",
			access: [APublic],
			pos: pos,
			kind: FFun( {
				ret: macro :String,
				args: [],
				expr: Context.parseInlineString(code.toString(), pos)
			})			
		});
	
		fields.push({
			name: "fromXMLString",
			doc:"",
			access: [APublic],		// 由于 static 类型的需要获得构造方法的参数顺序因此复杂度太高
			pos: pos,
			kind: FFun({
				ret: macro :Void,
				args: [{
					name: "xml",
					type: macro :Xml
				}],
				expr: macro {
					var fa = new haxe.xml.Fast(xml.firstElement());
					$b{from};
				}
			})
		});
		return fields;
	}
	
	static function export(f:Field, ct:ComplexType, code:StringBuf,from:Array<Expr>, c:Bool):Void{
		var tag = f.name;
		var lt = '"  <$tag>"';
		var rt = '"</$tag>\n"';
		if(c){
			lt = '"  <$tag><![CDATA["';
			rt = '"]]></$tag>\n"';
		}
		switch (ct) {
			case TPath(p): p;
				switch (p.name) {
					case "Bool" , "Int", "Float", "String":
						code.add('$lt + $tag + $rt + ');
						
					//case "Array":
					//	code.add('($tag != null ? [ for(v in $tag) $lt + v +$rt].join("") + "\n" : "" ) +');;
					default:	
				}
				switch(p.name){
					case "Bool": from.push(macro $i{tag} = fa.node.resolve($v{tag}).innerData == "true");
					case "Int": from.push(macro $i{tag} = Std.parseInt(fa.node.resolve($v{tag}).innerData));
					case "Float": from.push(macro $i{tag} = Std.parseFloat(fa.node.resolve($v{tag}).innerData));
					case "String": from.push(macro $i{tag} = fa.node.resolve($v{tag}).innerData);
					default:
				}
			default:
		}
	}
	#end
}