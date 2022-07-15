
NASM=nasm
NASM_PARAMS=-f bin -O0

PERL=perl

BIOS_SIZE=8192

TARGETS=wdbios-11.bin wdbios-12.bin wdbios-13.bin wdbios-custom.bin

all: $(TARGETS)

#%.bin: %.asm
#	$(NASM) $< $(NASM_PARAMS) -o $@ -l $(basename $@).lst
#	perl ../tools/checksum.pl $@ $(BIOS_SIZE)

wdbios-11.bin: wdbios.asm
	$(NASM) $< $(NASM_PARAMS) -DTYPE11 -o $@ -l $(basename $@).lst
	perl ../tools/checksum.pl $@ $(BIOS_SIZE)

wdbios-12.bin: wdbios.asm
	$(NASM) $< $(NASM_PARAMS) -DTYPE12 -o $@ -l $(basename $@).lst
	perl ../tools/checksum.pl $@ $(BIOS_SIZE)

wdbios-13.bin: wdbios.asm
	$(NASM) $< $(NASM_PARAMS) -DTYPE13 -o $@ -l $(basename $@).lst
	perl ../tools/checksum.pl $@ $(BIOS_SIZE)

# If you want to have a custom build of the BIOS with a custom set of
# drive tables, you can uncomment this block. You must also provide
# the geometry in a file named inc/drvparamscustom.inc. You can use
# any of the existing geometry files as sample and change whatever you
# need.
#wdbios-custom.bin: wdbios.asm
#	$(NASM) $< $(NASM_PARAMS) -DTYPECUSTOM -o $@ -l $(basename $@).lst
#	perl ../tools/checksum.pl $@ $(BIOS_SIZE)
	

.PHONY: clean
clean:
	rm -f $(TARGETS) $(addsuffix .lst,$(basename $(TARGETS)))

