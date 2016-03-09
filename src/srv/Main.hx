package srv;

import neko.Web;

class Main{
	public static function main(){
		Web.cacheModule(run);
		run();
	}
	static function run(){
		trace("It Works!");
	}
}