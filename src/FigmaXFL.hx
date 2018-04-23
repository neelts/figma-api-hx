package ;
import tink.CoreApi.Outcome;
import tink.xml.Structure;
import figma.FigmaAPI.Document;
import sys.io.File;
class FigmaXFL {

	private static inline var DOM:String = "DOMDocument.xml";

	public static function update(content:Document, xflRoot:String):Void {
		var structure:Structure<DOMDocument> = new Structure<DOMDocument>();
		var domParse = structure.read(File.getContent(xflRoot + "/" + DOM));
		trace(domParse);
		#if idea
		var dom:DOMDocument; 
		var e:String; 
		#end
		switch (domParse) {
			case Outcome.Success(dom): updateDOM(content, dom);
			case Outcome.Failure(e): trace(e);
		}
		/*for (symbol in dom.symbols.symbols) {
			trace(symbol.href);
		}*/
		
		//structure.write();
	}

	private static function updateDOM(content:Document, dom:DOMDocument):Void {
		
		for (symbol in dom.symbols.all) {
			trace(symbol.href);
		}
		
		for (timeline in dom.timelines.all) {
			for (layer in timeline.layers.all) {
				for (frame in layer.frames.all) {
					for (symbolInstance in frame.elements.symbolInstances) {
						trace(symbolInstance.libraryItemName);
					}
				}
			}
		}
	}

}

typedef DOMDocument = {
	var symbols:DOMDocumentSymbols;
	var timelines:DOMDocumentTimelines;
}

typedef DOMDocumentSymbols = {
	@:list('Include') var all:Array<Include>;
}

typedef DOMDocumentTimelines = {
	@:list('DOMTimeline') var all:Array<DOMTimeline>;
}

typedef Include = {
	@:attr var href:String;
	@:attr var itemID:String; 
}

typedef DOMTimeline = {
	var layers:DOMTimelineLayers;
}

typedef DOMTimelineLayers = {
	@:list('DOMLayer') var all:Array<DOMLayer>; 
}

typedef DOMLayer = {
	@:attr var name:String;
	var frames:DOMLayerFrames;
}

typedef DOMLayerFrames = {
	@:list('DOMFrame') var all:Array<DOMFrame>; 
}

typedef DOMFrame = {
	@:attr var index:Int;
	var elements:DOMFrameElements;
}

typedef DOMFrameElements = {
	@:list('DOMSymbolInstance') var symbolInstances:Array<DOMSymbolInstance>; 
}

typedef DOMSymbolInstance = {
	@:attr var libraryItemName:String;
}