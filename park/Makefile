
NASM=nasm
NASM_PARAMS=-f bin -O2

TARGETS=park.com

all: $(TARGETS)

%.com: %.asm
	$(NASM) $< $(NASM_PARAMS) -DDEBUG -o $@ -l $(basename $@).lst

.PHONY: clean
clean:
	rm -f $(TARGETS) $(basename $(TARGETS)).lst

