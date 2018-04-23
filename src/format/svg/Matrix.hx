package format.svg;
class Matrix {

	public var a:Float;
	public var b:Float;
	public var c:Float;
	public var d:Float;
	public var tx:Float;
	public var ty:Float;

	public function new(a:Float = 1, b:Float = 0, c:Float = 0, d:Float = 1, tx:Float = 0, ty:Float = 0) {
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;
	}

	public function translate(dx:Float, dy:Float):Void {
		tx += dx;
		ty += dy;
	}

	public function scale(sx:Float, sy:Float):Void {
		a *= sx;
		b *= sy;
		c *= sx;
		d *= sy;
		tx *= sx;
		ty *= sy;
	}

	public function rotate(theta:Float):Void {
		var cos = Math.cos(theta);
		var sin = Math.sin(theta);
		var a1 = a * cos - b * sin;
		b = a * sin + b * cos;
		a = a1;
		var c1 = c * cos - d * sin;
		d = c * sin + d * cos;
		c = c1;
		var tx1 = tx * cos - ty * sin;
		ty = tx * sin + ty * cos;
		tx = tx1;
	}

	public function concat(m:Matrix):Void {
		var a1 = a * m.a + b * m.c;
		b = a * m.b + b * m.d;
		a = a1;
		var c1 = c * m.a + d * m.c;
		d = c * m.b + d * m.d;
		c = c1;
		var tx1 = tx * m.a + ty * m.c + m.tx;
		ty = tx * m.b + ty * m.d + m.ty;
		tx = tx1;
	}

	public function createGradientBox(width:Float, height:Float, rotation:Float = 0, tx:Float = 0, ty:Float = 0):Void {
		a = width / 1638.4;
		d = height / 1638.4;
		if (rotation != 0) {
			var cos = Math.cos(rotation);
			var sin = Math.sin(rotation);
			b = sin * d;
			c = -sin * a;
			a *= cos;
			d *= cos;
		} else {
			b = 0;
			c = 0;
		}
		this.tx = tx + width / 2;
		this.ty = ty + height / 2;
	}

	public function clone():Matrix {
		return new Matrix(a, b, c, d, tx, ty);
	}
}
