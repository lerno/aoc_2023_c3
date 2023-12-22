/*
 * Advent of Code 2023 day 21
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;
import std::collections::map;

fn void main()
{
	io::printn("Advent of code, day 21.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Plots visited part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Plots visited part 2: %d - completed in %s", part2(), c.mark());
	};
}

const long BIG_WIDTH = 100_000_000;

macro ulong pos_to_index(long[<2>] pos)
{
	assert(pos.x + BIG_WIDTH > 0 && pos.x < BIG_WIDTH);
	assert(pos.y + BIG_WIDTH > 0 && pos.y < BIG_WIDTH);
	return (pos.y + BIG_WIDTH) * BIG_WIDTH * 2 + BIG_WIDTH + pos.x;
}

macro long[<2>] index_to_pos(ulong idx)
{
	return { idx % (BIG_WIDTH * 2) - BIG_WIDTH, idx / (BIG_WIDTH * 2) - BIG_WIDTH };
}

// Originally, I picked a faster algorithm for part 1
// That one was not reusable, so I removed it.
// This function does a brute force step simulation
// without any sort of grace.
fn ulong get_plots_for_steps(int steps, bool wrap)
{
	File f = file::open("day21.txt", "rb")!!;
    defer (void)f.close();

	// Load the map.
	String[200] map;
	long side @noinit;
	long height;
	long[<2>] start @noinit;
	while (try line = io::treadline(&f))
    {
        if (try idx = line.index_of("S"))
        {
            start = { (long)idx, height };
        }
        map[height++] = line;
        side = line.len;
	}
	// These assumption holds for all our maps.
	assert(side % 2 == 1 && start.x == (side - 1)/ 2);
	assert(height == side && start.y == start.x);

	HashMap(<long, bool>)[2] maps;
	// Let's allocate some big maps.
	foreach (&m : maps)
	{
		m.init_temp(2048);
	}

	// We switch between two maps
	int current_map = 0;
	maps[0].set(pos_to_index(start), true);
	for (int i = 0; i < steps; i++)
	{
		// Here we want another pool, but we
		// don't want to use release allocations the outer
		// hash map does, so force another temp allocator.
		// This is how it looks. If you try to use
		// @pool() normally, it will lead to memory corruption.
		@pool(mem::temp())
		{
			int next_map = (current_map + 1) % 2;
			// Loop through each key (sloooow)
			foreach (key : maps[current_map].key_tlist())
			{
				// Unpack the key to a position (slightly hackish folks!)
				long[<2>] pos = index_to_pos(key);
				// In all directions
				foreach (offset : long[<2>][4] { {0, 1}, {0, -1}, {-1, 0}, {1, 0} })
				{
					// Get the coordinat.
					long[<2>] coord = offset + pos;
					long[<2>] wrapped_coord = coord;
					switch
					{
						case wrap:
							// wrap if we wrap.
							wrapped_coord = (wrapped_coord % side + side) % side;
						default:
							// Otherwise skip this.
							if (coord.min() < 0 || coord.max() >= side) continue;
					}
					// If it's a rock, then we exit.
					if (map[wrapped_coord.y][wrapped_coord.x] == '#') continue;
					// Otherwise add this to the next map.
					maps[next_map].set(pos_to_index(coord), true);
				}
			}
			// Clear the current map and move to the next.
			maps[current_map].clear();
			current_map = next_map;
		};
	}
	// Answer is the number of elements in the current map.
	return maps[current_map].len();
}
fn ulong part1()
{
	// Just get 64 steps, no wrap.
	return get_plots_for_steps(64, false);
}

fn ulong part2()
{
	// Ok, some explanation. If the starting point is centered and the map is square, then
	// the flood fill will proceed in a diamond shape:
	//
	//    X        C        C
	//   Y#Z      B#D      B#D
	//    W      A###E    B###D
	//            H#F    A#####E
	//             G      H###F
	//                     H#F
	//                      G
    //
	// the above shows as half_side iterations, half_side + side, half_side + side * 2 etc
	//
	// We'll get:
	// half_side + side = 5 internal + 4 corners + 4 diagonals
	// half_side + 2 * side = 13 internal + 4 corners + 8 diagonals
	// half_side + 3 * side = 25 internal + 4 corners + 12 diagonals
	//
	// In other words, this is a quadratic formula.

	// We're going to do the following assumptions from the data:
	// 1. (STEPS - half_side) % side = 0
	// 2. The borders do not have any rocks.
	const long STEPS = 26501365;
	int side = 131;
	int half_side = 65;

	// We sample at three points (very slow and we actually redo the
	// calculation...)
	long a = get_plots_for_steps(half_side + side, true);
	long b = get_plots_for_steps(half_side + side * 2, true);
	long c = get_plots_for_steps(half_side + side * 3, true);

	// We want the constants of the following formula:
	// n2 * sides * sides + n * sides + add = plots
	// The following formula can be worked out from:
	// n2 + n + add = a
	// 4 * n2 + 2 * n + add = b
	// 9 * n2 + 3 * n + add = c
	//
	long n2 = (a + c - 2 * b) / 2;
	long n = (c - a - 8 * n2) / 2;
	long add = 2 * n2 - b + 2 * a;

	// How many full sides do we step?
	long sides = (STEPS - half_side) / side;

	// Solve it with maths...
	return n2 * sides * sides + n * sides + add;
}