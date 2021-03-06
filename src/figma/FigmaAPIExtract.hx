package figma;

import haxe.ds.StringMap;
import haxe.Http;
import haxe.Json;
import haxe.Template;
import sys.io.File;

using StringTools;
using sys.io.File;
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
	private static var propsRemove:EReg = ~/(?:\s+)([a-zA-Z0-9]+):/g;
	private static var extend:EReg = ~/"span",\{className=l\.literal\},"([A-Z_]+)"/g;
	private static var enums:EReg = ~/"span",\{className=l\.string\},"([A-Z_]+)"/g;
	private static var isEnum:EReg = ~/enum/gi;

	private static var endpoints:EReg = ~/createElement\("div",\{id:"endpoints"\}/;
	private static var array:EReg = ~/(.+)\[\]/;

	private static var parts:Parts;
	private static var api:API;
	private static var apiEnums:Map<String, TypeDef>;

	public static function main():Void {
		trace("started");
		parts = { NodePropertiesTable: null, TypesTable: null, MutationsTable: null };
		load();
	}

	public static function load():Void {
		var html:Http = new Http('$url/developers/docs');
		html.request();
		if (jsPath.match(html.responseData)) {
			var js:Http = new Http('${url}${jsPath.first()}');
			js.request();

			//File.saveContent('figma.js', js.responseData);
			var data:String = nl.replace(js.responseData, '');

			var varsData = data.substr(data.indexOf("FilesDescription=function()"));
			var typesData = data.substr(data.indexOf("GlobalPropertiesTable=function()"));
			for (f in Reflect.fields(parts)) {
				var etype = new EReg('\\.$f=function\\(\\)\\{.+?(\\w)\\.map', 'g');
				if (etype.match(typesData)) {
					varsData = propsRemove.replace(varsData, '$1 =');
					Reflect.setField(parts, f, get(varsData, varsData.indexOf('${etype.first()}=[') + 2, f));
				}
			}

			//parts.endpoints = getEndpoints(data);

			generate();
		}
	}

	private static function generate():Void {

		api = { nodes:[], types:[], enums:[] };
		apiEnums = new StringMap<TypeDef>();
		
		for (node in parts.NodePropertiesTable) {
			var type:NodeTypeDef = { name:node.name.getName(), type:node.name, id:node.name.getName(false), vars:[] };
			for (prop in node.props) {
				if (type.extend == null && prop.div != null && prop.name == null) type.extend = prop.div.getExtends();
				if (prop.name != null) type.vars.push({
					name:prop.name, type:prop.type.getType(prop.div, type.name + prop.name.capital())
				});
			}
			if (type.extend == null) type.extend = "Node";
			api.nodes.push(type);
		}

		var types:StringMap<TypeDef> = new StringMap<TypeDef>();
		
		for (part in parts.TypesTable) {
			if (isEnum.match(part.desc)) {
				for (prop in part.props) addEnumType(prop.div, part.name);
			} else {
				var type:TypeDef = { name:part.name, vars:[] };
				for (prop in part.props) if (prop.name != null) type.vars.push({
					name:prop.name, type:prop.type.getType(prop.div, type.name + prop.name.capital())
				});
				types.set(part.name, type);
				api.types.push(type);
			}
		}

		for (node in api.nodes) {
			for (prop in node.vars) {
				var type = types.get(prop.type);
				if (type != null && type.vars.length == 1 && type.vars[0].name == "") {
					prop.type = type.vars[0].type;
					if (!type.isEmpty) type.isEmpty = true;
				}
			}
		}

		for (e in apiEnums) api.enums.push(e);

		File.saveContent('$src/FigmaAPI.hx', new Template(File.getContent('$src/FigmaAPI.hxt')).execute(api));
	}

	private static function getEndpoints(data:String):Dynamic {
		if (endpoints.match(data)) {
			var index:Int = endpoints.index();
			var sub:Int = index.getLast(data);
		}
		return null;
	}

	private static function getType(type:String, div:String = null, name:String = null):String {
		var map:EReg = ~/Map<(.+),(.+)>/;
		return switch (type) {
			case 'Boolean': 'Bool';
			case 'Number': 'Float';
			case type if (map.match(type)): 'Map<${getType(map.first())}, ${getType(map.second())}>';
			case type if (array.match(type)): 'Array<${getType(array.first())}>';
			default: {
				if (div != null && name != null && enums.match(div)) {
					addEnumType(div, name);
					name;
				} else type;
			}
		}
	}

	private static function addEnumType(s:String, name:String):Void {
		var e:TypeDef = apiEnums.get(name);
		if (e == null) e = { name:name, vars:[], isEnum:true };
		while (enums.match(s)) {
			var value:String = enums.first();
			e.vars.push({ name:value.getName(false), value:'"$value"' });
			s = enums.matchedRight();
		}
		if (!apiEnums.exists(name)) apiEnums.set(name, e);
	}

	private static function getName(name:String, node:Bool = true):String {
		var r:String = "";
		for (p in name.split("_")) r += p.lower();
		if (node) r += "Node";
		return r;
	}

	private static function getExtends(div:String):String {
		return extend.match(div) ? extend.first().getName() : null;
	}

	private static function get(data:String, from:Int, n:String):Dynamic {

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
		var curr:String;
		var prev:String = null;
		while (index < data.length) {
			curr = data.charAt(index);
			switch (prev) {
				case ':': switch (curr) {
					case '[', '{', '"':
					default: {
						var sub:Int = index.getLast(data);
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

	private static function getLast(sub:Int, data:String, l:String = '(', r:String = ')'):Int {
		var subOpen:Int = 0;
		while (sub < data.length) {
			if (data.charAt(sub) == l) subOpen++
			else if (data.charAt(sub) == r && --subOpen == 0) break;
			sub++;
		}
		return sub;
	}

	public static inline function index(e:EReg):Int {
		return e.matchedPos().pos + e.matchedPos().len;
	}

	public static inline function first(e:EReg):String {
		return e.matched(1);
	}

	public static inline function second(e:EReg):String {
		return e.matched(2);
	}

	public static function lower(s:String, l:Bool = true):String {
		return s.charAt(0) + s.substring(1).toLowerCase();
	}

	public static function capital(s:String, l:Bool = true):String {
		return s.charAt(0).toUpperCase() + s.substring(1);
	}
}

private typedef Parts = {
	var NodePropertiesTable:Array<Part>;
	var TypesTable:Array<Part>;
	var MutationsTable:Array<Part>;
	@:optional var endpoints:Dynamic;
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
	var enums:Array<TypeDef>;
}

private typedef TypeDef = {
	var name:String;
	var vars:Array<TypeDefVar>;
	@:optional var isEmpty:Bool;
	@:optional var isEnum:Bool;
}

private typedef TypeDefVar = {
	var name:String;
	@:optional var optional:Bool;
	@:optional var type:String;
	@:optional var value:String;
}

private typedef NodeTypeDef = { > TypeDef,
	var id:String;
	var type:String;
	@:optional var extend:String;
}