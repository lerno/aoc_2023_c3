/*
 * Advent of Code 2023 day 25
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;
import std::sort;
import std::collections::map;

fn void main()
{
	io::printn("Advent of code, day 25.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sizes part 1: %d - completed in %s", part1(), c.mark());
	};
}

struct Edge
{
	long a;
	long b;
}

def NameMap = HashMap(<String, long>);
def EdgeList = List(<Edge>);

fn long part1()
{
	File f = file::open("day25.txt", "rb")!!;
	defer (void)f.close();
	NameMap map;
	map.temp_init(2048);
	EdgeList original_list;
	original_list.temp_init(2048);

	// Parse graph
	while (try line = io::readline(&f))
	{
		String[] parts = line.split(": ", 2);
		String lhs = parts[0];
		long id = map.@get_or_set(lhs, (long)map.len());
		foreach (node : parts[1].split(" "))
		{
			long other = map.@get_or_set(node, (long)map.len());
			original_list.append({ id, other });
		}
	}

	const long ID_MULT = 10000;
	// Set a maximum for number of tries, in case we have a bug! :D
	for (int loop = 0; loop < 1000000; loop++)
	{
		@pool()
		{
			// We have an id counter for our new merged nodes.
			long id = 0;
			assert(map.len() < ID_MULT, "Too many edges!");

			// Make a copy
			EdgeList list;
			list.temp_init(2048);
			list.add_all(&original_list);

			// Until we (maybe) have three wires
			while (list.len() > 3)
			{
				// Grab one edge
				int remove_index = rand((int)list.len());
				Edge e = list[remove_index];

				// Check the number of nodes already merged:
				// we have ID_MULT * id + merged nodes
				// unless it's a non-generated node.
				long a_count = e.a < ID_MULT ? 1 : e.a % ID_MULT;
				long b_count = e.b < ID_MULT ? 1 : e.b % ID_MULT;

				// Create a new node according to the above
				id++;
				long new = id * ID_MULT + a_count + b_count;

				// Remove the edge.
				list.remove_at(remove_index);

				// Walk through the edges
				usz len = list.len();
				for (usz i = 0; i < len; i++)
				{
					Edge* other = &list[i];
					// Replace with the new merged vertex
					if (other.a == e.a || other.a == e.b) other.a = new;
					if (other.b == e.a || other.b == e.b) other.b = new;

					// Remove any loops
					if (other.a == other.b)
					{
						list.remove_at(i);
						len--;
                        i--;
					}
				}
			}

			// We're done, so we now check if we only have two groups left
			// (joined by 3 edges)
			List(<long>) elements;
			elements.temp_init(16);
			foreach (e : list)
			{
				if (!elements.contains(e.a)) elements.append(e.a);
				if (!elements.contains(e.b)) elements.append(e.b);
			}
			// If we don't have it - keep looking.
			if (elements.len() != 2) continue;

			// We found the solution, return it as node_id % ID_MULT == number of nodes
			// Here we assume both nodes have been merged!
			return (elements[0] % ID_MULT) * (elements[1] % ID_MULT);
		};
	}
	assert(false, "No solution");
}
