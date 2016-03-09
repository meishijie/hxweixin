package utils;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.TypeTools;

class Macors{
	
	/**
	用于获得所有 @:enum abstract 的所有字段 
	*/
	static public function allEnumVars(){

		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
	
		var ret = [];
		for(f in fields){
			switch (f.kind) {
				case FVar(_,e):
					ret.push(macro $i{f.name});
				default:
			}
		}
		
		var r = {expr: EArrayDecl(ret), pos:pos};
		
		fields.push({
			name: "all",
			doc: "get all fileds",
			access: [AStatic, APublic, AInline],
			pos: pos,
			kind: FFun({
			ret: null,	// 让编译器自已推断
				args:[],
				expr: macro return $r
			})
		});
		return fields;
	}
}