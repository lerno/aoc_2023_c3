/*
 * Advent of Code 2023 day 22
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;
import std::sort;

fn void main()
{
	io::printn("Advent of code, day 22.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Total part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Total part 2: %d - completed in %s", part2(), c.mark());
	};
}

struct Brick (Printable)
{
	int[<3>] start;
	int[<3>] end;
	int id;
	List(<Brick*>) supports;
	List(<Brick*>) supported_by;
	int color;
}

// Useful for debugging.
fn usz! Brick.to_format(&self, Formatter* f) @dynamic
{
	return f.printf("[%d: %s,%s]", self.id, self.start, self.end);
}

// Comparison for 'sort'
fn int Brick.compare_to(self, Brick* other)
{
	return compare_to(self.start.z, other.start.z);
}

// When looking for destroyed bricks, we use coloring,
fn bool Brick.has_no_uncolored_support(&self, int color)
{
	// If the brick is only supported by bricks that
	// are colored, then it will fall...
	foreach (b : self.supported_by)
	{
		if (b.color != color) return false;
	}
	return true;
}

// Check if a brick will collide with another
fn int Brick.collide(&self, Brick* other)
{
	// Overlapping rectangles.
    if (self.start.x > other.end.x || other.start.x > self.end.x) return 0;
    if (self.start.y > other.end.y || other.start.y > self.end.y) return 0;
    return other.end.z;
}

// Parse "4,5,6"
fn int[<3>] string_to_coord(String s)
{
	@pool()
	{
		String[] parts = s.tsplit(",");
		return { parts[0].to_int()!!, parts[1].to_int()!!, parts[2].to_int()!! };
	};
}

fn List(<Brick*>) create_and_simulate_bricks()
{
// Load the bricks
	File f = file::open("day22.txt", "rb")!!;
	defer (void)f.close();
	List(<Brick*>) bricks;
	bricks.init_temp();
	while (try line = io::treadline(&f))
	{
		String[] parts = line.tsplit("~");
		int[<3>] from = string_to_coord(parts[0]);
		int[<3>] to = string_to_coord(parts[1]);
		int[<3>] start = math::min(from, to);
			Brick* brick = mem::temp_new(Brick, { .id = (int)bricks.len() + 1, .start = start, .end = start + math::abs(from - to)});
		// Init the two internal lists.
		brick.supports.temp_init();
		brick.supported_by.temp_init();
		// Add the brick.
		bricks.append(brick);
	}
	// Keep track of supporters
	List(<Brick*>) supporters;
	supporters.temp_init();
	// Sort the bricks
	quicksort(bricks);
	foreach (i, b : bricks)
	{
		int max_collision = 0;
		supporters.clear();
		// Reverse look at the previous bricks.
		foreach_r (o : bricks.array_view()[:i])
		{
			assert(o.start.z <= b.start.z);
			// If we already have a higher collision, skip
			if (o.end.z < max_collision) continue;
			// Test collision.
			int collide = b.collide(o);
			// No collision or collision further down than max -> skip
			if (collide == 0 || collide < max_collision) continue;
			// Collision higher up?
 			if (collide > max_collision)
			{
				// The we clear our list of supporters.
				supporters.clear();
				// Update max collisions.
				max_collision = collide;
			}
			// Add to the list of supporters
			supporters.append(o);
		}
		// Fix our list of supporters / suppported by
		foreach (o : supporters)
		{
			o.supports.append(b);
			b.supported_by.append(o);
		}
		assert(max_collision == 0 || supporters.len() > 0);
		// Uppdate z
		int offset = max_collision + 1 - b.start.z;
		b.start.z += offset;
		b.end.z += offset;
	}
	return bricks;
}

fn int part1()
{
	// Simulate the bricks.
	List(<Brick*>) bricks = create_and_simulate_bricks();
	int destroyable;
	foreach OUTER: (b : bricks)
	{
		foreach (o : b.supports)
		{
			// Does this support one brick exactly dependent on it?
			// if so we skip.
			if (o.supported_by.len() == 1) continue OUTER;
		}
		// Passed all the tests -> destroyable
		destroyable++;
	}
	return destroyable;
}

// To calculate destroyed bricks, paint them
// with a number to indicate they are destroyed.
fn int paint_bricks(Brick* b, int color)
{
	// Paint this as destroyed.
	b.color = color;
	int total = 1;
	foreach (o : b.supports)
	{
		// If the supported one is already colored, then skip.
		if (o.color == color) continue;
		// Does it have no uncolored support? I.e.
		// it only depends on colored supports,
		// if so color and count it recursively.
		if (o.has_no_uncolored_support(color))
		{
			total += paint_bricks(o, color);
		}
	}
	// Return the total.
	return total;
}

fn int part2()
{
	// We first simulate the bricks.
	List(<Brick*>) bricks = create_and_simulate_bricks();
	int total = 0;
	// For each brick
	foreach (b : bricks)
	{
		// Color paint the bricks to determine destroyed.
		// deduct 1, because the initial brick isn't counted.
		total += paint_bricks(b, b.id) - 1;
	}
	return total;
}