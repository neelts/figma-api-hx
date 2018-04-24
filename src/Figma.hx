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
		var fileKey:String = "file".load();
		figmaAPI.files(fileKey, function(r:Response<Document>) {
			'${r.data.name}.json'.save(Json.stringify(r.data));
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
			Sys.exit(0);
		});

		MainLoop.addThread(keep);
	}

	public static inline function load(file:String):String return File.getContent(file);
	public static inline function save(file:String, content:String):Void File.saveContent(file, content);

	private static function keep():Void while (true) Sys.sleep(1);
}