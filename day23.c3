/*
 * Advent of Code 2023 day 23
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;
import std::collections::map;

fn void main()
{
	io::printn("Advent of code, day 23.");
	@pool()
	{
		Map map = load_global_map();
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Path part 1: %d - completed in %s", part1(map), c.mark());
		io::printfn("* Path part 2: %d - completed in %s", part2(map), c.mark());
	};
}

// Let's build a map with operator overloading, borrowed from day 14
struct Map
{
	char[200][] data;
	int width;
}

// This is what we need to implement to have indexing and foreach on the type
fn int Map.len(self) @inline @operator(len) => self.width;
fn char[] Map.get(self, int i) @inline @operator([]) => self.data[i][:self.width];

fn Map load_global_map()
{
	File f = file::open("day23.txt", "rb")!!;
	defer (void)f.close();
	static char[200][200] map_buffer;
	// Load the file into memory
    int height = 0;
    int width @noinit;
    while (try line = io::treadline(&f))
    {
    	width = line.len;
    	map_buffer[height++][0:line.len] = line;
    }
	assert(height < 200 && width < 200);
    return { map_buffer[:height], width };
}

// A convenient direction enum.
enum Dir : char(int[<2>] dir)
{
	NORTH({  0, -1 }),
	EAST ({  1,  0 }),
	SOUTH({  0,  1 }),
	WEST ({ -1,  0 }),
}

// A convenient method to take the opposite of a direction.
fn Dir Dir.opposite(s) => (Dir)((s.ordinal + 2) % 4);

// We want to be able to hash positions.
fn uint int[<2>].hash(s) => s.x + s.y * 10001;

// The next search for part 1
struct Search
{
	int[<2>] loc;
	int cost;
	Dir dir;
}

// Walk the map
fn int part1(Map map)
{
	// Keep track of the cost.
    int[200][200] visited_cost;
    // We start one step in to simplify.
	int[<2>] start = { 1, 1 };
	int[<2>] end = { map.width - 2, map.data.len - 1 };
	// The list contains the locations to search.
	List(<Search>) list;
	list.init_temp();
	// Start with the initial location.
	list.append({ start, 1, SOUTH });
	while OUTER: (list.len())
	{
		// Pop the search location off the stack.
		Search path = list.pop();

		int cost = path.cost;
		int[<2>] current = path.loc;
		Dir current_dir = path.dir;

		// Note that all paths are single directed,
		// so we can remove a lot of checks.
		while (current != end)
		{
			int[<2>] next;
			Dir next_dir;
			Dir opposite_dir = current_dir.opposite();
			foreach (dir : Dir.values)
			{
				// Just make sure we don't walk back:
				if (opposite_dir == dir) continue;
				// Find the possible exit.
				int[<2>] loc = dir.dir + current;
				// Skip if already visited at higher cost.
				if (visited_cost[loc.y][loc.x] >= cost) continue;
				// Check if we can move.
				switch (map.data[loc.y][loc.x])
				{
					case '#': continue;
					case '<': if (dir != WEST) continue;
					case 'v': if (dir != SOUTH) continue;
					case '^': if (dir != NORTH) continue;
					case '>': if (dir != EAST) continue;
				}
				// If we already found a direction to search
				// then put this search in the list.
				if (next != { 0, 0 })
				{
					list.append({ loc, cost + 1, dir });
					continue;
				}
				// Update the possible next dir.
				next_dir = dir;
				next = loc;
			}
			// If we didn't find any way to go, we skip.
			if (next == { 0, 0 }) continue OUTER;
			// Otherwise, increase cost and take a step
			// storing the cost.
			cost++;
			current = next;
			visited_cost[current.y][current.x] = cost;
			current_dir = next_dir;
		}
	}
	// Now we walked the entire map, check the cost at the exit.
	return visited_cost[end.y][end.x];
}

// This is an intersection of paths.
struct Intersection
{
	// The position of the intersection.
	int[<2>] pos;
	// Links to other intersections (may be null if not discovered)
	Intersection*[4] intersections;
	// And distance to those intersections
    int[4] intersection_cost;
	// Used to calculate cost.
	bool visited;
}

fn int part2(Map map)
{
	int[<2>] start = { 1, 1 };
	int[<2>] end = { map.width - 2, map.data.len - 1 };
	// Create the first and last intersection.
	Intersection* first = mem::new_temp(Intersection);
	Intersection* last = mem::new_temp(Intersection);
	*first = { .pos = start };
	*last = { .pos = end };

	// We set up a map position -> Intersection*
	HashMap(<int[<2>], Intersection*>) intersection_map;

	// Place the last location here.
	intersection_map.init_temp();
	intersection_map.set(end, last);

	// Create a list of intersections to search.
	List(<Intersection*>) list;
	list.init_temp();

	// Add the first intersection to this list.
	list.append(first);

	while OUTER: (list.len())
	{
		// Pop the last intersection.
		Intersection* path = list.pop();

		// Look into each direction from this intersection.
		foreach NEXT_DIR: (Dir dir : Dir.values)
		{
			int[<2>] current = path.pos + dir.dir;

			// Do some checks to see if we should skip it:

			// Is this moving out of the map?
			if (current.y == 0) continue;

			// Is it a wall?
			if (map.data[current.y][current.x] == '#') continue;

			// Did we already connect to this direction?
			if (path.intersections[dir.ordinal]) continue;

        	// Ok, let's visit this direction
			int cost = 1;
			Dir last_dir = dir;

			// Now try to walk to the next intersection.
			while (true)
			{
				// Have we discovered an existing intersection? If so
				// then we update the cost.
				if (try o = intersection_map.get(current))
				{
					assert(cost > 0);
					Dir from = last_dir.opposite();
					path.intersections[dir.ordinal] = o;
					path.intersection_cost[dir.ordinal] = cost;
					o.intersections[from.ordinal] = path;
					o.intersection_cost[from.ordinal] = cost;
					continue NEXT_DIR;
				}

				// Let's look into all directions, except the
				// one we come from.
				int dirs = 0;
				Dir first_dir;
				Dir opposite = last_dir.opposite();
				foreach (Dir d : Dir.values)
				{
					if (d == opposite) continue;
					int[<2>] pos = current + d.dir;
					char c = map.data[pos.y][pos.x];
					if (c == '#') continue;
					dirs++;
					first_dir = d;
				}

				assert(dirs > 0);
				// If we find a single direction, then
				// we continue walking.
				if (dirs == 1)
				{
					current += first_dir.dir;
					last_dir = first_dir;
					cost++;
					continue;
				}
				// An intersection was found!
				// Built it and add it to the map
				// In the next loop we will automatically connect it.
				Intersection* sec = mem::new_temp(Intersection);
				*sec = { .pos = current };
				intersection_map.set(current, sec);
				list.append(sec);
			}
		}
	}

	// Calculate the max distance.
	first.visited = true;
	// We add +1 because we started one step in.
	return max_distance(first, last) + 1;
}

fn int max_distance(Intersection* current, Intersection* last)
{
	// If we reached the end then return 0
	if (current == last) return 0;

	// Find the max distance.
	int max = -1;
	// Loop through the other nodes connected to this one.
	for (int i = 0; i < 4; i++)
	{
		Intersection* o = current.intersections[i];

		// If the node doesn't exist, or it's already visited - skip
        if (!o || o.visited) continue;

        // Otherwise, mark as visited.
		o.visited = true;

		// Calculate the max to the end
		int own = max_distance(o, last);

		// make it unvisited
		o.visited = false;

		// If there was no path to the end, skip it.
		if (own < 0) continue;

		// Cost is steps to the intersection + steps from the other intersection to the end.
		int total = own + current.intersection_cost[i];

		// If this exceeds the old max, update.
		if (total > max) max = total;
	}
	return max;
}
