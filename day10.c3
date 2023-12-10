/*
 * Advent of Code 2023 day 10
 */
import std::io;
import std::time;

fn void main()
{
	io::printn("Advent of code, day 10.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Steps part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Tiles part 2: %d - completed in %s", part2(), c.mark());
	};
}


const NORTH = 0x01;
const EAST = 0x02;
const SOUTH = 0x04;
const WEST = 0x08;

const int[256] DIRECTION_MAP = {
	['|'] = NORTH | SOUTH,
	['-'] = EAST | WEST,
	['L'] = NORTH | EAST,
	['J'] = NORTH | WEST,
	['7'] = SOUTH | WEST,
	['F'] = SOUTH | EAST,
};

const int[<2>][4] MOVES = { { 0, -1}, { 1, 0 }, { 0, 1 }, { -1, 0 }};
const PAINTED_MASK = 0x200;
const PATH_MASK = 0x100;

fn long part1()
{
	File f = file::open("day10.txt", "rb")!!;
	defer (void)f.close();
	int[200][200] map;
	int width = 0;
	int height = 0;
	int[<2>] start;
	while (try line = io::treadline(&f))
	{
		// Parse the line.
		width = line.len;
		foreach (int i, c : line)
		{
			// Directly convert.
			map[height][i] = DIRECTION_MAP[c];
			if (c == 'S')
			{
				start = { i, height };
				continue;
			}
		}
		height++;
	}
	assert (width < 499);
	int[<2>] point;
	// Find a starting point by going in all directions from S.
	switch
	{
		case start.y > 0 && map[start.y - 1][start.x] & SOUTH:
			point = start - { 0, 1 };
		case map[start.y + 1][start.x] & NORTH == NORTH:
			point = start + { 0, 1 };
		case start.x > 0 && map[start.y][start.x - 1] & EAST:
			point = start - { 1, 0 };
		default:
			unreachable("No start found.");
	}
	int[<2>] prev = start;
	int steps = 1;
	while OUTER: (point != start)
	{
		steps++;
		int direction = map[point.y][point.x];
		// Assume our loop never exits the map:
		foreach (i, int dir : { NORTH, EAST, SOUTH, WEST })
		{
			if (!(dir & direction)) continue;
			int[<2>] next = point + MOVES[i];
			if (next == prev) continue;
			prev = point;
			point = next;
			continue OUTER;
		}
		unreachable();
	}
	// The max length = steps around the whole path / 2
	return (long)steps / 2;
}

fn int fill(int[<2>] point, int[200][200]* map, char[200][200]* data, int height, int width)
{
	// Skip if the point isn't on the map.
	if (point.x < 0 || point.y < 0) return 0;
	if (point.x >= width || point.y >= height) return 0;
	int current = (*map)[point.y][point.x];
	// If we hit a path or already painted square, then we're done.
	if (current & PATH_MASK || current & PAINTED_MASK) return 0;

	// Update as painted.
	(*map)[point.y][point.x] = PAINTED_MASK;
	// Let's update the graphics.
	(*data)[point.y][point.x] = '#';

	// Fill in the cardinal directions.
 	return 1 + fill(point + { 0, 1 }, map, data, height, width)
			+ fill(point + { 0, -1 }, map, data, height, width)
			+ fill(point + { 1, 0 }, map, data, height, width)
			+ fill(point + { -1, 0 }, map, data, height, width);
}

// Given a point (on the path) and a direction and whether the it is clockwise or not, paint.
fn int flood_fill(int[<2>] point, bool clockwise, int direction, int[200][200]* map, char[200][200]* data, int height, int width)
{
	int mult = clockwise ? 1 : -1;
	switch (direction)
	{
		case NORTH: return fill(point + { mult, 0 }, map, data, height, width); // North -> west if clockwise
		case EAST: return fill(point + { 0, mult }, map, data, height, width);  // East -> north if clockwise
		case SOUTH: return fill(point + { -mult, 0 }, map, data, height, width);// South -> east if clockwise
		case WEST: return fill(point + { 0, -mult }, map, data, height, width); // West -> south if clockwise
		default: unreachable();
	}
}

fn long part2()
{
	File f = file::open("day10.txt", "rb")!!;
	defer (void)f.close();
	int[200][200] map;
	char[200][200] data;
	int width = 0;
	int height = 0;
	int[<2>] start;
	while (try line = io::treadline(&f))
	{
		// Parse the line.
		width = line.len;
		foreach (int i, c : line)
		{
			map[height][i] = DIRECTION_MAP[c];
			data[height][i] = c;
			if (c == 'S')
			{
				start = { i, height };
				continue;
			}
		}
		height++;
	}
	assert (width < 499);
	// We need to determine what the starting direction is
	int[<2>] first_point;
	int first_direction;
	switch
	{
		case start.y > 0 && map[start.y - 1][start.x] & SOUTH:
			first_point = start - { 0, 1 };
            first_direction = NORTH;
        case map[start.y + 1][start.x] & NORTH != 0:
			first_point = start + { 0, 1 };
			first_direction = SOUTH;
		case map[start.y][start.x + 1] & WEST != 0:
			first_point = start + { 1, 0 };
			first_direction = EAST;
		default:
			unreachable("We should have found a direction");
	}

	int last_direction = first_direction;
	int[<2>] point = first_point;
	int[<2>] prev = start;
	map[start.y][start.x] = PATH_MASK;
	int cw = 0;
	while OUTER: (point != start)
	{
		int direction = map[point.y][point.x];
		map[point.y][point.x] |= PATH_MASK;
		// Assume our loop never exits the map:
		foreach (i, int dir : { NORTH, EAST, SOUTH, WEST })
		{
			if (!(dir & direction)) continue;
			int[<2>] next = point + MOVES[i];
			// There are two possible directions...
			// skip if we moved back.
			if (next == prev) continue;
			// Ok, update the prev / next point.
			prev = point;
			point = next;
			// If we had a turn, then update clockwise turns accordingly:
			switch (last_direction)
			{
				case NORTH:
					switch (dir)
					{
						case EAST: cw++;
						case WEST: cw--;
					}
				case SOUTH:
					switch (dir)
					{
						case EAST: cw--;
						case WEST: cw++;
					}
				case WEST:
					switch (dir)
					{
						case SOUTH: cw--;
						case NORTH: cw++;
					}
				case EAST:
					switch (dir)
					{
						case SOUTH: cw++;
						case NORTH: cw--;
					}
			}
			// Update the last direction.
			last_direction = dir;
			continue OUTER;
		}
		unreachable();
	}
	// Just clean up all the unused pipes for nicer graphics:
	for (int i = 0; i < height; i++)
    {
    	for (int j = 0; j < width; j++)
    	{
    	    if (map[i][j] & 256 == 0)
    	    {
    	        data[i][j] = '.';
    	    }
    	}
	}
	prev = start;
	point = first_point;
	// We now know that anything on left side (cw) or right side (ccw) can be painted
	// so again we just follow the path, and make sure that we track how much we're painting.
	// note that we could have done this in a single sweep, marking lhs and rhs respectively of the path
	// in the first loop.
	int painted = 0;
	while OUTER: (point != start)
	{
		int direction = map[point.y][point.x];
		// Assume our loop never exits the map:
		foreach (i, int dir : { NORTH, EAST, SOUTH, WEST })
		{
			if (!(dir & direction)) continue;
			int[<2>] next = point + MOVES[i];
			if (next == prev) continue;
			// Now we flood fill in the direction we're going
			painted += flood_fill(point, cw > 0, dir, &map, &data, height, width);
			// If we changed direction (i.e. this is a corner) also flood fill in the old direction.
			if (last_direction != dir) painted += flood_fill(point, cw > 0, last_direction, &map, &data, height, width);
			prev = point;
			point = next;
			last_direction = dir;
			continue OUTER;
		}
		unreachable();
	}
	// Let's draw it nicely:
	for (int i = 0; i < height; i++)
	{
		for (int j = 0; j < width; j++)
		{
			switch (data[i][j])
			{
				case '7': io::print("┐");
				case 'L': io::print("└");
				case 'J': io::print("┘");
				case 'F': io::print("┌");
				case '|': io::print("│");
				case '-': io::print("─");
				default: io::printf("%c", data[i][j]);
			}

		}
		io::printn();
	}
	return painted;
}
