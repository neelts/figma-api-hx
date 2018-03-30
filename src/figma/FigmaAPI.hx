package figma;

import haxe.Http;
import haxe.Json;
import haxe.macro.Context;
import haxe.macro.Expr.ExprOf;
import haxe.macro.Expr;
import neko.vm.Thread;
import Reflect;
import String;

class FigmaAPI {

	private static inline var API:String = "https://api.figma.com/v1";

	private static inline var MIME_JSON:String = "application/json";
	private static inline var HEADER_CONTENT_TYPE:String = "Content-Type";
	private static inline var HEADER_TOKEN:String = "X-Figma-Token";

	private var token:String;

	public function new(token:String):Void {
		this.token = token;
	}

	public function files(key:String, ?onComplete:Response<Document> -> Void):Void call(methodName(), key, null, onComplete);
	//public function images(key:String, params:ImagesParams, ?onComplete:Response<Dynamic> -> Void):Void call(methodName(), key, null, onComplete);

	private function call<P, T, R:Response<T>>(method:String, key:String, params:P = null, onComplete:R -> Void = null):Void {
		var thread:Thread = Thread.create(callAsync);
		var message:Call<P, R> = { method:method, key:key, params:params, onComplete:onComplete };
		thread.sendMessage(message);
	}

	private function callAsync<P, T, R:Response<T>>():Void {
		var message:Call<P, Response<T>> = Thread.readMessage(true);
		var http:Http = new Http('${API}/${message.method}/${message.key}');
		if (message.params != null) for (param in Reflect.fields(message.params)) http.addParameter(param, Reflect.field(message.params, param));
		http.addHeader(HEADER_CONTENT_TYPE, MIME_JSON);
		http.addHeader(HEADER_TOKEN, token);
		if (message.onComplete != null) http.onData = http.onError = function(_):Void message.onComplete(Json.parse(http.responseData));
		http.request();
	}

	#if idea var $v:Expr; #end

	macro public static function methodName():ExprOf<String> {
		return macro $v{Context.getLocalMethod()};
	}
}

typedef Call<P, R> = {

	var method:String;
	var key:String;
	var params:P;
	var onComplete:R -> Void;

}

typedef Response<T> = {

}

typedef Document = {

	var schemaVersion:Int;
    var name:String;
    var components:Map<String, Component>;
    var lastModified:String;
    var document:DocumentNode;
    var thumbnailUrl:String;

}

/**
*
*	Nodes
*
**/

typedef Node = {

	var id:String;
	var name:String;
	var visible:Bool;
	var type:NodeType;

}

@:enum abstract NodeType(String) {

	var Document = "DOCUMENT";
	var Canvas = "CANVAS";
	var Frame = "FRAME";
	var Group = "GROUP";
	var Vector = "VECTOR";
	var Boolean = "BOOLEAN";
	var Star = "STAR";
	var Line = "LINE";
	var Ellipse = "ELLIPSE";
	var RegularPolygon = "REGULAR_POLYGON";
	var Rectangle = "RECTANGLE";
	var Text = "TEXT";
	var Slice = "SLICE";
	var Component = "COMPONENT";
	var Instance = "INSTANCE";
	
}

typedef DocumentNode = { > Node,

	var children:Array<Node>;
	
}

typedef CanvasNode = { > Node,

	var children:Array<Node>;
	var backgroundColor:Color;
	var exportSettings:Array<ExportSetting>;
	
}

typedef FrameNode = { > Node,

	var children:Array<Node>;
	var backgroundColor:Color;
	var exportSettings:Array<ExportSetting>;
	var blendMode:BlendMode;
	var preserveRatio:Bool;
	var constraints:LayoutConstraint;
	var transitionNodeID:String;
	var opacity:Float;
	var absoluteBoundingBox:Rectangle;
	var clipsContent:Bool;
	var layoutGrids:Array<LayoutGrid>;
	var effects:Array<Effect>;
	var isMask:Bool;
	
}

typedef GroupNode = { > FrameNode,

	
}

typedef VectorNode = { > Node,

	var exportSettings:Array<ExportSetting>;
	var blendMode:BlendMode;
	var preserveRatio:Bool;
	var constraints:LayoutConstraint;
	var transitionNodeID:String;
	var opacity:Float;
	var absoluteBoundingBox:Rectangle;
	var effects:Array<Effect>;
	var isMask:Bool;
	var fills:Array<Paint>;
	var strokes:Array<Paint>;
	var strokeWeight:Float;
	var strokeAlign:VectorNodeStrokeAlign;
	
}

typedef BooleanNode = { > VectorNode,

	var children:Array<Node>;
	
}

typedef StarNode = { > VectorNode,

	
}

typedef LineNode = { > VectorNode,

	
}

typedef EllipseNode = { > VectorNode,

	
}

typedef RegularPolygonNode = { > VectorNode,

	
}

typedef RectangleNode = { > VectorNode,

	var cornerRadius:Float;
	
}

typedef TextNode = { > VectorNode,

	var characters:String;
	var style:TypeStyle;
	var characterStyleOverrides:Array<Float>;
	var styleOverrideTable:Map<Float, TypeStyle>;
	
}

typedef SliceNode = { > Node,

	var exportSettings:Array<ExportSetting>;
	var absoluteBoundingBox:Rectangle;
	
}

typedef ComponentNode = { > FrameNode,

	
}

typedef InstanceNode = { > FrameNode,

	var componentId:String;
	
}

/**
*
*	Types
*
**/

typedef Color = {

	var r:Float;
	var g:Float;
	var b:Float;
	var a:Float;
	
}

typedef ExportSetting = {

	var suffix:String;
	var format:ExportSettingFormat;
	var constraint:Constraint;
	
}

typedef Constraint = {

	var type:ConstraintType;
	var value:Float;
	
}

typedef Rectangle = {

	var x:Float;
	var y:Float;
	var width:Float;
	var height:Float;
	
}

typedef LayoutConstraint = {

	var vertical:LayoutConstraintVertical;
	var horizontal:LayoutConstraintHorizontal;
	
}

typedef LayoutGrid = {

	var pattern:LayoutGridPattern;
	var sectionSize:Float;
	var visible:Bool;
	var color:Color;
	var alignment:LayoutGridAlignment;
	var gutterSize:Float;
	var offset:Float;
	var count:Float;
	
}

typedef Effect = {

	var type:EffectType;
	var visible:Bool;
	var radius:Float;
	var color:Color;
	var blendMode:BlendMode;
	var offset:Vector;
	
}

typedef Paint = {

	var type:PaintType;
	var visible:Bool;
	var opacity:Float;
	var color:Color;
	var gradientHandlePositions:Array<Vector>;
	var gradientStops:Array<ColorStop>;
	var scaleMode:PaintScaleMode;
	
}

typedef Vector = {

	var x:Float;
	var y:Float;
	
}

typedef FrameOffset = {

	var node_id:String;
	var node_offset:Vector;
	
}

typedef ColorStop = {

	var position:Float;
	var color:Color;
	
}

typedef TypeStyle = {

	var fontFamily:String;
	var fontPostScriptName:String;
	var italic:Bool;
	var fontWeight:Float;
	var fontSize:Float;
	var textAlignHorizontal:TypeStyleTextAlignHorizontal;
	var textAlignVertical:TypeStyleTextAlignVertical;
	var letterSpacing:Float;
	var fills:Array<Paint>;
	var lineHeightPx:Float;
	var lineHeightPercent:Float;
	
}

typedef Component = {

	var name:String;
	var description:String;
	
}

/**
*
*	Enums
*
**/

@:enum abstract LayoutConstraintVertical(String) {

	var Top = "TOP";
    var Bottom = "BOTTOM";
    var Center = "CENTER";
    var TopBottom = "TOP_BOTTOM";
    var Scale = "SCALE";
    
}

@:enum abstract PaintType(String) {

	var Solid = "SOLID";
    var GradientLinear = "GRADIENT_LINEAR";
    var GradientRadial = "GRADIENT_RADIAL";
    var GradientAngular = "GRADIENT_ANGULAR";
    var GradientDiamond = "GRADIENT_DIAMOND";
    var Image = "IMAGE";
    var Emoji = "EMOJI";
    
}

@:enum abstract TypeStyleTextAlignVertical(String) {

	var Top = "TOP";
    var Center = "CENTER";
    var Bottom = "BOTTOM";
    
}

@:enum abstract LayoutConstraintHorizontal(String) {

	var Left = "LEFT";
    var Right = "RIGHT";
    var Center = "CENTER";
    var LeftRight = "LEFT_RIGHT";
    var Scale = "SCALE";
    
}

@:enum abstract VectorNodeStrokeAlign(String) {

	var Inside = "INSIDE";
    var Outside = "OUTSIDE";
    var Center = "CENTER";
    
}

@:enum abstract ExportSettingFormat(String) {

	var Jpg = "JPG";
    var Png = "PNG";
    var Svg = "SVG";
    
}

@:enum abstract BlendMode(String) {

	var PassThrough = "PASS_THROUGH";
    var Normal = "NORMAL";
    var Darken = "DARKEN";
    var Multiply = "MULTIPLY";
    var LinearBurn = "LINEAR_BURN";
    var ColorBurn = "COLOR_BURN";
    var Lighten = "LIGHTEN";
    var Screen = "SCREEN";
    var LinearDodge = "LINEAR_DODGE";
    var ColorDodge = "COLOR_DODGE";
    var Overlay = "OVERLAY";
    var SoftLight = "SOFT_LIGHT";
    var HardLight = "HARD_LIGHT";
    var Difference = "DIFFERENCE";
    var Exclusion = "EXCLUSION";
    var Hue = "HUE";
    var Saturation = "SATURATION";
    var Color = "COLOR";
    var Luminosity = "LUMINOSITY";
    
}

@:enum abstract EffectType(String) {

	var InnerShadow = "INNER_SHADOW";
    var DropShadow = "DROP_SHADOW";
    var LayerBlur = "LAYER_BLUR";
    var BackgroundBlur = "BACKGROUND_BLUR";
    
}

@:enum abstract ConstraintType(String) {

	var Scale = "SCALE";
    var Width = "WIDTH";
    var Height = "HEIGHT";
    
}

@:enum abstract LayoutGridAlignment(String) {

	var Min = "MIN";
    var Max = "MAX";
    var Center = "CENTER";
    
}

@:enum abstract TypeStyleTextAlignHorizontal(String) {

	var Left = "LEFT";
    var Right = "RIGHT";
    var Center = "CENTER";
    var Justified = "JUSTIFIED";
    
}

@:enum abstract LayoutGridPattern(String) {

	var Columns = "COLUMNS";
    var Rows = "ROWS";
    var Grid = "GRID";
    
}

@:enum abstract PaintScaleMode(String) {

	var Fill = "FILL";
    var Fit = "FIT";
    var Tile = "TILE";
    var Stretch = "STRETCH";
    
}
