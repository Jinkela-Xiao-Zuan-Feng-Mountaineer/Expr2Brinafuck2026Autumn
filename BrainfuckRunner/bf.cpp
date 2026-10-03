#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
constexpr std::size_t memory_size = 1048576;

struct Instruction {
    char opcode;
    std::size_t line;
    std::size_t column;
    std::size_t match = 0;
};

[[noreturn]] void fail(const Instruction& instruction, const std::string& message) {
    throw std::runtime_error("line " + std::to_string(instruction.line) +
                             ", column " + std::to_string(instruction.column) +
                             ": " + message);
}

std::vector<Instruction> parse(std::istream& source) {
    std::vector<Instruction> program;
    std::vector<std::size_t> openings;
    std::size_t line = 1;
    std::size_t column = 0;
    char ch;
    while (source.get(ch)) {
        ++column;
        if (std::string("><+-.,[]").find(ch) != std::string::npos) {
            const std::size_t index = program.size();
            program.push_back({ch, line, column, 0});
            if (ch == '[') {
                openings.push_back(index);
            } else if (ch == ']') {
                if (openings.empty()) {
                    fail(program.back(), "unmatched ']'");
                }
                const std::size_t opening = openings.back();
                openings.pop_back();
                program[opening].match = index;
                program[index].match = opening;
            }
        }
        if (ch == '\n') {
            ++line;
            column = 0;
        }
    }
    if (source.bad()) {
        throw std::runtime_error("failed to read source file");
    }
    if (!openings.empty()) {
        fail(program[openings.back()], "unmatched '['");
    }
    return program;
}

// Consume a complete whitespace-delimited decimal int, rejecting partial tokens.
int read_integer(const Instruction& instruction) {
    std::string token;
    if (!(std::cin >> token)) {
        fail(instruction, "expected integer input (input exhausted or unreadable)");
    }
    std::size_t digits = (token[0] == '+' || token[0] == '-') ? 1 : 0;
    if (digits == token.size() || token.find_first_not_of("0123456789", digits) != std::string::npos) {
        fail(instruction, "input must be a decimal int");
    }
    try {
        return std::stoi(token);
    } catch (const std::exception&) {
        fail(instruction, "input integer is outside the int range");
    }
}

std::uint64_t parse_maxstep(const std::string& text) {
    if (text.empty() || text.find_first_not_of("0123456789") != std::string::npos) {
        throw std::runtime_error("maxstep must be a non-negative decimal integer");
    }
    std::uint64_t value = 0;
    for (char digit : text) {
        const auto number = static_cast<unsigned int>(digit - '0');
        if (value > (std::numeric_limits<std::uint64_t>::max() - number) / 10) {
            throw std::runtime_error("maxstep exceeds uint64 range");
        }
        value = value * 10 + number;
    }
    return value;
}

std::uint64_t execute(const std::vector<Instruction>& program,
                      std::optional<std::uint64_t> maxstep) {
    std::vector<std::uint8_t> memory(memory_size, 0);
    std::size_t pointer = 0;
    std::size_t pc = 0;
    std::uint64_t steps = 0;
    while (pc < program.size()) {
        const Instruction& instruction = program[pc];
        if (maxstep && steps >= *maxstep) {
            fail(instruction, "maxstep exceeded (limit: " + std::to_string(*maxstep) +
                              ", executed: " + std::to_string(steps) + ")");
        }
        if (steps == std::numeric_limits<std::uint64_t>::max()) {
            fail(instruction, "instruction counter overflow");
        }
        ++steps;
        switch (instruction.opcode) {
        case '>':
            if (pointer == memory_size - 1) fail(instruction, "pointer exceeds right memory boundary");
            ++pointer;
            break;
        case '<':
            if (pointer == 0) fail(instruction, "pointer exceeds left memory boundary");
            --pointer;
            break;
        case '+': memory[pointer] = static_cast<std::uint8_t>(memory[pointer] + 1); break;
        case '-': memory[pointer] = static_cast<std::uint8_t>(memory[pointer] - 1); break;
        case '.':
            std::cout << static_cast<unsigned int>(memory[pointer]) << '\n';
            if (!std::cout) fail(instruction, "failed to write output");
            break;
        case ',': memory[pointer] = static_cast<std::uint8_t>(read_integer(instruction)); break;
        case '[':
            if (memory[pointer] == 0) pc = instruction.match;
            break;
        case ']':
            if (memory[pointer] != 0) pc = instruction.match;
            break;
        }
        ++pc; // Both jump forms resume AFTER the matching bracket.
    }
    std::cout.flush();
    if (!std::cout) throw std::runtime_error("failed to flush output");
    return steps;
}
} // namespace

int main(int argc, char* argv[]) {
    try {
        if (argc != 2 && argc != 3) throw std::runtime_error("usage: bf input.bf [maxstep]");
        const auto maxstep = argc == 3 ? std::optional<std::uint64_t>(parse_maxstep(argv[2]))
                                      : std::nullopt;
        std::ifstream source(argv[1], std::ios::binary);
        if (!source) throw std::runtime_error("cannot open source file: " + std::string(argv[1]));
        const auto program = parse(source);
        const auto steps = execute(program, maxstep);
        std::cerr << "Executed instructions: " << steps << '\n';
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Error: " << error.what() << '\n';
        return -1;
    }
}
