package format.svg;
class Rectangle {

	public var right(get, set):Float;

	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;

	public function new(x:Float, y:Float, width:Float, height:Float) {
		this.x = x;
		this.y = x;
		this.width = width;
		this.height = height;
	}

	private function get_right():Float { return x + width; }
	private function set_right(r:Float):Float { width = r - x; return r; }
}