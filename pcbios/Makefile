
NASM=nasm
NASM_PARAMS=-f bin -O0

PERL=perl

BIOS_SIZE=8192

TARGETS=pcbios.bin

all: $(TARGETS)

%.bin: %.asm
	$(NASM) $< $(NASM_PARAMS) -o $@ -l $(basename $@).lst
	dd if=$@ of=$(basename $@)2.bin bs=1 count=8192 skip=57344
	mv $(basename $@)2.bin $@
	perl ../tools/checksum.pl $@ $(BIOS_SIZE)

.PHONY: clean
clean:
	rm -f $(TARGETS) $(basename $(TARGETS)).lst

