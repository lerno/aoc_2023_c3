/*
 * Advent of Code 2023 day 3
 */
import std::io;
import std::time;
import std::collections::list;
import std::ascii;
import std::math;

struct Gear
{
	isz[<2>] location;
	int counter;
	long ratio;
}

def StringList = List(<String>);
def GearList = List(<Gear>);

GearList gear_list;

fn void main()
{
	io::printn("Advent of code, day 3.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Game 1 sum: %d - completed in %s", part1(), c.mark());
		io::printfn("* Game 2 sum: %d - completed in %s", part2(), c.mark());
	};
}

fn int part1()
{
	gear_list.temp_init();
	return scan_schematic();
}

fn long part2()
{
	// We already collected all the gears, so now just
	// add the gear ratios
	long sum;
	foreach (&gear : gear_list)
	{
		if (gear.counter == 2) sum += gear.ratio;
	}
	return sum;
}

fn int scan_schematic()
{
	File f = file::open("day3.txt", "rb")!!;
	defer (void)f.close();
	StringList list;
	list.temp_init();
	// Read every line into a dynamic list.
	while (try line = io::treadline(&f)) list.push(line);
	// I prefer using the view, but the list can be used as
	// well.
	String[] schematic = list.array_view();
	usz width = schematic[0].len;
	usz height = schematic.len;
	int sum;
	// Scan for numbers
	foreach (y, s : schematic)
	{
		for (usz i = 0; i < width; i++)
		{
			char c = s[i];
			if (!c.is_digit()) continue;
			// A number was found, find the end
			usz start = i;
			while (++i < width) if (!s[i].is_digit()) break;
			usz len = i - start;
			// Now scan the number and it's surroundings.
			sum += scan_number(schematic, height, width, start, y, len);
		}
	}
    return sum;
}

fn int scan_number(String[] list, isz height, isz width, isz x, isz y, isz len)
{
	// Get the bountaries
	isz start_y = math::max(y - 1, (isz)0);
	isz end_y = math::min(y + 2, height);
	isz start_x = math::max(x - 1, (isz)0);
	isz end_x = math::min(x + len + 1, width);
	// Scan everything around the digit for symbols
	// for simplicity we unnecessarily also scan over the digit.
	for (isz ys = start_y; ys < end_y; ys++)
	{
		String s = list[ys];
		for (isz xs = start_x; xs < end_x; xs++)
		{
			switch (s[xs])
			{
				case '.':
				case '0'..'9':
					// We found space or digit, so we continue.
					continue;
				case '*':
					// We found a gear, so we return the value *and*
					// store the gear.
					int value = list[y][x:len].to_int()!!;
					multiply_gear({xs, ys}, value);
					return value;
				default:
					// We found a non-gear, return the value.
					return list[y][x:len].to_int()!!;;
			}
		}
	}
	// Nothing around this digit, return zero.
	return 0;
}


fn void multiply_gear(isz[<2>] location, int value)
{
	// Look throught the list of gears.
	foreach (&gear : gear_list)
	{
		if (gear.location == location)
		{
			// The gear was found, increase the amount of surrounding digits.
			gear.counter++;
			if (gear.counter == 2)
			{
				// Multiply by the value if this is the second value.
				gear.ratio *= value;
				return;
			}
		}
	}
	// First time this gear is detected, store location, count and ratio.
	gear_list.push({ location, 1, value });
}
