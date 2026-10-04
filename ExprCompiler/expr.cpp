#include <fstream>
#include <iostream>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: exprc input.expr > output.bf\n";
        return 43;
    }
    std::ifstream source(argv[1]);
    if (!source) {
        std::cerr << "Error: cannot open source file\n";
        return 43;
    }

    // TODO: Implement the Expr compiler according to ../HW3.md.
    // Write Brainfuck to stdout only after successful compilation.
    std::cerr << "Error: compiler not implemented\n";

    // If everything is ok
    return 0;
}
