package ;
import haxe.Json;
import figma.FigmaAPI;
import haxe.MainLoop;
import sys.io.File;

using Figma;
using haxe.Json;

class Figma {

	public static function main():Void {
		var figmaAPI:FigmaAPI = new FigmaAPI("token".load());
		figmaAPI.files("file".load(), function(r:Response<Document>) {
			'xfl/${r.data.name}.json'.save(Json.stringify(r.data));
			FigmaXFLGenerate.generate(r.data, "xfl");
		});

		MainLoop.addThread(keep);
		
		//FigmaXFL.update(cast "xfl/Test.json".load(), "xfl/Test");
		//FigmaXFLUpdate.update(cast "xfl/Test.json".load(), "xfl/Test");

		//FigmaXFLGenerate.generate("xfl/Test2.json".load().parse(), "xfl");
	}

	public static inline function load(file:String):String return File.getContent(file);
	public static inline function save(file:String, content:String):Void File.saveContent(file, content);

	private static function keep():Void while (true) Sys.sleep(1);
}