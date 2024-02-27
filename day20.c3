/*
 * Advent of Code 2023 day 20
 */
import std::io;
import std::time;
import std::math;
import std::collections::list;
import std::collections::map;

fn void main()
{
	io::printn("Advent of code, day 20.");
	@pool()
	{
		Configuration conf = load_configuration();
		// Simple benchmarking with Clock, "mark" returns the last duration and resets the clock
		Clock c = clock::now();
		io::printfn("* Product part 1: %d - completed in %s", part1(conf), c.mark());
		io::printfn("* Presses part 2: %d - completed in %s", part2(conf), c.mark());
	};
}

struct Configuration
{
	char[] broadcaster; // Handle this separately
	Module[] modules;   // The modules (two types)
}

struct Module
{
	bool is_flip;
	char[] targets;     // Targets to call
	char[9] inputs;     // Inputs, only for conjunction
	char input_count;   // Number of bits used to track it
	char bit_start;     // First bit
}

// Magic constant for the end
const char END_TARGET = 0xFF;
// Magic constant for the start
const char BROADCAST = 0xFE;


fn Configuration load_configuration()
{
	File f = file::open("day20.txt", "rb")!!;
    defer (void)f.close();

	char[] broadcast_targets;
	HashMap(<String, char>) mapping;
	mapping.init_temp(64);
	List(<Module>) modules;
	modules.init_temp(64);

	// Step 1 build a map name <=> idx, skip broadcaster.
	int index = 0;
	while (try line = io::treadline(&f))
    {
		isz idx = line.index_of(" -> ")!!;
		String name = line[:idx];
		if (name == "broadcaster") continue;
		mapping.set(name[1..], (char)index++);
	}

	// From the beginning...
	f.seek(0, SET)!!;

	// Now we read the targets
	int end_targets = 0;
	while (try line = io::treadline(&f))
    {
		isz idx = line.index_of(" -> ")!!;
		// Grab the name
		String name = line[:idx];
		// Target names split
		String[] target_names = line[idx + 4..].tsplit(", ");
		assert(target_names.len > 0);

		// Create an array of targets
		char[] targets = mem::temp_alloc_array(char, target_names.len);
		foreach (i, target_name : target_names)
		{
			// Get the mapping, if none exists -> END_TARGET
			char id = mapping.get(target_name) ?? END_TARGET;
			targets[i] = id;
			// Count the end targets.
			if (id == END_TARGET) end_targets++;
		}
		// If this is the broadcaster, set it specially.
		if (name == "broadcaster")
		{
			broadcast_targets = targets;
			continue;
		}
		// Create and add a module.
		modules.push({ .is_flip = name[0] == '%', .targets = targets });
	}
	// We're going to assume 0 or 1 end targets.
	assert(end_targets < 2);

	// Because of the way we handle broadcast
	// we need to update inputs for Conjunction separately
	// for broadcast.
	foreach (target : broadcast_targets)
	{
		if (target == END_TARGET) continue;
		Module* t = &modules[target];
		if (!t.is_flip)
		{
			// Add BROADCAST as an input for the conjunction
			// (Does this happen?)
			t.inputs[t.input_count++] = BROADCAST;
		}
	}
	// Ok, normal pass, for every module, if
	// their target is a conjunction,
	// add the number of inputs.
	foreach (char i, &m : modules)
	{
		foreach (target : m.targets)
		{
			if (target == END_TARGET) continue;
			Module* t = &modules[target];
			if (!t.is_flip)
			{
				t.inputs[t.input_count++] = i;
			}
		}
	}

	// Now we need to reserve bits for each module
	char bit_start = 0;
	foreach (i, &m : modules)
	{
		m.bit_start = bit_start;
		bit_start += m.is_flip ? 1 : m.input_count;
	}
	assert(bit_start < 100);

	// This is super convoluted, but was written anticipating
	// a quite different part two...

	return { broadcast_targets, modules.array_view() };
}

struct Signal
{
	char to;
	char pulse;
	char from;
}

def SignalList = List(<Signal>);

const char HIGH_PULSE = 1;
const char LOW_PULSE = 0;

fn long part1(Configuration conf)
{
	int128 state;
	long[<2>] result;
	SignalList[2] signal_lists;

	// Init the two lists
	foreach (&list : signal_lists) list.init_temp();

	for (int it = 0; it < 1000; it++)
	{
		// Add a low pulse
		result[0]++;

		// broadcast low pulses
		foreach (j : conf.broadcaster)
		{
			signal_lists[0].push({ j, LOW_PULSE, BROADCAST });
			result[0]++;
		}

		// We switch between two lists
		// rather than having a ring buffer or similar.
		int current_list;
		while (signal_lists[current_list].len())
		{
			// The other list is the write list.
			SignalList* write_list = &signal_lists[(current_list + 1) & 0x1];
			// For each signal
			foreach (Signal signal : signal_lists[current_list])
			{
				// End target? We're done.
				if (signal.to == END_TARGET) continue;

				// Get the current module.
				Module m = conf.modules[signal.to];
				char bit_start = m.bit_start;
				char pulse_out @noinit;
				switch
				{
					case m.is_flip:
						// If it's a high pulse then don't do anything.
						if (signal.pulse == HIGH_PULSE)  continue;
						// Low pulse, flip state:
						char flip_state = (char)((state >> bit_start) & 0x1);
						state ^= 1u128 << m.bit_start;
						// Check the original state to determine pulse out.
						pulse_out = flip_state == HIGH_PULSE ? LOW_PULSE : HIGH_PULSE;
					default:
						// Bits are a range.
						char from = signal.from;
						char state_bits = m.input_count;
						for (char i = 0; i < state_bits; i++)
						{
							// Update the corresponding bit
							// (I know, I know very complex)
							if (m.inputs[i] == from)
							{
								uint128 bit = 1u128 << (i + bit_start);
								if (signal.pulse == HIGH_PULSE)
								{
									state |= bit;
								}
								else
								{
									state &= ~bit;
								}
								break;
							}
						}
						// Now look at the result
						uint mask = 1u << state_bits - 1;
						uint c_state = (uint)((state >> m.bit_start) & mask);
						// Did we fill all bits or not.
						pulse_out = c_state == mask ? LOW_PULSE : HIGH_PULSE;
				}
				// Send the result to all targets.
				foreach (target : m.targets)
				{
					result[pulse_out]++;
					write_list.push({ target, pulse_out, signal.to });
				}
			}
			// Clear the used list
			signal_lists[current_list].clear();
			// Swap lists.
			current_list = (current_list + 1) & 0x1;
		}
	}
	return result.product();
}

// Detect periods on a particular conjunction
fn usz detect_period(Configuration conf, char module_idx)
{
	// This uses the same method as for part 1
	int128 state;
	SignalList[2] signal_lists;
	foreach (&list : signal_lists) list.init_temp();
	int steps = 0;
	// We do a maximum of 100000 spins, which should be plenty
	for LOOP: (int g = 0; g < 100000; g++)
	{
		// Increase the steps.
		steps++;

		// broadcast low pulses
		foreach (j : conf.broadcaster)
		{
			signal_lists[0].push({ j, LOW_PULSE, BROADCAST });
		}

		// This follows part 1
		int current_list;
		while (signal_lists[current_list].len())
		{
			SignalList* write_list = &signal_lists[(current_list + 1) & 0x1];
			foreach (Signal signal : signal_lists[current_list])
			{
				if (signal.to == END_TARGET) continue;
				Module m = conf.modules[signal.to];
				char bit_start = m.bit_start;
				char pulse_out = 0xAA;
				switch
				{
					case m.is_flip:
						if (signal.pulse == HIGH_PULSE)  continue;
						// Flip state
						char flip_state = (char)((state >> bit_start) & 0x1);
						state ^= 1u128 << m.bit_start;
						pulse_out = flip_state == HIGH_PULSE ? LOW_PULSE : HIGH_PULSE;
					default:
						char from = signal.from;
						char state_bits = m.input_count;
						for (char i = 0; i < state_bits; i++)
						{
							if (m.inputs[i] == from)
							{
								uint128 bit = 1u128 << (i + bit_start);
								if (signal.pulse == HIGH_PULSE)
								{
									state |= bit;
								}
								else
								{
									state &= ~bit;
								}
								break;
							}
						}
						uint mask = 1u << state_bits - 1;
						uint c_state = (uint)((state >> m.bit_start) & mask);
						pulse_out = c_state == mask ? LOW_PULSE : HIGH_PULSE;
						// Except for this: if we found a high pulse on the searched-for
						// module we're done.
						if (pulse_out == HIGH_PULSE && module_idx == signal.to) return steps;
				}
				foreach (target : m.targets)
				{
					write_list.push({ target, pulse_out, signal.to });
				}
			}
			signal_lists[current_list].clear();
			current_list = (current_list + 1) & 0x1;
		}
	}
	unreachable("No cycle found");
}

fn long lcm(long a, long b) => (a * b) / gcd(a, b);
fn long gcd(long a, long b)
{
	long remainder;
	while (b)
	{
		remainder = a % b;
		a = b;
		b = remainder;
	}
	return a;
}

// We use some knowledge of the data to find an answer.
fn long part2(Configuration conf)
{
	// 1. We know the one updating rx is a conjunction
	// 2. And it only has a single target in rx
	// So find it!
	usz last_target;
	foreach (i, m : conf.modules)
	{
		if (m.targets[0] == END_TARGET)
		{
			last_target = i;
			break;
		}
	}

	// We're making the following observation:
	// Every target that broadcast signals to, enters
	// a graph that is independent of the other, until it reaches
	// the conjunction which triggers the end target.
	// Those matches are in themselves conjunctions!
	// This means, that if we can find the period of those conjunctions,
	// we can find out when all outputs high pulse,
	// causing a low pulse to be emitted to rx
	long presses = 1;
	foreach (char i, m : conf.modules)
   	{
   	    // Walk through each module
   	    foreach (c : m.targets)
   	    {
   	        // If it has the last conjunction as the target
   	        if (c == last_target)
   	        {
   	            assert(!m.is_flip); // Sanity check of our assumption
   	            @pool()
   	            {
   	                // Detect the period and find the lcm of all modules.
   	                presses = lcm(presses, detect_period(conf, i));
   	            };
    		}
    	}
    }
    // We're done. Pheeew! After many bad choices to solve this,
    // it's not harder than the above.
    return presses;
}