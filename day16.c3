/*
 * Advent of Code 2023 day 16
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;

fn void main()
{
	io::printn("Advent of code, day 16.");
	@pool()
	{
		Map map = load_global_map();
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", part1(map), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", part2(map), c.mark());
	};
}

// Let's build a map with operator overloading, this is actually borrowed from day 14
struct Map
{
	char[128][] data;
	int width;
}

// This is what we need to implement to have indexing and foreach on the type
fn int Map.len(self) @inline @operator(len) => self.width;
fn char[] Map.get(self, int i) @inline @operator([]) => self.data[i][:self.width];

fn Map load_global_map()
{
	File f = file::open("day16.txt", "rb")!!;
	defer (void)f.close();
	static char[128][128] map_buffer;
	// Load the file into memory
    int height = 0;
    int width @noinit;
    while (try line = io::treadline(&f))
    {
    	width = line.len;
    	map_buffer[height++][0:line.len] = line;
    }
	assert(height < 128 && width < 128);

    return { map_buffer[:height], width };
}

const char NORTH = 0b00001;
const char EAST  = 0b00010;
const char SOUTH = 0b00100;
const char WEST  = 0b01000;

struct LightBeam
{
	ichar[<2>] location;
	char direction;
}

const ichar[<2>][*] DIRECTION_FROM_VALUE = {
	[NORTH] = { 0, -1 },
	[SOUTH] = { 0,  1 },
	[EAST]  = { 1,  0 },
	[WEST]  = { -1, 0 }
};

fn void trace_beam(List(<LightBeam>)* beams, LightBeam beam, Map map, Map light_map)
{
	ichar[<2>] location = beam.location;
	char direction = beam.direction;
	ichar[<2>] velocity = DIRECTION_FROM_VALUE[direction];
	int height = map.len();
	int width = map.width;

	// While the beam is still on the map:
	while (location.x >= 0 && location.y >= 0 && location.x < width && location.y < height)
	{
		// Check what
		char light = light_map[location.y][location.x];
		// Already found light in this direction.
		if (light & direction) return;
		// Map the light direction.
		light_map[location.y][location.x] = light | direction;
		switch (map[location.y][location.x])
		{
			case '.':
				// Do nothing
				break;
			case '|':
				// Split if coming from east or west
				if (direction == WEST || direction == EAST)
				{
					// Deal with the north beam later.
					beams.v({ location + { 0, -1 }, NORTH });
					// Trace the south beam.
					velocity = DIRECTION_FROM_VALUE[direction = SOUTH];
				}
			case '-':
				// Split if coming from north or south.
				if (direction == NORTH || direction == SOUTH)
				{
					// Deal with the west beam later
					beams.push({ location + { -1, 0 }, WEST });
					// Trace the east beam.
					velocity = DIRECTION_FROM_VALUE[direction = EAST];
				}
			case '/':
				// Redirect beam clockwise.
				switch (direction)
				{
					case EAST: velocity = DIRECTION_FROM_VALUE[direction = NORTH];
					case WEST: velocity = DIRECTION_FROM_VALUE[direction = SOUTH];
					case NORTH: velocity = DIRECTION_FROM_VALUE[direction = EAST];
					case SOUTH: velocity = DIRECTION_FROM_VALUE[direction = WEST];
					default: unreachable("Illegal direction");
				}
			case '\\':
				// Redirect the beam counter clockwise
				switch (direction)
				{
					case EAST: velocity = DIRECTION_FROM_VALUE[direction = SOUTH];
					case WEST: velocity = DIRECTION_FROM_VALUE[direction = NORTH];
					case NORTH: velocity = DIRECTION_FROM_VALUE[direction = WEST];
					case SOUTH: velocity = DIRECTION_FROM_VALUE[direction = EAST];
					default: unreachable("Illegal direction");
				}
			default:
				unreachable();
		}
		// Move the beam
		location += velocity;
	}
}

// Calculate energized tiles giving a starting beam and the map.
fn int calculate_energized_tiles(Map map, LightBeam beam)
{
	// Create a light map.
	char[128][128] light_buffer;
    Map light_map = { light_buffer[:map.len()], map.width };

    // Keep a list of beams to process
	List(<LightBeam>) beams;
	beams.init_temp();

	// Append the first beam
	beams.push(beam);

	// While we have beams, trace them.
	while (beams.len())
	{
		trace_beam(&beams, beams.pop(), map, light_map);
	}

	// Sum all in the light map that is != zero
	int sum;
	foreach (line : light_map)
	{
		foreach (c : line) if (c) sum++;
	}
	return sum;
}

fn long part1(Map map)
{
    // Calculate starting from { 0, 0 } beam moving east.
    return calculate_energized_tiles(map, { { 0, 0 }, EAST} );
}


fn int part2(Map map)
{
    ichar height = (ichar)map.len();
    ichar width = (ichar)map.width;
    int max = 0;

    // Look for max north and south, by tracing from the bottom and top.
    for (ichar i = 0; i < width; i++)
    {
        @pool()
        {
	        max = math::max(
                max,
                calculate_energized_tiles(map, { { i, 0 }, SOUTH }),
                calculate_energized_tiles(map, { { i, height - 1 }, NORTH })
            );
        };
    }
    // Look for max east and west by tracing from left and right.
    for (ichar i = 0; i < height; i++)
    {
        @pool()
        {
	        max = math::max(
	            max,
	            calculate_energized_tiles(map, { { 0, i }, EAST }),
	            calculate_energized_tiles(map, { { width - 1, i }, WEST })
	        );
	    };
    }
    // Return the max
    return max;
}
