package ;
import haxe.Json;
import figma.FigmaAPI;
import haxe.MainLoop;
import sys.io.File;

using Figma;

class Figma {

	public static function main():Void {
		/*var figmaAPI:FigmaAPI = new FigmaAPI("token".load());
		figmaAPI.files("file".load(), function(r:Response<Document>) {
			"xfl/Test2.json".save(Json.stringify(r.data));
			if (r.data != null) {
				trace(r.data.name);
				trace(r.data.lastModified);
				var document:DocumentNode = r.data.document;
				for (node in document.children) trace(node.type);
			} else {
				trace(r.error);
				trace(r.error.err);
				trace(r.error.status);
			}
		});

		MainLoop.addThread(keep);*/
		
		//FigmaXFL.update(cast "xfl/Test.json".load(), "xfl/Test");
		//FigmaXFLUpdate.update(cast "xfl/Test.json".load(), "xfl/Test");
		
		FigmaXFLGenerate.generate(cast "xfl/Test2.json".load(), "xfl");
	}

	public static inline function load(file:String):String return File.getContent(file);
	public static inline function save(file:String, content:String):Void File.saveContent(file, content);

	private static function keep():Void while (true) Sys.sleep(1);
}