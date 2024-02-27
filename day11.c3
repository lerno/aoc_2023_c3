/*
 * Advent of Code 2023 day 11
 */
import std::io;
import std::time;
import std::collections::list;
import std::math;

fn void main()
{
	io::printn("Advent of code, day 11.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", calculate(2), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", calculate(1000000), c.mark());
	};
}

def CoordList = List(<long[<2>]>);

fn long calculate(int expansion)
{
	File f = file::open("day11.txt", "rb")!!;
	defer (void)f.close();
	// We keep a list of our coordinates.
	CoordList list;
	list.temp_init(1000);
	int width @noinit;
	int y;
	// 200 should be good enough.
	bool[200] spaces;
	while (try line = io::treadline(&f))
	{
		// Grab the width, we uselessly do this every loop but...
		width = line.len;
		bool found;
		foreach (int x, c : line)
		{
			// If we found a galaxy (why didn't they use '@'??)
			if (c == '#')
			{
				// Append it to our list
				list.push({ x, y });
				// Also mark that this line should not expand x / y
				found = true;
				spaces[x] = true;
			}
		}
		// Expand space, if we didn't find a galaxy, by moving the y coordinate.
		y += found ? 1 : expansion;
	}
	// Now we can calculate the extra x for each x.
	int extra_spaces = 0;
	long[200] add;
	for (int i = 0; i < width; i++)
	{
		if (!spaces[i]) extra_spaces += expansion - 1;
		add[i] = extra_spaces;
	}
	// Update all entries to patch their x values.
	foreach (&entry : list)
	{
		entry.x += add[entry.x];
	}

	// We are done, do a simple sum. Note that 'long' is needed
	// to prevent overflow!
	long sum = 0;
	foreach (i, entry : list)
	{
		for (int j = 0; j < i; j++)
		{
			// Some vector ops, the below is the same as
			// abs(entry.x - list[j].x) + abs(entry.y - list[j].y)
			sum += math::abs(entry - list[j]).sum();
		}
	}
	return sum;
}
