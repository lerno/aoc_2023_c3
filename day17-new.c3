/*
 * Advent of Code 2023 day 17 fixup
 * This uses Dijkstra's algorithm properly and as a result is 100 times faster...
 */
import std::io;
import std::time;
import std::math;
import std::collections::priorityqueue;

fn void main()
{
	io::printn("Advent of code, day 17.");
	@pool()
	{
		int[<2>] size = load_global_map();
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", part1(size), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", part2(size), c.mark());
	};
}

// We keep the map global
char[200][200] map;

// Load the map
fn int[<2>] load_global_map()
{
	File f = file::open("day17.txt", "rb")!!;
	defer (void)f.close();
	// Load the file into memory
    int height = 0;
    int width @noinit;
    while (try line = io::treadline(&f))
    {
    	width = line.len;
    	map[height++][0:line.len] = line;
    }
	assert(height < 200 && width < 200);
    return { width, height };
}

// A simple enum for the directions.
enum Dir : char
{
	NORTH,
	EAST,
	SOUTH,
	WEST
}

const int[<2>][4] MOVE_DIR = { [Dir.NORTH] = { 0, -1 }, [Dir.SOUTH] = { 0, 1 }, [Dir.EAST] = { 1, 0 }, [Dir.WEST] = { -1, 0 } };


// Per node we're storing this data
struct Node
{
	Dir dir;
	int dir_len;
	int[<2>] coord;
	int cost;
}

fn int Node.compare_to(self, Node other)
{
	return compare_to(self.cost, other.cost);
}

// We're packing direction and length in 40 elements (because max length to move is 10)
def DirLen = int[40];

// A simple macro to grab the cost at a given coordinate.
macro int cost(int[<2>] coord)
{
	return map[coord.y][coord.x] - (int)'0';
}

fn int part1(int[<2>] size)
{
	@pool()
	{
		return solve(size, 1, 3);
	};
}

fn int part2(int[<2>] size)
{
	@pool()
	{
		return solve(size, 4, 10);
	};
}

/**
 * @require dir_len > 0 && dir_len < 11
 **/
macro int dir_len_idx(Dir dir, int dir_len)
{
	return 4 * (dir_len - 1) + dir.ordinal;
}

// Let's implement Dijkstra's algorithm properly...
fn int solve(int[<2>] size, int min_move, int max_move)
{
	// Allocate a 3D array (although it's actually 4D)
	DirLen[200][200]* vmap = mem::temp_new(DirLen[200][200]);

	// Create a priority queue. Note that 0.5.1 has a bug preventing
	// this from properly working(!)
	PriorityQueue(<Node>) queue;
	queue.init_temp(1024);

	// Store the initial directions to test.
	queue.push({ EAST, 1, { 1, 0 }, cost({ 1, 0 }) });
	queue.push({ SOUTH, 1, { 0, 1 }, cost({ 0, 1 }) });

	// Pop the next node
	while (try Node node = queue.pop())
	{
		// How long has this node moved?
		int dir_len = node.dir_len;
		// What is the direction of the node?
		Dir node_dir = node.dir;
		// What is the reverse of the current direction
		char reverse = (node_dir.ordinal + 2) % 4;

		int node_cost = node.cost;

		// Check that the cost is cheaper than the current
		int* cost_ref = &(*vmap)[node.coord.y][node.coord.x][dir_len_idx(node_dir, dir_len)];

        // If not continue
        if ((*cost_ref ?: int.max) <= node_cost) continue;

		// Set the cost for the given x,y,direction,len in direction
		*cost_ref = node_cost;

		// Check each ordinal direction
		foreach (dir : Dir.values)
		{
			// Is it the opposite direction? If so continue.
			if (reverse == dir.ordinal) continue;
			// If it's not the same direction, may we turn?
			if (dir != node_dir && dir_len < min_move) continue;

			// Calculate the new location
			int[<2>] new_location = MOVE_DIR[dir] + node.coord;

			// Is it on the map? Otherwise continue.
			if (new_location.x < 0 || new_location.y < 0) continue;
			if (new_location.x >= size.x || new_location.y >= size.y) continue;

			// Calculate the new cost.
			int loc_cost = cost(new_location) + node.cost;

			// Do not look for solutions that would do worse than the manhattan distance.
			int cutoff = new_location.x + new_location.y;
			if (loc_cost > cutoff * 10) continue;

			// Calculate the new dir length
			int new_dir_len = 1;

			// If we go in the same direction...
			if (dir == node_dir)
			{
				// ... add the old length
				new_dir_len += dir_len;
				// Don't continue in this direction if this would exceed the max.
				if (new_dir_len > max_move) continue;
			}

			// Is the old cost cheaper?
			int prev_cost = (*vmap)[new_location.y][new_location.x][dir_len_idx(dir, new_dir_len)] ?: int.max;

			// If so skip
			if (prev_cost <= loc_cost) continue;

			// Add it to the open set
			queue.push({ dir, new_dir_len, new_location, loc_cost });
		}
	}

	// We're done, look at the last element.
	DirLen element = (*vmap)[size.y - 1][size.x - 1];
	int best = int.max;

	// Search the solution in the end location.
	for (int i = min_move; i < max_move + 1; i++)
    {
        foreach (dir : Dir.values)
    	{
    		int val = element[dir_len_idx(dir, i)] ?: int.max;
    		if (best > val) best = val;
    	}
	}
	return best;
}
