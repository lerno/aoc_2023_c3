/*
 * Advent of Code 2023 day 14
 */
import std::io;
import std::time;
import std::math;
import std::collections::ringbuffer;
import std::hash::fnv64a;

fn void main()
{
	io::printn("Advent of code, day 14.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", part2(), c.mark());
	};
}

fn long part1()
{
	File f = file::open("day14.txt", "rb")!!;
	defer (void)f.close();
	// For the rocks, let's try a very simple algorithm.
	int[200] rocks;
	int width = 0;
	int height = 0;
	// First let's just grab the height and width.
	while (try line = io::treadline(&f))
	{
		height++;
		width = line.len;
	}
	rocks[:width] = height + 1;
	// Go back in the file.
	f.seek(0, SET)!!;


	int sum = 0;
	int height_checked = height;
	while (try line = io::treadline(&f))
	{
		// For each line, iterate over every column.
		for (int i = 0; i < width; i++)
		{
			switch (line[i])
			{
				case 'O':
					// Add the value of the rock - 1 in the column
					// Reduce the next rock value by one, since it is now occupied.
					sum += rocks[i] - 1;
					rocks[i]--;
				case '#':
					// Finding a fixed rock means setting the rock value to the
					// height making the next rock having the value height_checked - 1
					rocks[i] = height_checked;
			}
		}
		// Go down one line.
		height_checked--;
	}
	return sum;
}

// Let's build a map with operator overloading.
struct Map
{
	char[200][] data;
	int width;
}

// This is what we need to implement to have indexing and foreach on the type
fn isz Map.len(self) @inline @operator(len) => self.width;
fn char[] Map.get(self, isz i) @inline @operator([]) => self.data[i][:self.width];


// Brute force tilt north.
fn void tilt_north(Map map)
{
	foreach (int h, line : map)
	{
		foreach (w, c : line)
		{
			if (c != 'O') continue;
			isz new_h = h;
			while (new_h > 0 && map[new_h - 1][w] == '.') new_h--;
			if (new_h != h)
			{
				line[w] = '.';
				map[new_h][w] = 'O';
			}
		}
	}
}

// Brute force tilt south
fn void tilt_south(Map map)
{
	foreach_r (int h, line : map)
	{
		foreach (w, c : line)
		{
			if (c != 'O') continue;
			isz new_h = h;
			while (new_h < map.len() - 1 && map[new_h + 1][w] == '.') new_h++;
			if (new_h != h)
			{
				line[w] = '.';
				map[new_h][w] = 'O';
			}
		}
	}
}

// Brute force tilt west
fn void tilt_west(Map map)
{
	foreach (line : map)
	{
		foreach (int w, c : line)
		{
			if (!w) continue;
			if (c != 'O') continue;
			isz new_w = w;
			while (new_w > 0 && line[new_w - 1] == '.') new_w--;
			if (new_w != w)
			{
				line[w] = '.';
				line[new_w] = 'O';
			}
		}
	}
}

// Brute force tilt east
fn void tilt_east(Map map)
{
	foreach (int h, line : map)
	{
		foreach_r (int w, c : line)
		{
			if (w == map.width - 1) continue;
			if (c != 'O') continue;
			int new_w = w;
			while (new_w < map.width - 1 && line[new_w + 1] == '.') new_w++;
			if (new_w != w)
			{
				line[w] = '.';
				line[new_w] = 'O';
			}
		}
	}
}

// Evaluate a map
fn int evaluate(Map map)
{
	int height = (int)map.len();
	int sum = 0;
	foreach (int h, line : map)
	{
		foreach (c : line)
		{
			if (c == 'O') sum += height - h;
		}
	}
	return sum;
}

// This solution is not really that efficient, but it
// exercises the ring buffer.
fn long part2()
{
	// Let's define a 256 length ring buffer.
	// This one is storing the checksums for the last steps
    const BUFFER_LEN = 256;
	RingBuffer(<Fnv64a, BUFFER_LEN>) ring;
	ring.init();

	// Load the file into memory
	File f = file::open("day14.txt", "rb")!!;
	defer (void)f.close();
	char[200][200] map_buffer;
	int height = 0;
	int width @noinit;
	while (try line = io::treadline(&f))
	{
		width = line.len;
		map_buffer[height++][0:line.len] = line;
	}

	// Create our map.
	Map map = { map_buffer[:height], width };

	// Did we find a cycle yet?
	bool cycle_found;
	const TOTAL = 1_000_000_000;

	// Spin
	for LOOP: (int cycle = 0; cycle < TOTAL; cycle++)
	{
		// Actual spin
		for (int i = 0; i < 4; i++)
		{
			switch (i)
			{
				case 0: tilt_north(map);
				case 1: tilt_west(map);
				case 2: tilt_south(map);
				case 3: tilt_east(map);
				default: unreachable();
			}
		}
		// If we found the cycle, then we're done.
		if (cycle_found) continue;

		// Let's calculate a checksum *assuming* that this
		// will be sufficiently unique that we don't need
		// the full comparison! A bit of cheating, but probably
		// ok if our hash function is good.
		Fnv64a checksum;
		checksum.init();

		// Do the checksum.
		foreach (line : map)
		{
			checksum.update(line);
		}

		for (int i = 0; i < ring.written; i++)
		{
			// Did we find the checksum in the ring buffer?
			if (ring.getc(i) == checksum)
			{
				// Yes we did! Calculate the cycle length.
				int cycle_length = (int)ring.written - i;
				// How many cycles are left?
				int cycles_left = TOTAL - cycle - 1;
				// Let's add enough repetitions that we only
				// need the last few iterations.
				// We could also actually store the value
				// for the next cycles backwards. In that case we'd be done now!
				int add = (cycles_left / cycle_length) * cycle_length;
				cycle += add;
				cycle_found = true;
				// Exit, since we don't need to push / pop to the buffer.
				continue LOOP;
			}
		}
		// Pop from the end if we have too many.
		if (ring.written == BUFFER_LEN - 1)
		{
			ring.popc()!!;
		}
		// Push the checksum.
		ring.putc(checksum);
	}
	// Finally we evaluate the result.
	return evaluate(map);
}