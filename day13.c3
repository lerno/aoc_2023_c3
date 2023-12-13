/*
 * Advent of Code 2023 day 13
 */
import std::io;
import std::time;
import std::math;

fn void main()
{
	io::printn("Advent of code, day 13.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", solve_part(1), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", solve_part(2), c.mark());
	};
}

fn bool check(int[] lines, int candidate)
{
	int len = lines.len;
	// What is the range we're checking up and down?
	int max_check = math::min(len - candidate - 2, candidate);
	for (int i = 0; i < max_check; i++)
	{
		// If the lines don't match that's an error.
		if (lines[i + candidate + 2] != lines[candidate - i - 1]) return false;
	}
	return true;
}

// Doing the check but requiring a smudge!
fn bool check_smudge(int[] lines, int candidate)
{
	int len = lines.len;
	// Again, what's the max span to check.
	int max_check = math::min(len - candidate - 2, candidate);
	// Auto init to false
	bool smudge;
	for (int i = 0; i < max_check; i++)
	{
		// Let's pick the bit diff
		int diff = lines[i + candidate + 2] ^ lines[candidate - i - 1];
		switch
		{
			case diff == 0:
				// If the diff is zero then then match, all's well.
				continue;
			case !smudge && diff.popcount() == 1:
				// If they only mismatch on 1 bit and there is no smudge detected,
				// we now have a smudge. Horray!
				smudge = true;
				continue;
			default:
				// Too big a diff or smudge already found -> failed
				return false;
		}
	}
	// Only return true if we found a smudge!
	return smudge;
}

fault SolveFault
{
	NO_SOLVE
}

fn int! solve(int[] lines)
{
	int len = lines.len;
	// Work through all lines.
	for (int i = 0; i < len - 1; i++)
	{
		// If two consequent lines match, we might have detected a mirror.
		if (lines[i] == lines[i + 1] && check(lines, i)) return i + 1;
	}
	return SolveFault.NO_SOLVE?;
}

// Let's solve requiring exactly 1 smudge.
fn int! solve_smudged(int[] lines)
{
	int len = lines.len;
	for (int i = 0; i < len - 1; i++)
	{
		// Create the bit diff
		int diff = lines[i] ^ lines[i + 1];
		switch
		{
			case diff == 0:
				// If the diff is zero, we want to check assuming the smudge comes later.
				if (check_smudge(lines, i)) return i + 1;
			case diff.popcount() == 1:
				// If the diff is 1 bit, then we want to check assuming no smudge
				if (check(lines, i)) return i + 1;
			default:
				// Anything else just look again.
				continue;
		}
	}
	// Return that the solve failed.
	return SolveFault.NO_SOLVE?;
}

fn long solve_part(int part)
{
	File f = file::open("day13.txt", "rb")!!;
	defer (void)f.close();
	long sum;
	while OUTER: (true)
	{
		// Keep two variants of the map, where one is turned 90 degrees,
		// so that both can be solved with the same algorithm.
		int[32] vertical;
		int[32] horizontal;
		int lines = 0;
		int width;
		while (try line = io::treadline(&f))
		{
			// Empty line -> we're done reading.
			if (line.len == 0) break;

			// Update width
			width = line.len;
			foreach (i, c : line)
			{
				if (c != '#') continue;
				// Pack into bits, we assume width and height <= 32
				horizontal[lines] |= 1 << i;
				vertical[i] |= 1 << lines;
			}
			lines++;
		}
		// If we got zero lines, that's because we reached EOF reading nothing.
		if (!lines) break;
		// Solve first with the horizontal stack, multiplying by 100. If that
		// result was instead SolveFault.NO_SOLVE, then ?? makes the code
		// try the vertical stack instead. We finally use !! because we know one of them should work!
		if (part == 1)
		{
			sum += (solve(horizontal[:lines]) * 100 ?? solve(vertical[:width]))!!;
			continue;
		}
		// This is the same as above, but using solve_smudged.
		sum += (solve_smudged(horizontal[:lines]) * 100 ?? solve_smudged(vertical[:width]))!!;
	}
	return sum;
}