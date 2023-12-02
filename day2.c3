/*
 * Advent of Code 2023 day 2
 */
import std::io;
import std::time;

fn void main()
{
	io::printn("Advent of code, day 2.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duraction and resets the clock
		Clock c = clock::now();
		io::printfn("* Game 1 sum: %d - completed in %s", part1(), c.mark());
		io::printfn("* Game 2 sum: %d - completed in %s", part2(), c.mark());
	};
}

fn long powerset(String sets)
{
	long r, g, b;
    foreach (set : sets.tsplit("; "))
    {
		foreach (color : set.tsplit(", "))
		{
			String[] amountcol = color.tsplit(" ");
			assert(amountcol.len == 2);
			int amount = amountcol[0].to_int()!!;
			switch (amountcol[1][0])
			{
				case 'r': if (amount > r) r = amount;
				case 'g': if (amount > g) g = amount;
				case 'b': if (amount > b) b = amount;
				default: unreachable();
			}
		}
	}
	return r * g * b;
}

fn bool is_valid_set(String set)
{
	foreach (color : set.tsplit(", "))
	{
		String[] amountcol = color.tsplit(" ");
		assert(amountcol.len == 2);
		int amount = amountcol[0].to_int()!!;
		switch (amountcol[1][0])
		{
			case 'r': if (amount > 12) return false;
			case 'g': if (amount > 13) return false;
			case 'b': if (amount > 14) return false;
			default: unreachable();
		}
	}
	return true;
}

fn int part1()
{
	File f = file::open("day2.txt", "rb")!!;
	defer (void)f.close();
	int id = 0;
	int sum = 0;
    while OUTER: (try line = io::treadline(&f))
    {
        id++;
        String second_part = line.tsplit(": ", 2)[1];
        foreach (part : second_part.tsplit("; "))
        {
			if (!is_valid_set(part)) continue OUTER;
        }
        sum += id;
    }
    return sum;
}

fn long part2()
{
	File f = file::open("day2.txt", "rb")!!;
	defer (void)f.close();
	long sum = 0;
    while (try line = io::treadline(&f))
    {
        sum += powerset(line.tsplit(": ", 2)[1]);
    }
    return sum;
}