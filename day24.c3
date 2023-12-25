/*
 * Advent of Code 2023 day 24
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;
import std::collections::map;

fn void main()
{
	io::printn("Advent of code, day 24.");
	@pool()
	{
		HailstoneList list = load_hailstones();
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Collisions part 1: %d - completed in %s", part1(list), c.mark());
		io::printfn("* Collisions part 2: %d - completed in %s", part2(list), c.mark());
	};
}

struct Hailstone
{
	double[<3>] pos;
	double[<3>] velocity;
}

def HailstoneList = List(<Hailstone>);

fn double[<3>] parse_vector(String line)
{
	String[] parts = line.tsplit(", ");
	return double[<3>]{ parts[0].to_double(), parts[1].to_double(), parts[2].to_double() }!!;
}

fn HailstoneList load_hailstones()
{
	File f = file::open("day24.txt", "rb")!!;
	defer (void)f.close();

	// Load all hailstones.
	HailstoneList list;
	list.init_temp();

    while (try line = io::treadline(&f))
    {
		String[] parts = line.tsplit(" @ ");
		list.append({ parse_vector(parts[0]), parse_vector(parts[1] )});
    }
    return list;
}

// Find the intersection point of two hailstone paths.
fn double[<3>]! Hailstone.collides_2d(&self, Hailstone* other)
{
	// Solve
	// p1 + v1 * s = p2 + v2 * t for xy
	double[<2>] v1 = self.velocity.xy;
	double[<2>] v2 = other.velocity.xy;
	double[<2>] p1 = self.pos.xy;
    double[<2>] p2 = other.pos.xy;
    double det = v1.x * v2.y - v1.y * v2.x;

    // No determinant - parallel
	if (det == 0) return SearchResult.MISSING?;
	double intersect = (p2.x * v2.y + p1.y * v2.x - p2.y * v2.x - p1.x * v2.y) / det;

	// Negative intersection, happened t < 0
	if (intersect < 0) return SearchResult.MISSING?;

	// Calculate the intersection point.
	return self.pos + intersect * self.velocity;
}

// Find the intersection, but require it is an integral
// time
fn long! intersect_integral(Vec2 p1, Vec2 v1, Vec2 p2, Vec2 v2)
{
	// Convert
	long[<2>] v1i = (long[<2>])v1;
	long[<2>] v2i = (long[<2>])v2;
	long[<2>] p1i = (long[<2>])p1;
    long[<2>] p2i = (long[<2>])p2;
    // Check determinant.
    long det = v1i.x * v2i.y - v1i.y * v2i.x;
	if (det == 0) return SearchResult.MISSING?;
	long i = p2i.x * v2i.y + p1i.y * v2i.x - p2i.y * v2i.x - p1i.x * v2i.y;
	// Is it divisible by the determinant?
	if (i % det != 0) return SearchResult.MISSING?;
	i /= det;
	// Is it t < 0?
	if (i < 0) return SearchResult.MISSING?;
	// Ok, just return t, not the intersection point.
	return i;
}

fn int part1(HailstoneList list)
{
	const double LIMIT_LOW = 200000000000000;
	const double LIMIT_HIGH = 400000000000000;

	int found = 0;
	foreach (i, &stone : list)
	{
		foreach (&other : list.array_view()[(i + 1)..])
		{
			// Cross reference each stone, if they collide in the range.
			if (try v = stone.collides_2d(other))
			{
				// .. then we found it.
				if (v.x >= LIMIT_LOW && v.x <= LIMIT_HIGH && v.y >= LIMIT_LOW && v.y <= LIMIT_HIGH)
				{
					found++;
				}
			}
		}
	}
	return found;
}

fn long part2(HailstoneList list)
{
	int found = 0;
	const long RANGE = 500;
	// Given p = start point and v is the velocity of the rock,
	// this holds (a, b is the first stone, c, d is the second).
	// 1. p = a + (b - v) * t
	// 2. p = c + (d - v) * s
	// 3. p = e + (f - v) * w
	// =>
	// Find a + (b - v) * t = c + (d - v) * s
	// and c + (d - v) * s = e + (f - v) * w
	// Then we can verify that s is the same for both.
	Vec3 a = list[0].pos;
	Vec3 b = list[0].velocity;
	Vec3 c = list[1].pos;
	Vec3 d = list[1].velocity;
	Vec3 e = list[2].pos;
	Vec3 f = list[2].velocity;
	// We brute force a starting xy velocity.
	for (long x = -RANGE; x <= RANGE; x++)
	{
		for (long y = -RANGE; y <= RANGE; y++)
		{
			Vec2 b_v = b.xy - { x, y };
			Vec2 d_v = d.xy - { x, y };

			// We solve s
			long! s = intersect_integral(c.xy, d_v, a.xy, b_v);

			// None found? Continue.
			if (catch s) continue;

			// We now solve s using the second equation.
			Vec2 f_v = f.xy - { x, y };
			long! s2 = intersect_integral(c.xy, d_v, e.xy, f_v);
			if (catch s2) continue;

			// Do they match for this x, y?
			if (s != s2) continue;

			// Calculate w
			long w = intersect_integral(e.xy, f_v, c.xy, d_v)!!;

			// We can now get our z velocity using this:
			//
			// s * d_v.z + c.z = w * f_v.z + e.z
			// =>
			// z = (w * f.z + e.z - s * d.z - c.z) / (w - s)
			double z = (w * f.z + e.z - s * d.z - c.z) / (double)(w - s);

			// To get the actual point, use:
			// p = c + (d - v) * s
            Vec3 p = c + (d - { x, y, z }) * s;
            return (long)p.sum();
		}
	}
	assert(false, "No solution reached :(");
}

