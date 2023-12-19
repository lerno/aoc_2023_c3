/*
 * Advent of Code 2023 day 19
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;
import std::collections::map;

fn void main()
{
	io::printn("Advent of code, day 19.");
	@pool()
	{
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Sum part 1: %d - completed in %s", part1(), c.mark());
		io::printfn("* Sum part 2: %d - completed in %s", part2(), c.mark());
	};
}

struct Rule
{
	// What's the name of the rule
	String name;
	// Link to the rule set on success
	RuleSet* result;
	// The property to test 0-3
	int property;
	// Is it less or greater?
	bool less;
	// Comparison value
	int value;
}

struct Range
{
	long[<4>] from;
	long[<4>] to;
}

struct RuleSet
{
	// The name of the rule set
	String name;
	int rule_count;
	// The rules, assume max 3
	Rule[3] rules;
	// Name of the rule set on default
	String else_name;
	// Pointer to rule set on default.
	RuleSet* else_ptr;
}

def RangeList = List(<Range>);
def RuleList = List(<RuleSet>);

RuleSet a_rule;
RuleSet r_rule;

// Convenience to grab accept and refuse rules if matching.
fn RuleSet* default_rule_ptr(String name)
{
	switch (name)
	{
	    case "A": return &a_rule;
	    case "R": return &r_rule;
	    default: return null;
	}
}

fn void parse_rule(RuleList* list, String line)
{
	isz idx = line.index_of("{")!!;
	RuleSet r @noinit;
	r.name = line[0:idx];
	// Remove name, starting and ending {}
	String rules = line[idx + 1..^2];
	// Split the rules
	String[] split = rules.tsplit(",");
	r.rule_count = split.len - 1;
	// Grab the all the values except the last.
	foreach (i, rule : split[..^2])
	{
		// Split on `:`
		idx = rule.index_of(":")!!;
		const int[256] MAP = { ['x'] = 0, ['m'] = 1, ['a'] = 2, ['s'] = 3 };
		// Grab the name, but do not map yet, except for the default value.
		String name = rule[idx + 1..];
		r.rules[i] = {
			.name = name,
			.result = default_rule_ptr(name),
			.property = MAP[rule[0]],
			.less = rule[1] == '<',
			.value = rule[2..(idx - 1)].to_int()!! };
	}
	// Finally handle the "else" value.
	r.else_name = split[^1];
	r.else_ptr = default_rule_ptr(r.else_name);
	// And add the rule.
	list.append(r);
}

// In post processing, patch up the links to avoid having to do a hashmap lookup
fn RuleSet* post_process_rules(RuleList* list)
{
	RuleSet* in;
	@pool()
	{
		// Create our hashmap and find 'in'
		HashMap(<String, isz>) index;
		index.init_temp((uint)list.len());
		foreach (i, &rule : list)
		{
			if (rule.name == "in") in = rule;
			index.set(rule.name, i);
		}
		// Now for each rule, map the pointer shortcut using the name.
		foreach (&rule : list)
		{
			// Do the rules
			for (int i = 0; i < rule.rule_count; i++)
			{
				if (rule.rules[i].result) continue;
				isz idx = index.get(rule.rules[i].name)!!;
				rule.rules[i].result = list.get_ref(idx);
			}
			// And the else
			if (!rule.else_ptr)
			{
				isz idx = index.get(rule.else_name)!!;
				rule.else_ptr = list.get_ref(idx);
			}
		}
	};
	return in;
}

// Let's apply rules to a given line for part 1
fn int apply_rules(String line, RuleList* rules, RuleSet* in)
{
	line = line[1..^2]; // Remove {}
	int[<4>] properties;
	// Parse the values.
	@pool()
	{
		foreach (i, part : line.tsplit(","))
		{
			properties[i] = part[2..].to_int()!!;
		}
	};
	RuleSet* rule = in;
	// Loop until we reach the accept or reject rule.
	while LOOP: (rule != &a_rule && rule != &r_rule)
	{
		// Apply each rule in order.
		for (int i = 0; i < rule.rule_count; i++)
		{
			Rule* r = &rule.rules[i];
			int val = properties[r.property];
			int rule_value = r.value;
			bool match = r.less ? val < rule_value : val > rule_value;
			if (match)
			{
				// Match, so continue the outer loop.
				rule = r.result;
				continue LOOP;
			}
		}
		// Go for the default rule.
		rule = rule.else_ptr;
	}
	// If it's the reject rule, return zero.
	if (rule == &r_rule) return 0;

	// Return the sum of the properties.
	return properties.sum();
}

fn long part1()
{
	File f = file::open("day19.txt", "rb")!!;
	defer (void)f.close();

	// Prepare our list.
	RuleList rules;
	rules.init_temp();

	// Read until space
    while (String line = io::treadline(&f)!!, line.len > 0)
    {
        assert(line.len > 0);
        parse_rule(&rules, line);
    }
    // Post process rules, finding "in" and adding links.
    RuleSet* in = post_process_rules(&rules);

	// Apply rules and calculate the sum.
    long sum;
    while (try line = io::treadline(&f))
    {
        sum += apply_rules(line, &rules, in);
    }
    return sum;
}

// Apply a rule on a range
fn void apply_range(RuleSet* rule, RangeList* list, long[4] start, long[4] end)
{
	// If this is the reject rule then we're done.
	if (rule == &r_rule) return;

	// If it's the accept rule, add it to valid ranges.
	if (rule == &a_rule)
	{
		list.append({start, end});
		return;
	}

	// Walk through the rules.
	for (int i = 0; i < rule.rule_count; i++)
	{
		Rule* r = &rule.rules[i];
		long low = start[r.property];
		long high = end[r.property];
		long rule_value = r.value;

		// If it's x < limit
		if (r.less)
		{
			// If high < limit then it's a full match, continue to the next rule.
			if (high < rule_value)
			{
				apply_range(r.result, list, start, end);
				return;
			}
			// low >= limit then it's a no match, skip to the next rule.
			if (low >= rule_value) continue;

			// Split into [rule_value, end], [start, rule_value - 1]
			// The second is matching, so apply the rule to it,
			// and continue working with the non-matching range.
			long[4] end_copy = end;
			long[4] start_copy = start;
			end_copy[r.property] = rule_value - 1;
			start[r.property] = rule_value;
			apply_range(r.result, list, start_copy, end_copy);
			continue;
		}

		// Matching the entire range with greater-than.
		if (low > rule_value)
		{
			apply_range(r.result, list, start, end);
			return;
		}
		// Matching nothing.
		if (high <= rule_value) continue;

		// Split into [rule_value + 1, end] and [start, rule_value]
		// the former is the match.
		long[<4>] start_copy = start;
		long[<4>] end_copy = end;
		start_copy[r.property] = rule_value + 1;
		end[r.property] = rule_value;
		apply_range(r.result, list, start_copy, end_copy);
	}
	// Apply "else" rule.
	apply_range(rule.else_ptr, list, start, end);
}

fn long part2()
{
	File f = file::open("day19.txt", "rb")!!;
	defer (void)f.close();

	RuleList rules;
	rules.init_temp();

	// Parse rules as before.
    while (String line = io::treadline(&f)!!, line.len > 0)
    {
        assert(line.len > 0);
        parse_rule(&rules, line);
    }
    // And post process
    RuleSet* in = post_process_rules(&rules);

    // Keep a list of ranges.
    RangeList ranges;
    ranges.init_temp();

    // The original range is 1..4000, apply it recursively.
    apply_range(in, &ranges, { 1, 1, 1, 1 }, { 4000, 4000, 4000, 4000 });

    // Sum all the combinations.
	long res;
	foreach (r : ranges)
	{
		res += (r.to - r.from + { 1, 1, 1, 1 }).product();
	}
	return res;
}