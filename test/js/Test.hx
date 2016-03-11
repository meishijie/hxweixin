package;


import haxe.Timer;
import utils.Msg;
import utils.GenUid;
import js.Wx;

class Test{

	public static function main(){
		testGenUid();
		testExternWx();

	}
	
	
	static function testExternWx(){
	}
	
	static function testGenUid(){
		for(i in 0...2){
			trace("random id: " + GenUid.v4() + " - short: " + GenUid.token());
		}
	}
	

}