CXX = c++
CXXFLAGS = -O2 -std=c++17 -Wall -Wextra -Wpedantic

ifeq ($(OS),Windows_NT)
EXEEXT = .exe
endif

.PHONY: all test clean
all: bf$(EXEEXT)

bf$(EXEEXT): bf.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(LDFLAGS) $(LDLIBS) -o $@

test: bf$(EXEEXT)
	sh tests.sh ./bf$(EXEEXT)

clean:
	rm -f bf bf.exe
