package ;
import figma.FigmaAPI;
import haxe.MainLoop;
import sys.io.File;

using Figma;

class Figma {

	public static function main():Void {
		var figmaAPI:FigmaAPI = new FigmaAPI("token".load());
		figmaAPI.files("file".load(), function(r:Response<Document>) {
			trace(r.data.name);
			trace(r.data.lastModified);
			var document:DocumentNode = r.data.document;
			for (node in document.children) trace(node.type);
		});

		MainLoop.addThread(keep);
	}

	private static inline function load(file:String):String return File.getContent(file);
	private static inline function save(file:String, content:String):Void File.saveContent(file, content);

	private static function keep():Void while (true) Sys.sleep(1);
}