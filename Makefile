COPY_TARGET = /Volumes/MSXDOS2

all:
	mkdir -p bin
	java -Xss160K -jar tools/glass.jar -I gen -I lib/neonlib/src/ src/COM.asm bin/fmpcm.com bin/fmpcm.sym

copy: all
	cp bin/fmpcm.com $(COPY_TARGET)/
	diskutil umount $(COPY_TARGET)

run: all
	openmsx -machine Panasonic_FS-A1GT -ext ide -ext ram4mb -script openmsx.tcl

run2: all
	openmsx -machine Philips_NMS_8245 -ext ide -ext slotexpander -ext ram4mb -ext fmpac -script openmsx.tcl

run3: all
	openmsx -machine Sanyo_PHC-70FD -ext ide -ext ram4mb -script openmsx.tcl
