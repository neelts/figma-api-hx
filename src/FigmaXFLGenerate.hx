package ;
import figma.FigmaAPI;
import figma.FigmaAPI;
import haxe.Template;

using Figma;
using FigmaXFLGenerate;

class FigmaXFLGenerate {
	
	private static inline var MAIN:String = "Main";
	
	public function new():Void {}

	public var filename:String;
	
	public var width:Int;
	public var height:Int;
	public var backgroundColor:String;
	
	public var symbols:Array<Symbol>;
	public var timelines:Array<Timeline>;

	public function execute(content:Document, xflRoot:String) {
		parse(content);
		'$xflRoot/$filename/DOMDocument.xmlt'.save(
			new Template('$xflRoot/template/DOMDocument.xmlt'.load()).execute(this, this)
		);
	}

	private function parse(content:Document):Void {
		
		filename = content.name;
		timelines = [];
		
		for (node in content.document.children) {
			if (node.type == NodeType.Canvas) {
				var canvas:CanvasNode = cast node;
				var timeline:Timeline = { layers:[], name:canvas.name };
				for (node in canvas.children) {
					if (node.type == NodeType.Frame) {
						var frameNode:FrameNode = cast node;
						if (frameNode.name == MAIN) setMain(cast frameNode);
						var frame:Frame = { elements:[] };
						var layer:Layer = { frames:[frame], name:frameNode.name };
						for (node in frameNode.children) {
							switch (node.type) {
								case NodeType.Component, NodeType.Instance: {
									if (node.type == NodeType.Component) addLibraryItem(cast node);
									frame.elements.push({ type:ElementType.SymbolInstance });
								}
								default:
							}
						}
						timeline.layers.push(layer);
					} else {
						trace("Error! Unframed elements not allowed!")
					}
				}
				timelines.push(timeline);
			}
		}
	}

	private function addLibraryItem(component:ComponentNode):Symbol {
		return symbols.push({ type:Include, href:'${component.name}.xfl', itemID:guid() });
	}

	public function setMain(frame:FrameNode):Void {
		width = frame.absoluteBoundingBox.width;
		height = frame.absoluteBoundingBox.height;
		backgroundColor = frame.backgroundColor;
	}

	public static function generate(content:Document, xflRoot:String):Void {
		new FigmaXFLGenerate().execute(content, xflRoot);
	}

	private static function guid():String {
		var result = "";
		for (j in 0...16) {
			if (j == 8) result += "-";
			result += StringTools.hex(Math.floor(Math.random() * 16));
		}
		return result;
	}
}

typedef Symbol = {
	var type:SymbolType;
	var href:String;
	var itemID:String;
}

@:enum abstract SymbolType(String) {
	var Include = "Include";
}

typedef Include = {
	var href:String;
}

typedef Timeline = {
	var name:String;
	var layers:Array<Layer>;
}

typedef Layer = {
	var name:String;
	var frames:Array<Frame>;
}

typedef Frame = {
	var elements:Array<Element>;
}

typedef Element = {
	var type:ElementType;
}

@:enum abstract ElementType(String) {
	var SymbolInstance = "SymbolInstance";
}