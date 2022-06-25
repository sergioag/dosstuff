
NASM=nasm
NASM_PARAMS=-f bin -O2

TARGETS=xebecv1.bin

BIOS_SIZE=4096

all: $(TARGETS)

%.bin: %.asm
	$(NASM) $< $(NASM_PARAMS) -DDEBUG -o $@ -l $(basename $@).lst
	perl ../tools/checksum.pl $@ $(BIOS_SIZE)

.PHONY: clean
clean:
	rm -f $(TARGETS) $(basename $(TARGETS)).lst

