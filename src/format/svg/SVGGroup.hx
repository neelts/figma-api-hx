package format.svg;

class SVGGroup {

	public function new() {
		name = "";
		children = [];
	}

	public function hasGroup(inName:String) { return findGroup(inName) != null; }

	public function findGroup(inName:String):SVGGroup {
		#if idea
		var group:SVGGroup;
		#end
		for (child in children)
			switch(child) {
				case DisplayGroup(group):
					if (group.name == inName) return group;
					var inGroup:SVGGroup = group.findGroup(inName);
					if (inGroup != null) return inGroup;
				default:
			}
		return null;
	}

	public var name:String;
	public var children:Array<DisplayElement>;
}

enum DisplayElement {
	DisplayPath(path:Path);
	DisplayGroup(group:SVGGroup);
	DisplayText(text:Text);
}

typedef DisplayElements = Array<DisplayElement>;
