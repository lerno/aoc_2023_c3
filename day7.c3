/*
 * Advent of Code 2023 day 7
 */
import std::io;
import std::time;
import std::collections::list;
import std::ascii;
import std::math;
import std::sort;

fn void main()
{
	io::printn("Advent of code, day 7.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Score Jacks : %d - completed in %s", part1(), c.mark());
		io::printfn("* Score Jokers: %d - completed in %s", part2(), c.mark());
	};
}

struct HandBid
{
	inline Hand hand;
	long bid;
}

struct Hand
{
	char[5] hand;
	Score score;
}

// Comparison function for a hand.
fn int Hand.compare_to(&self, Hand other)
{
	if (self.score < other.score) return -1;
	if (self.score > other.score) return 1;
	foreach (i, c : self.hand)
	{
		if (c < other.hand[i]) return -1;
		if (c > other.hand[i]) return 1;
	}
	return 0;
}

enum Score
{
	HIGH_CARD,
	PAIR,
	TWO_PAIRS,
	THREE_OF_A_KIND,
	FULL_HOUSE,
	FOUR_OF_A_KIND,
	FIVE_OF_A_KIND
}

const char[256] CONVERSION = {
	['2'] = 1, ['3'] = 2, ['4'] = 3, ['5'] = 4, ['6'] = 5, ['7'] = 6, ['8'] = 7,
	['9'] = 8, ['T'] = 9, ['J'] = 10, ['Q'] = 11, ['K'] = 12, ['A'] = 14
};

const char[256] JOKER_CONVERSION = {
	['2'] = 1, ['3'] = 2, ['4'] = 3, ['5'] = 4, ['6'] = 5, ['7'] = 6, ['8'] = 7,
	['9'] = 8, ['T'] = 9, ['J'] = 0, ['Q'] = 11, ['K'] = 12, ['A'] = 14
};

// Evaluate when two cards remain
macro Score eval_two(char[] hand, Score current)
{
	char lowest = hand[0];
	// No match, return current score.
	if (lowest != hand[1]) return current;
	// We have a pair:
	switch (current)
	{
		case HIGH_CARD: return PAIR;
		case PAIR: return TWO_PAIRS;
		case THREE_OF_A_KIND: return FULL_HOUSE;
		default:
			unreachable();
	}
}

// Eval three cards
macro Score eval_three(char[] hand, Score current)
{
	char lowest = hand[0];
	// No match, eval 2
	if (lowest != hand[1]) return eval_two(hand[1..], current);
	// Pair, increase score by one (will be pair or high card)
	if (lowest != hand[2]) return current + 1;
	// We got three of a kind.
	return current == PAIR ? Score.FULL_HOUSE : Score.THREE_OF_A_KIND;
}

// Four cards left
macro Score eval_four(char[] hand)
{
	char lowest = hand[0];
	if (lowest != hand[1]) return eval_three(hand[1..], HIGH_CARD);
	if (lowest != hand[2]) return eval_two(hand[2..], PAIR);
	if (lowest != hand[3]) return THREE_OF_A_KIND;
	return FOUR_OF_A_KIND;
}

// Five cards left
macro Score eval_hand(char[] hand)
{
	char lowest = hand[0];
	if (lowest != hand[1]) return eval_four(hand[1..]);
	if (lowest != hand[2]) return eval_three(hand[2..], PAIR);
	if (lowest != hand[3]) return eval_two(hand[3..], THREE_OF_A_KIND);
	if (lowest != hand[4]) return FOUR_OF_A_KIND;
	return FIVE_OF_A_KIND;
}

macro Hand create_hand(String line)
{
	char[5] hand;
	char[5] ordered_hand;
	// Loop through the hand.
	foreach LOOP: (i, c : line)
	{
		char value = CONVERSION[c];
		hand[i] = value;
		// Insert into an ordered hand
		for (int j = 0; j < i; j++)
		{
			if (value < ordered_hand[j])
			{
				ordered_hand[j + 1..i] = ordered_hand[j..i - 1];
				ordered_hand[j] = value;
				continue LOOP;
			}
		}
		ordered_hand[i] = value;
	}
	// Return the evaluated hand.
	return { hand, eval_hand(&ordered_hand) };
}

// Evaluate when we have 3 jokers and two cards left
macro Score eval_joker_two(char[] hand)
{
	return Score.FOUR_OF_A_KIND + eval_two(hand, HIGH_CARD).ordinal;
}

// Evaluate when we have 2 jokers and three cards left
macro Score eval_joker_three(char[] hand)
{
	switch (eval_three(hand, HIGH_CARD))
	{
		case HIGH_CARD: return THREE_OF_A_KIND;
		case PAIR: return FOUR_OF_A_KIND;
		case THREE_OF_A_KIND: return FIVE_OF_A_KIND;
		default: unreachable();
	}
}

// Evaluate when we have 1 joker and four cards left
macro Score eval_joker_four(char[] hand)
{
	switch (eval_four(hand))
	{
		case HIGH_CARD: return PAIR;
		case PAIR: return THREE_OF_A_KIND;
		case TWO_PAIRS: return FULL_HOUSE;
		case THREE_OF_A_KIND: return FOUR_OF_A_KIND;
		case FOUR_OF_A_KIND: return FIVE_OF_A_KIND;
		default: unreachable();
	}
}

macro Hand create_joker_hand(String line)
{
	char[5] hand;
	char[5] ordered_hand;
	int jokers;
	foreach LOOP: (i, c : line)
	{
		char value = JOKER_CONVERSION[c];
		if (!value) jokers++;
		hand[i] = value;
		for (int j = 0; j < i; j++)
		{
			if (value < ordered_hand[j])
			{
				ordered_hand[j + 1..i] = ordered_hand[j..i - 1];
				ordered_hand[j] = value;
				continue LOOP;
			}
		}
		ordered_hand[i] = value;
	}
	// Jokers will be at the start of the ordered hand.
	switch (jokers)
	{
		case 4..5: return { hand, FIVE_OF_A_KIND };
		case 3: return { hand, eval_joker_two(ordered_hand[3..]) };
		case 2: return { hand, eval_joker_three(ordered_hand[2..]) };
		case 1: return { hand, eval_joker_four(ordered_hand[1..]) };
		default: return { hand, eval_hand(&ordered_hand) };
	}
}

def HandBidList = List(<HandBid>);

fn long calculate_score(HandBidList list)
{
	// Sort the list
	quicksort(list);
	// Score
	long score = 0;
	foreach (i, &hand : list)
	{
		score += hand.bid * (i + 1);
	}
	return score;
}

fn long part1()
{
	File f = file::open("day7.txt", "rb")!!;
	defer (void)f.close();
	HandBidList list;
	list.temp_init(1024);
	// Parse hands
	while (try line = io::treadline(&f))
	{
		String hand = line[:5];
		long bid = line[6..].to_long()!!;
		list.append({ create_hand(hand), bid });
	}
	return calculate_score(list);
}

fn long part2()
{
	File f = file::open("day7.txt", "rb")!!;
	defer (void)f.close();
	HandBidList list;
	list.temp_init(1024);
	// Parse hands
	while (try line = io::treadline(&f))
	{
		String hand = line[:5];
		long bid = line[6..].to_long()!!;
		list.append({ create_joker_hand(hand), bid });
	}
	return calculate_score(list);
}
