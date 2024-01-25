
NASM=nasm
NASM_PARAMS=-f bin -O0

PERL=perl

BIOS_SIZE=32768

TARGETS=vgabios.bin

all: $(TARGETS)

%.bin: %.asm
	$(NASM) $< $(NASM_PARAMS) -o $@ -l $(basename $@).lst
	perl ../tools/checksum.pl $@ $(BIOS_SIZE)

vgabios.asm: endblob.inc

.PHONY: clean
clean:
	rm -f $(TARGETS) $(addsuffix .lst,$(basename $(TARGETS)))

