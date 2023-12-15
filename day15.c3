/*
 * Advent of Code 2023 day 15
 */
import std::io;
import std::time;
import std::collections::list;

fn void main()
{
	io::printn("Advent of code, day 15.");
	@pool()
	{
		// Load the whole data in a single sweep.
		char[] data = file::load_temp("day15.txt")!!;

		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", part1(data), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", part2(data), c.mark());
	};
}

fn long part1(char[] data)
{
	long sum = 0;
	// Sum the current hash in 'current'
	long current = 0;
	foreach (c : data)
	{
		// If we reach a new number, add 'current' and
		// and start a new hash calculation.
		if (c == ',')
		{
			sum += current;
			current = 0;
			continue;
		}
		// Perform the hash calculation.
		current = ((current + c) * 17) & 0xFF;
	}
	// Add any pending "current" to the sum.
	return sum + current;
}


struct Lens
{
	char[] name;
	int focal_length;
}

def LensList = List(<Lens>);

// Part2 is essentially implementing a hash map.
fn long part2(char[] data)
{
	// Create our fixed set of boxes with Lists
	// we could also do this with linked lists.
	LensList[256] boxes;
	foreach (&box : boxes) box.init_temp();

	// Again we just walk through the data without
	// separating it, so we need to keep track
	// of what the "first" character in the label is.
	int first = 0;
	long current = 0;
	for OUTER: (int i = 0; i < data.len; i++)
	{
		// Switch over the character
		char c = data[i];
		switch (c)
		{
			case ',':
				// A comma, that means we update what the first
				// character is (the next one after this)
				// we also reset the hash (although we could do
				// this elsewhere too)
				first = i + 1;
				current = 0;
				continue;
			case '-':
				// This is a removal. We first grab the name
				// as a slice:
				char[] name = data[first..i - 1];
				// We then loop over all of the lenses in the
				// current box.
				foreach (j, &lens : boxes[current])
				{
					// If we match the name, we remove it
					// since we use a List, this automatically
					// fixes the ordering.
					// Note that there can only be a single entry
					// with the same name, so if we get a match
					// we're done.
					if (lens.name == name)
					{
						boxes[current].remove_at(j);
						break;
					}
				}
			case '=':
				// Get the name of the lens to add
				char[] name = data[first..i - 1];
				// Now skip forward and grab the focal length
				i++;
				int focal_length = data[i] - '0';
				// We first try to see if we have it already
				foreach (j, &lens : boxes[current])
				{
					if (lens.name == name)
					{
						// If we do, we only need to update the
						// focal length
						lens.focal_length = focal_length;
						continue OUTER;
					}
				}
				// Otherwise, we append the new lens at the end of the
				// list.
				boxes[current].append({ name, focal_length });
			case 'a'..'z':
				// For a-z this is a name
				current = ((current + c) * 17) & 0xFF;
			default:
				// We should not get any other matches, so mark this as
				// unreachable.
				unreachable();
		}
	}
	// Now, we're done, so just sum up the "focusing power"
	long sum = 0;
	foreach (i, &box : boxes)
	{
		foreach (j, &lens : *box)
		{
			sum += (i + 1) * (j + 1) * lens.focal_length;
		}
	}
	return sum;
}
