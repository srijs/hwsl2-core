CC = clang
CFLAGS = -Wall -mavx2 -msse2 -msse4.1 -mpclmul -O3

.PHONY: clean test bench

HEADERS = $(wildcard *.h)
TESTS = $(wildcard tests/*.c)
BENCHMARKS = $(wildcard bench/*.c)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c $< -o $@

test: $(TESTS)
	$(CC) $(CFLAGS) $(TESTS) -o test
	./test

bench: $(TESTS)
	$(CC) $(CFLAGS) $(BENCHMARKS) -o benchmark
	./benchmark

clean:
	-rm -f *.o
	-rm -f test
	-rm -f benchmark
