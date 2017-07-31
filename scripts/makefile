.PHONY: all clean

BIN=mark_chapters remove_blanklines lowernum remove_oov

all: $(BIN)
clean:
	-rm -- $(BIN) $(addsuffix .o,$(BIN))

%: %.d
	dmd -g -O $<
