/*
 * Advent of Code 2023 day 6
 */
import std::io;
import std::time;
import std::collections::list;
import std::ascii;
import std::math;

fn void main()
{
	io::printn("Advent of code, day 6.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Puzzle part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Puzzle part 2: %d - completed in %s", part2(), c.mark());
	};
}

macro long combinations(long time, long distance)
{
	// Distance moved is just a quadratic equation.
	// distance = (t - x) * x
	// x^2 - x*t + distance = 0
	// => x = t/2 +- sqrt(t*t/4 - distance)
	double term = math::sqrt((double)time * time / 4.0 - distance);
	// Since want the inequality, distance < (t - x) * x
	// We can just ceil and add one.
	long low = (long)(time / 2.0 - term) + 1;
	double high_cut = time / 2.0 + term;
	// For the high we want to make 10.0 -> 9.0, 10.00000001 -> 10, so let's abuse casts:
	long high = high_cut == (long)high_cut ? (long)high_cut - 1 : (long)high_cut;
	// Now we have the range.
	return high - low + 1;
}

fn long part1()
{
	File f = file::open("day6.txt", "rb")!!;
	defer (void)f.close();
	// Use a static array as backing.
	int[<2>][] race_data = &&int[<2>][10] {};
	int races;
	foreach (time : io::treadline(&f)!!.tsplit(":")[1].tsplit(" "))
	{
		// We get a bunch of spaces as zero length strings on split.
		if (!time.len) continue;
		race_data[races++] = { time.to_int()!!, 0 };
	}
	races = 0;
	foreach (distance : io::treadline(&f)!!.tsplit(":")[1].tsplit(" "))
	{
		if (!distance.len) continue;
		race_data[races++][1] = distance.to_int()!!;
	}
	// Resize the slice.
	race_data = race_data[:races];
	long product = 1;
	// Calculate the result
	foreach (race : race_data)
	{
		product *= combinations(race[0], race[1]);
	}
	return product;
}

fn long part2()
{
	File f = file::open("day6.txt", "rb")!!;
	defer (void)f.close();
	// Remove spaces by splitting on " " and then join with "" :D
	// If high perf was desired, then one should consider a different way to do this.
	long time = string::join_new(io::treadline(&f).tsplit(":")[1].tsplit(" "), "", mem::temp()).to_long()!!;
	long distance = string::join_new(io::treadline(&f).tsplit(":")[1].tsplit(" "), "", mem::temp()).to_long()!!;
	// Do the single calculation.
	return combinations(time, distance);
}
