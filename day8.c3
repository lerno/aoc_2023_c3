/*
 * Advent of Code 2023 day 8
 */
import std::io;
import std::time;
import std::collections::map;
import std::math;

fn void main()
{
	io::printn("Advent of code, day 8.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Steps part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Steps part 2: %d - completed in %s", part2(), c.mark());
	};
}

distinct Location (Printable) = char[3];
def LocationMap = HashMap(<Location, Location[2]>);

fn uint Location.hash(Location l) => l[0] << 16 + l[1] << 8 + l[0];
fn usz! Location.to_format(&self, Formatter* f) @dynamic { return f.printf("%s", (String)(*self)[:3]); }

fn long part1()
{
	File f = file::open("day8.txt", "rb")!!;
	defer (void)f.close();

	// Load the instructions
	String instructions = io::treadline(&f)!!;
	io::treadline(&f)!!;

	// Setup the mapping
	LocationMap map;
	map.temp_init(2048);

	// Load all mappings.
	while (try line = io::treadline(&f))
	{
		Location loc = (Location)(char[3])line[:3];
		Location left = (Location)line[7:3];
		Location right = (Location)line[12:3];
		map.set(loc, { left, right });
	}

	Location loc = "AAA";
	int steps = 0;
	isz pc = -1;

	// Step until we find ZZZ
	while (loc != (Location)"ZZZ")
	{
		steps++;
		pc = (pc + 1) % instructions.len;
		Location[2] locs = map.get(loc)!!;
		switch (instructions[pc])
		{
			case 'L': loc = locs[0];
			case 'R': loc = locs[1];
			default: unreachable();
		}
	}
	// Found!
	return steps;
}

// Greatest common denominator
fn long gcd(long a, long b)
{
	long remainder;
	while (b)
	{
		remainder = a % b;
		a = b;
		b = remainder;
	}
	return a;
}

fn long lcm(long a, long b) => (a * b) / gcd(a, b);

fn long find_cycle_length(LocationMap* map, String instructions, Location loc)
{
	for (isz pc = 0, long steps = 1 ;; steps++, pc = (pc + 1) % instructions.len)
	{
		Location[2] next = map.get(loc)!!;
		switch (instructions[pc])
		{
			case 'L': loc = next[0];
			case 'R': loc = next[1];
			default: unreachable();
		}
		if (loc[2] == 'Z') return steps;
	}
}

fn long part2()
{
	File f = file::open("day8.txt", "rb")!!;
	defer (void)f.close();

	// Grab the instructions
	String instructions = io::treadline(&f)!!;
	io::treadline(&f)!!;

	// Our tree map.
	LocationMap map;
	map.temp_init(2048);

	// A hundred should be plenty.
	Location[100] locs_buffer;
	Location[] start_locs;
	while (try line = io::treadline(&f))
	{
		Location loc = (Location)(char[3])line[:3];
		Location left = (Location)line[7:3];
		Location right = (Location)line[12:3];
		map.set(loc, { left, right });
		if (loc[2] == 'A')
		{
			// Use the current slice len as the counter(!)
			locs_buffer[start_locs.len] = loc;
			start_locs = locs_buffer[.. start_locs.len];
		}
	}
	// We note two things with the data:
	// 1. We find a Z only when we have run a complete set of instructions.
	// 2. The stepping from Z to Z has the same periodicity as going from A to Z
	//
	// Consequently we only need the least common multiple.
	long steps = 1;
	foreach (i, loc : start_locs)
	{
		steps = lcm(steps, find_cycle_length(&map, instructions, loc));
	}
	return steps;
}