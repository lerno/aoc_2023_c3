/*
 * Advent of Code 2023 day 5
 */
import std::io;
import std::time;
import std::collections::list;
import std::ascii;
import std::math;

def LongList = List(<long>);
def SettingsList = List(<long[3]>);
def SeedRangeList = List(<long[<2>]>);

fn void main()
{
	io::printn("Advent of code, day 5.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Location number 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Location number 2: %d - completed in %s", part2(), c.mark());
	};
}

fn SettingsList read_settings(File* f)
{
	SettingsList list;
	list.temp_init(64);
	// We start a temp pool here.
	@pool()
	{
		io::treadline(f)!!;
		// There are always only 3 values.
		long[3] rule @noinit;
		while (true)
		{
			String! line = io::treadline(f);
			// On error we assume this is EOF
			if (catch line) break;
			// Line is now unwrapped due to the line above.
			if (!line.len) break;
			// Split and parse
			foreach (i, num : line.tsplit(" ")) rule[i] = num.to_long()!!;
			// Append the rule
			list.push(rule);
		}
	};
	return list;
}

fn void transform(SettingsList* list, LongList* seeds)
{
	// For each seed, apply the transformation.
	foreach (&seed_ref : seeds)
	{
		long seed = *seed_ref;
		foreach (long[3] rule : list)
		{
			long destination = rule[0];
			long source = rule[1];
			long len = rule[2];
			long source_end = source + len;
			// Is it in range
			if (seed >= source && seed < source_end)
			{
				// Update with the offset.
				*seed_ref += destination - source;
				break;
			}
		}
		// Leave the seed unchanged if no rule applies.
	}
}

fn void transform_range(SettingsList* list, SeedRangeList* seeds)
{
	usz seeds_len = seeds.len();
	for (usz i = 0; i < seeds_len; i++)
	{
		long[<2>] seed = seeds.get(i);
		foreach (long[3] rule : list)
		{
			long destination = rule[0];
			long source = rule[1];
			long len = rule[2];
			long source_end = source + len;

			// Is the seed all before or after? If so, skip
			if (seed[1] < source) continue;
			if (seed[0] >= source_end) continue;

			// Do the no-split case:
			// We have four cases for split:
			// ****** ===***===  ***=== ===***

			switch
			{
				// ******
				case seed[0] >= source && seed[1] < source_end:
					// Default case, all are transformed
					break;
				// ===***
				case seed[0] < source && seed[1] < source_end:
					long[<2>] unchanged_seed = { seed[0], source - 1 };
    				seed = { source, seed[1] };
    				seeds.push(unchanged_seed);
    				seeds_len++;
				// ***===
    			case seed[0] >= source && seed[1] >= source_end:
					long[<2>] unchanged_seed = { source_end, seed[1] };
					seed = { seed[0], source_end - 1 };
					seeds.push(unchanged_seed);
					seeds_len++;
				// ===***===
				default:
					long[<2>] unchanged_seed1 = { seed[0], source - 1 };
					long[<2>] unchanged_seed2 = { source_end, seed[1] };
					seed = { source, source_end - 1 };
					seeds.push(unchanged_seed1);
					seeds.push(unchanged_seed2);
					seeds_len += 2;
			}
			// Update the transformed part, using vector ops.
			seed += destination - source;
    		seeds.set(i, seed);
			break;
		}
	}
}

fn long part1()
{
	File f = file::open("day5.txt", "rb")!!;
	defer (void)f.close();
	LongList seeds;
	seeds.temp_init(128);
	String numbers = io::treadline(&f)!!.tsplit(": ")[1];
	foreach (num : numbers.tsplit(" "))
	{
		seeds.push(num.to_long()!!);
	}
	io::treadline(&f)!!;
	for (int i = 0; i < 7; i++)
	{
		SettingsList settings = read_settings(&f);
		transform(&settings, &seeds);
	}
	long min = long.max;
	foreach (long seed : seeds) min = math::min(min, seed);
	return min;
}

fn long part2()
{
	File f = file::open("day5.txt", "rb")!!;
	defer (void)f.close();
	SeedRangeList seeds;
	seeds.temp_init(128);
	String[] numbers = io::treadline(&f)!!.tsplit(": ")[1].tsplit(" ");
	// Load ranges
	for (int i = 0 ; i < numbers.len; i += 2)
	{
		// Inclusive ranges
		long start = numbers[i].to_long()!!;
		long end = numbers[i + 1].to_long()!! + start;
		seeds.push({ start, end });
	}
	io::treadline(&f)!!;
	for (int i = 0; i < 7; i++)
	{
		SettingsList settings = read_settings(&f);
		transform_range(&settings, &seeds);
	}
	long min = long.max;
	foreach (seed : seeds) min = math::min(min, seed[0]);
	return min;
}
