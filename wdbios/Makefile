
NASM=nasm
NASM_PARAMS=-f bin -O0

PERL=perl

BIOS_SIZE=8192

TARGETS=wdbios.bin

all: $(TARGETS)

%.bin: %.asm
	$(NASM) $< $(NASM_PARAMS) -o $@ -l $(basename $@).lst
	perl tools/checksum.pl $@ $(BIOS_SIZE)

wdbios.asm: Boot.asm Initialize.asm Int13h.asm IrqHandler.asm \
	inc/RamVars.inc inc/RomVars.inc inc/biosseg.inc inc/drvpar1.inc \
	inc/drvpar2.inc inc/equs.inc

.PHONY: clean
clean:
	rm -f $(TARGETS) $(basename $(TARGETS)).lst

