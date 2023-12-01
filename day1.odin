// Conversion to Odin written by
// Ian Simonson (https://github.com/iansimonson)
// implementing the same algorithm.
package day1

import "core:os"
import "core:time"
import "core:strings"
import "core:fmt"
import "core:bufio"

NUMS := [?]string{"zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"}

calibrate :: proc(read_text: bool) -> (total: int, ok := true) {
    f, err := os.open("day1.txt")
    defer os.close(f)
    if err < 0 {
        return {}, false
    }

    scanner: bufio.Scanner
    bufio.scanner_init(&scanner, os.stream_from_handle(f), context.temp_allocator)
    defer bufio.scanner_destroy(&scanner)
    for bufio.scanner_scan(&scanner) {
        line := bufio.scanner_text(&scanner)
        first := first_num_from(line, read_text) or_return
        last := reverse_num_from(line, read_text) or_return
        value := 10 * first + last
        total += value
    }

    return
}

main :: proc() {
    fmt.println("Advent of code, day 1.")
    {
        start := time.now()
        total, ok := calibrate(read_text = false)
        if !ok {
            panic("Error when running part 1")
        }
        end := time.now()
        fmt.printf("* Calibration task 1: %d - completed in %v\n", total, time.diff(start, end))
    }
    {
        start := time.now()
        total, ok := calibrate(read_text = true)
        if !ok {
            panic("Error when running part 2")
        }
        end := time.now()
        fmt.printf("* Calibration task 2: %d - completed in %v\n", total, time.diff(start, end))
    }
}

first_num_from :: proc(s: string, read_text: bool) -> (value: int, ok := false) {
    index := -1

    for c, i in s {
        if '0' <= c && c <= '9' {
            index = i
            value = int(c - '0')
            ok = true
            break
        }
    }

    if !read_text do return

    for num, i in NUMS {
        if idx := strings.index(s, num); idx != -1 {

            if index != -1 && index < idx do continue

            index = idx
            value = i
            ok = true
        }
    }

    return
}

reverse_num_from :: proc(s: string, read_text: bool) -> (value: int, ok := false) {
    index := -1

    #reverse for c, i in s {
        if '0' <= c && c <= '9' {
            index = i
            value = int(c - '0')
            ok = true
            break
        }
    }

    if !read_text do return

    for num, i in NUMS {
        if idx := strings.last_index(s, num); idx != -1 {

            if index != -1 && index > idx do continue

            index = idx
            value = i
            ok = true
        }
    }

    return
}