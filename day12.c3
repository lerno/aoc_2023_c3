/*
 * Advent of Code 2023 day 12
 */
import std::io;
import std::time;
import std::collections::map;
import std::math;

// Memoisation, needed for part 2
struct Memo
{
	String map;
	String[] rules;
}

// Slow hash function...
fn uint Memo.hash(self)
{
	uint sum = self.map.hash();
	foreach (rule : self.rules) sum = sum * 37 + rule.hash();
	return sum;
}

// Very slow equals...
fn bool Memo.equals(self, Memo other)
{
	if (self.rules.len != other.rules.len) return false;
	if (self.map != other.map) return false;
	foreach (i, s : self.rules) if (s != other.rules[i]) return false;
	return true;
}

def MemoMap = HashMap(<Memo, long>);
MemoMap memo;

fn void main()
{
	io::printn("Advent of code, day 12.");
	@pool()
	{
		// Init memoization map.
		memo.init_new(1024);
		defer memo.free();
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", part2(), c.mark());
	};
}

// Solve a particular string with a set of rules.
fn long solve(String map, String[] rules)
{
	// Check if we have this memoized.
	Memo key = { map, rules };
	if (try value = memo.get(key)) return value;

	long result = {|

		// Remove . from the beginning and the end
		map = map.trim(".");

		// Maybe we're done? Empty map, empty rules.
		if (map.len == 0) return rules.len == 0 ?  1 : 0;

		// If we have no more rules, then the map should have no more springs.
		if (rules.len == 0) return map.contains("#") ? 0 : 1;

		// Get the rule value
		int val = rules[0].to_int()!!;

		// Contract the map, removing the spaces.

		// Is there enough space? Otherwise this yields zero.
		if (map.len < val + (rules.len - 1) * 2) return 0;

		// If we start with an `?` then add the solution where the `?` is removed and add that to the combinations.
		long solutions = map[0] == '?' && map.len > 1 ? solve(map[1..], rules) : 0;

		// If there is a space in the part, then we return the solutions we have.
		if (map[:val].contains(".")) return solutions;

		// If we just traversed the entire map, then we're done.
		// we already checked for space, so this is safe
		if (map.len == val) return 1 + solutions;

		// If the map is followed by a string, then we don't have a proper match, return the solutions
		if (map[val] == '#') return solutions;

		// Recursively apply solve for the remaining rules after this.
		return solutions + solve(map[val + 1..], rules[1..]);
	|};
	// Memoize result
	memo.set(key, result);
	return result;
}

fn long part1()
{
	File f = file::open("day12.txt", "rb")!!;
	defer (void)f.close();
	long total;
	while (try line = io::treadline(&f))
	{
		@pool()
		{
			// Just split on space
			String[] parts = line.tsplit(" ");
			assert(parts.len == 2);
			// Rules are split again
			String[] rules = parts[1].tsplit(",");
			// Solving here with memoization is actually slower than without.
			total += solve(parts[0], rules);
		};
	}
	return total;
}

fn long part2()
{
	File f = file::open("day12.txt", "rb")!!;
	defer (void)f.close();
	long total;
	while (try line = io::treadline(&f))
	{
		@pool()
		{
			String[] parts = line.tsplit(" ");
			assert(parts.len == 2);
			// Let's very crudely assemble the new version of the rules:
			DString temp;
			temp.init_temp();
			for (int i = 0; i < 5; i++)
			{
				temp.append(parts[1]);
				if (i != 4) temp.append(",");
			}
			String[] rules = temp.str_view().tcopy().tsplit(",");

			// Clear and use it again, to get the map
			temp.clear();
			for (int i = 0; i < 5; i++)
			{
				temp.append(parts[0]);
				if (i != 4) temp.append("?");
			}

			// Solve
			total += solve(temp.str_view(), rules);
		};
	}
	return total;
}
