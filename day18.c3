/*
 * Advent of Code 2023 day 18
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;

fn void main()
{
	io::printn("Advent of code, day 18.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", part2(), c.mark());
	};
}

fn int[<2>] process_line(String line, int[<2>] current)
{
	// Straightforward conversion of char to direction.
	const int[<2>][256] CHAR_TO_DIR = {
		['L'] = { -1,  0 },
		['R'] = {  1,  0 },
		['U'] = {  0, -1 },
		['D'] = {  0,  1 }
	};
	int[<2>] dir = CHAR_TO_DIR[line[0]];

	// Grab the part after the character, split into two and grab the first
	// converting it into an integer:
	int steps = line[2..].tsplit(" ", 2)[0].to_int()!!;

	// Ok, we're done, multiply steps by direction and add to the current.
	return dir * steps + current;
}

fn int part1()
{
	File f = file::open("day18.txt", "rb")!!;
	defer (void)f.close();
	int[<2>] pos = { 1, 1 };
	int sum;
	int path;
	// We use the Shoelace theorem and track the path.
	while (try int[<2>] next = process_line(io::treadline(&f), pos))
	{
		path += math::abs(next - pos).sum();
		sum += pos.x * next.y - pos.y * next.x;
		pos = next;
	}
	// Interior + path gives the result.
	return math::abs(sum) / 2 + path / 2 + 1;
}

fn long[<2>] process_hex_line(String line, long[<2>] current)
{
	const long[<2>][256] CHAR_TO_DIR = {
		['0'] = {  1,  0 },
		['1'] = {  0,  1 },
		['2'] = { -1,  0 },
		['3'] = {  0, -1 }
	};
	// Split in 3 and discard the first two.
	String hex = line.tsplit(" ", 3)[2];

	// The last two chars are like '0)'
	// So the next last character contains the direction.
	long[<2>] dir = CHAR_TO_DIR[hex[^2]];

	// Strip the two characters at the end:
	hex = hex[:^2];

	// In 0.5.2 we'll be able to use to_long(16) but here,
	// but for now use the fact that 0x1234 works with String.to_long:
	hex[0..1] = "0x";

	// We return the new position.
	return dir * hex.to_long()!! + current;
}

fn long part2()
{
	File f = file::open("day18.txt", "rb")!!;
	defer (void)f.close();
	long[<2>] pos = { 1, 1 };

	// Implicit init to zero.
	long sum;
	long path;

	// Shoelace theorem again, same as part 1
	while (try long[<2>] next = process_hex_line(io::treadline(&f), pos))
	{
		path += math::abs(next - pos).sum();
		sum += pos.x * next.y - pos.y * next.x;
		pos = next;
	}
	// Interior + path
	return math::abs(sum) / 2 + path / 2 + 1;
}