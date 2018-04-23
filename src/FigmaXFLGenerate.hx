package ;
import figma.FigmaAPI.NodeType;
import figma.FigmaAPI;
import haxe.Template;

using Figma;
using FigmaXFLGenerate;
using sys.FileSystem;
using haxe.xml.Printer;
using Xml;
using StringTools;

class FigmaXFLGenerate {

	private static inline var MAIN:String = "Main";

	public function new():Void {}

	private var xflRoot:String;
	private var xflPath:String;
	private var libraryPath:String;

	public var filename:String;

	public var width:Float;
	public var height:Float;
	public var backgroundColor:String;

	public var symbols:Array<Symbol>;
	public var timelines:Array<Timeline>;

	private var symbolsMap:Map<String, Symbol>;

	public function execute(content:Document, xflRoot:String) {

		this.xflRoot = xflRoot;

		filename = content.name;

		xflPath = '$xflRoot/$filename';
		libraryPath = '$xflPath/LIBRARY';

		var xfl:String = '$xflPath/$filename.xfl';
		if (!xfl.exists()) xfl.save('$xflRoot/template/Name.xfl'.load());

		if (!xflPath.exists()) xflPath.createDirectory();
		if (!libraryPath.exists()) libraryPath.createDirectory();

		parse(content);

		trace(timelines);

		'$xflPath/DOMDocument.xml'.save(
			new Template('$xflRoot/template/DOMDocument.xmlt'.load()).execute(this, this).pretty()
		);
	}

	private function parse(content:Document):Void {

		symbolsMap = new Map<String, Symbol>();

		symbols = [];
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
						getElements(frame, frameNode.children);
						timeline.layers.push(layer);
					} else {
						trace("Error! Unframed elements not allowed!");
					}
				}
				timelines.push(timeline);
			}
		}
	}

	private function getElements(frame:Frame, children:Array<Node>):Void {
		for (node in children) getElement(frame, node);
	}

	private function getElement(frame:Frame, node:Node):Void {
		var element:Element = switch (node.type) {
			case NodeType.Component, NodeType.Instance: {
				checkSymbol(cast node);
				var symbolElement:SymbolElement = { type:ElementType.SymbolInstance, libraryItemName:node.name };
				symbolElement;
			}
			case NodeType.Rectangle: {
				var rect:RectangleNode = cast node;
				var rectangle:RectangleElement = { type:ElementType.Rectangle, width:rect.absoluteBoundingBox.width, height:rect.absoluteBoundingBox.height };
				if (rect.fills.isNotEmpty()) rectangle.fill = rect.fills[0].color.hexColor();
				rectangle;
			}
			default: null;
		}
		if (element != null) {
			switch (node.type) {
				case NodeType.Component, NodeType.Instance, NodeType.Vector: {
					var vectorNode:FrameNode = cast node;
					if (vectorNode.absoluteBoundingBox.x != 0 || vectorNode.absoluteBoundingBox.y != 0) {
						element.matrix = { tx:vectorNode.absoluteBoundingBox.x, ty:vectorNode.absoluteBoundingBox.y };
					}
				}
				default:
			}
			frame.elements.push(element);
		}
	}

	private function getFills(fills:Array<Paint>):Array<ShapeFill> {
		var shapeFills:Array<ShapeFill> = [];
		var index:Int = 0;
		for (paint in fills) shapeFills.push({ index:index++, color:paint.color.hexColor() });
		return shapeFills;
	}

	private function checkSymbol(node:FrameNode):Symbol {
		return symbolsMap.exists(node.name) ? symbolsMap.get(node.name) : createSymbol(
			symbols.pushes(symbolsMap.sets(node.name, { type:SymbolType.Include, href:node.name, itemID:guid() })), node
		);
	}

	private function createSymbol(symbol:Symbol, frameNode:FrameNode):Symbol {

		var item:LibrarySymbol = { name:symbol.href, itemID:symbol.itemID, layers:[] };

		for (node in frameNode.children) {
			var frame:Frame = { elements:[] };
			var layer:Layer = { frames:[frame], name:frameNode.name };
			getElement(frame, node);
			item.layers.push(layer);
		}

		trace(item);

		'$libraryPath/${symbol.href}.xml'.save(
			new Template('$xflRoot/template/LIBRARY/Item.xmlt'.load()).execute(item, this).pretty()
		);
		return symbol;
	}

	public function setElements(resolve:String -> Dynamic, elements:Array<Element>):String {
		return new Template('$xflRoot/template/Elements.xmlt'.load()).execute({ elements:elements }, this).pretty();
	}

	public function setMain(frame:FrameNode):Void {
		width = frame.absoluteBoundingBox.width;
		height = frame.absoluteBoundingBox.height;
		backgroundColor = frame.backgroundColor.hexColor();
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
		return result.toLowerCase();
	}

	public static inline function sets<K, V>(map:Map<K, V>, key:K, value:V):V {
		map.set(key, value);
		return value;
	}

	public static inline function pushes<V>(array:Array<V>, value:V):V {
		array.push(value);
		return value;
	}

	public static inline function pretty(xml:String):String {
		return ~/>\s*</g.replace(xml, "><").parse().print(true);
	}

	public static inline function hexColor(c:Color):String {
		return '#${c.r.f2h()}${c.g.f2h()}${c.b.f2h()}';
	}

	public static inline function f2h(float:Float, base:Int = 255):String {
		return Std.int(float * base).hex();
	}

	public static inline function isNotEmpty<T>(array:Array<T>):Bool return array != null && array.length > 0;
}

typedef LibrarySymbol = {
	var name:String;
	var itemID:String;
	var layers:Array<Layer>;
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
	@:optional var matrix:{ tx:Float, ty:Float };
}

typedef SymbolElement = { > Element,
	var libraryItemName:String;
}

typedef ShapeElement = { > Element,
	var fills:Array<ShapeFill>;
	var edges:Array<ShapeEdge>;
}

typedef ShapeFill = {

}

typedef ShapeEdge = {

}

typedef RectangleElement = { > Element,
	var width:Float;
	var height:Float;
	@:optional var fill:String;
}

@:enum abstract ElementType(String) {
	var SymbolInstance = "SymbolInstance";
	var Shape = "Shape";
	var Rectangle = "Rectangle";
}