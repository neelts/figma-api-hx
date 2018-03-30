package figma;
import haxe.Template;
import Array;
import haxe.Http;
import haxe.Json;
import sys.io.File;

using StringTools;
using figma.FigmaAPIExtract;

class FigmaAPIExtract {

	private static inline var url:String = 'https://www.figma.com';
	private static inline var src:String = 'src/figma';

	private static var jsPath:EReg = ~/(\/figbuild\/symlinks\/developers.+\.js)/;

	private static var nl:EReg = ~/[\r\n]+/g;
	private static var sqt:EReg = ~/'+/g;
	private static var dqt:EReg = ~/"+/g;
	private static var cln:EReg = ~/:+/g;
	private static var def:EReg = ~/"default"/g;
	private static var props:EReg = ~/([a-zA-Z0-9]*):/g;
	private static var ext:EReg = ~/"span",\{className=l\.literal\},"([A-Z_]+)"/g;

	private static var map:EReg = ~/Map<(.+),(.+)>/;
	private static var array:EReg = ~/(.+)\[\]/;

	private static var parts:Parts;
	private static var api:API;

	public static function main():Void {
		trace("started");
		parts = { nodeProps: null, fileFormatTypes: null, apiTypes: null, webhookTypes:null };
		load();
	}

	public static function load():Void {
		var html:Http = new Http('$url/developers/docs');
		html.request();
		if (jsPath.match(html.responseData)) {
			var js:Http = new Http('${url}${jsPath.first()}');
			js.request();
			var data:String = nl.replace(js.responseData, '');
			for (f in Reflect.fields(parts)) Reflect.setField(parts, f, get(data, data.indexOf('$f=') + f.length + 1));
			generate();
		}
	}

	private static function generate():Void {

		api = { nodes:[], types:[] };

		for (node in parts.nodeProps) {
			var type:NodeTypeDef = { name:node.name.getNodeName(), type:node.name, id:node.name.getNodeName(false), vars:[] };
			for (prop in node.props) {
				if (type.extend == null && prop.div != null && prop.name == null) type.extend = prop.div.getExtends();
				if (prop.name != null) type.vars.push({ name:prop.name, type:prop.type.getType() });
			}
			if (type.extend == null) type.extend = "Node";
			api.nodes.push(type);
		}

		for (part in parts.fileFormatTypes) {
			var type:TypeDef = { name:part.name, vars:[] };
			for (prop in part.props) if (prop.name != null) type.vars.push({ name:prop.name, type:prop.type.getType() });
			api.types.push(type);
		}

		File.saveContent('$src/FigmaAPI.hx', new Template(File.getContent('$src/FigmaAPI.hxt')).execute(api));
	}

	private static function getType(type:String):String {
		return switch (type) {
			case 'Boolean': 'Bool';
			case 'Number': 'Float';
			case type if (map.match(type)): 'Map<${getType(map.first())}, ${getType(map.second())}>';
			case type if (array.match(type)): 'Array<${getType(array.first())}>';
			default: type;
		}
	}

	private static function getNodeName(name:String, node:Bool = true):String {
		var r:String = "";
		for (p in name.split("_")) r += p.charAt(0) + p.substring(1).toLowerCase();
		if (node) r += "Node";
		return r;
	}

	private static function getExtends(div:String):String {
		return ext.match(div) ? ext.matched(1).getNodeName() : null;
	}

	private static function get(data:String, from:Int):Dynamic {
		var index:Int = from;
		var open:Int = 0;
		while (from < data.length) {
			switch (data.charAt(index)) {
				case '[': open++;
				case ']': if (--open == 0) break;
				default:
			}
			index++;
		}
		var r:String = props.replace(parse(data.substring(from, index + 1)), '"$1":');
		r = def.replace(r, '"def"');
		return Json.parse(r);
	}

	private static function parse(data:String):String {
		var index:Int = 0;
		var open:Int = 0;
		var curr:String;
		var prev:String = null;
		while (index < data.length) {
			curr = data.charAt(index);
			switch (prev) {
				case ':': switch (curr) {
					case '[', '{', '"':
					default: {
						var sub:Int = index;
						var subOpen:Int = 0;
						while (sub < data.length) {
							switch (data.charAt(sub)) {
								case '(': subOpen++;
								case ')': if (--subOpen == 0) break;
							}
							sub++;
						}
						var subPart:String = data.substring(index, sub + 1);
						subPart = cln.replace(subPart, '=');
						subPart = dqt.replace(subPart, '\\"');
						data = data.substring(0, index) + '"$subPart"' + data.substring(sub + 1);
						index += subPart.length;
					}
				}
			}
			prev = curr;
			index++;
		}
		return data;
	}

	public static inline function first(e:EReg):String {
		return e.matched(1);
	}

	public static inline function second(e:EReg):String {
		return e.matched(2);
	}
}

private typedef Parts = {
	var nodeProps:Array<Part>;
	var fileFormatTypes:Array<Part>;
	var apiTypes:Array<Part>;
	var webhookTypes:Array<Part>;
}

private typedef Part = {
	var name:String;
	var desc:String;
	var props:Array<Prop>;
}

private typedef Prop = {
	var name:String;
	var type:String;
	var content:String;
	@:optional var def:String;
	@:optional var div:String;
}

private typedef API = {
	var nodes:Array<NodeTypeDef>;
	var types:Array<TypeDef>;
}

private typedef TypeDef = {
	var name:String;
	var vars:Array<TypeDefVar>;
}

private typedef TypeDefVar = {
	var name:String;
	@:optional var optional:Bool;
	var type:String;
}

private typedef NodeTypeDef = { > TypeDef,
	var id:String;
	var type:String;
	@:optional var extend:String;
}