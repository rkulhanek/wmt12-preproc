.PHONY: all clean

BIN=mark_chapters remove_blanklines

all: $(BIN)
clean:
	-rm -- $(BIN) $(addsuffix .o,$(BIN))

%: %.d
	dmd -g -O $<
