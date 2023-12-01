/*
 * Advent of Code 2023 day 1
 * Sample solution demonstrating C3 language and standard library.
 */
import std::io;
import std::time;

const String[10] NUMS = { "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn int! calibrate(bool read_text)
{
	File f = file::open("day1.txt", "rb")!;
	defer (void)f.close();
	int total = 0;
	// We read by line and store it in a temporary string.
	while (try line = io::treadline(&f))
	{
		int value = 10 * first_num_from(line, read_text)! + reverse_num_from(line, read_text)!;
		total += value;
	}
	return total;
}

fn void main()
{
	io::printn("Advent of code, day 1.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duraction and resets the clock
		Clock c = clock::now();
		io::printfn("* Calibration task 1: %d - completed in %s", calibrate(.read_text = false)!!, c.mark());
		io::printfn("* Calibration task 2: %d - completed in %s", calibrate(.read_text = true)!!, c.mark());
	};
}

fn int! first_num_from(String s, bool read_text)
{
	usz! index = SearchResult.MISSING?;
	int! value = SearchResult.MISSING?;

	// Let's demonstrate simple iteration.
	foreach (i, c : s)
	{
		if (c >= '0' && c <= '9')
		{
			index = i;
			value = c - '0';
			break;
		}
	}
	if (!read_text) return value;

	// If we already have a number at index, then we only need to scan up to index.
	// We can also avoid scanning if there are less than 3 characters before!
	foreach (int i, num : NUMS)
	{
		// This is very inefficient, for example first of all we could
		// reduce the string to the part before the first number.
		// And I mean we could just scan the string one time and
		// dispatch on the starting character instead!
		if (try idx = s.index_of(num))
		{
			// This means: if we already assigned an index, and that index is less than idx, then continue.
			// That is, we already found a number before the match.
			if (try index && index < idx) continue;
			index = idx;
			value = i;
		}
	}
	// Here we actually allow us not to find a number, which is
	// not true in the actual data set.
	// But it shows how C3 can deal with errors.
	return value;
}

// Reverse works from end to start, but is
// essentially the same as first_num_from
// We note that we could have combined both
// into a single function.
fn int! reverse_num_from(String s, bool read_text)
{
	usz! index = SearchResult.MISSING?;
	int! value = SearchResult.MISSING?;
	// Here we use foreach_r to demonstrate
	// revers iteration.
	foreach_r (i, c : s)
	{
		if (c >= '0' && c <= '9')
		{
			index = i;
			value = c - '0';
			break;
		}
	}
	if (!read_text) return value;
	foreach (int i, num : NUMS)
	{
		// This condition works the inverse of the
		// previous function, looking for the last
		// and skipping if index is already a later index.
		if (try idx = s.rindex_of(num))
		{
			if (try index && index > idx) continue;
			index = idx;
			value = i;
		}
	}
	return value;
}

