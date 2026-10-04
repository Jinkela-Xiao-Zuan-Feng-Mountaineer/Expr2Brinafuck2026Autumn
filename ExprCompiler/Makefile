CXX = c++
CXXFLAGS = -O2 -std=c++17 -Wall -Wextra -Wpedantic
ifeq ($(OS),Windows_NT)
EXEEXT = .exe
endif

.PHONY: all test cases clean
all: exprc$(EXEEXT)
exprc$(EXEEXT): expr.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(LDFLAGS) $(LDLIBS) -o $@
test: all
	$(MAKE) -C ../BrainfuckRunner
	sh tests.sh ./exprc$(EXEEXT) ../BrainfuckRunner/bf$(EXEEXT)
cases: all
	$(MAKE) -C ../BrainfuckRunner
	sh run_cases.sh ./exprc$(EXEEXT) ../BrainfuckRunner/bf$(EXEEXT)
clean:
	rm -f exprc exprc.exe
