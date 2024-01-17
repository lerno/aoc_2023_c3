/*
 * Advent of Code 2023 day 4
 */
import std::io;
import std::time;
import std::collections::list;
import std::ascii;
import std::math;

fn void main()
{
	io::printn("Advent of code, day 4.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Winnings 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Winnings 2: %d - completed in %s", part2(), c.mark());
	};
}

fn int matches_for_line(String line)
{
	// Split on ':' and keep the second, then split on | and keep
	// The parts.
	String[] data = line.tsplit(": ", 2)[1].tsplit("| ", 2);
	assert(data.len == 2);
	uint winning_numbers = data[0].len / 3;
	uint numbers = (data[1].len + 1) / 3;
	int matches;
	for (int i = 0; i < numbers; i++)
	{
		// Slice the number, eg " 9" or "48"
		String number = data[1][i * 3:2];
		// Check every number by string comparison
		// – this works because of the tabular nature
		// of the data.
		for (int j = 0; j < winning_numbers; j++)
		{
			String win = data[0][j * 3:2];
			if (number == win) matches++;
		}
	}
	return matches;
}

fn long part1()
{
	File f = file::open("day4.txt", "rb")!!;
	defer (void)f.close();
	long winnings;
	while (try line = io::treadline(&f))
	{
		int matches = matches_for_line(line);
		if (!matches) continue;
		// The winnings are 2^(matches - 1)
		winnings += 1L << (matches - 1);
	}
	return winnings;
}

fn long part2()
{
	File f = file::open("day4.txt", "rb")!!;
	defer (void)f.close();
	long winnings;
	List(<int>) matches;
	matches.temp_init(1024);
	// Store all the matches in a single sweep.
	while (try line = io::treadline(&f))
	{
		matches.append(matches_for_line(line));
	}
	// Create an array to store the cards, where zero = 1 card
	int[] cards = mem::temp_alloc_array(int, matches.len());
	long total_cards;
	foreach (i, copies : cards)
	{
		// How many actual cards do we have?
		int total = copies + 1;
		// Add to the sum.
		total_cards += total;
		// Lookup the wins
 		int wins = matches[i];
 		// Add copies to the following cards.
 		for (int j = 0; j < wins; j++)
 		{
 		    cards[i + j + 1] += total;
 		}
	}
	// We return the cards we've summed.
	return total_cards;
}