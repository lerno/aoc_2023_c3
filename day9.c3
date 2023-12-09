/*
 * Advent of Code 2023 day 9
 */
import std::io;
import std::time;

fn void main()
{
	io::printn("Advent of code, day 9.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Steps part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Steps part 2: %d - completed in %s", part2(), c.mark());
	};
}

fn long solve1(int[] vals)
{
	// We need a buffer to hold the new values.
	int[30] res;
	isz len = vals.len - 1;
	bool is_zero = true;

	// Calculate the new row (fairly inefficient, we could vectorize this for example)
	for (isz i = 0; i < len; i++)
	{
		if ((res[i] = vals[i + 1] - vals[i]) != 0) is_zero = false;
	}

	// If we have all zeros, then the value is the left hand side + 0
	if (is_zero) return vals[len];

	// Otherwise it is the previous interpolated value + the left hand side.
	return solve1(res[:len]) + vals[len];
}

fn long part1()
{
	File f = file::open("day9.txt", "rb")!!;
	defer (void)f.close();
	// We can use a dynamic array, or just reuse a slice of
	// a buffer.
	int[100] buffer;
	long sum;
	while (try line = io::treadline(&f))
	{
		// Parse the line.
		String[] nums = line.tsplit(" ");
		foreach (i, num : nums)
		{
			buffer[i] = num.to_int()!!;
		}
		// Solve and add to the sum.
		sum += solve1(buffer[:nums.len]);
	}
	return sum;
}

fn long solve2(int[] vals)
{
	// This solve is almost identical to solve 1
	int[30] res;
	isz len = vals.len - 1;
	bool is_zero = true;
	for (isz i = 0; i < len; i++)
	{
		if ((res[i] = vals[i + 1] - vals[i]) != 0) is_zero = false;
	}
	// Rather than getting it from the end, let's return the first value, and change the sign of the solve.
	if (is_zero) return vals[0];
	return -solve2(res[:len]) + vals[0];
}

fn long part2()
{
	File f = file::open("day9.txt", "rb")!!;
	defer (void)f.close();
	int[100] buffer;
	long sum;
	while (try line = io::treadline(&f))
	{
		String[] nums = line.tsplit(" ");
		foreach (i, num : nums)
		{
			buffer[i] = num.to_int()!!;
		}
		sum += solve2(buffer[:nums.len]);
	}
	return sum;
}