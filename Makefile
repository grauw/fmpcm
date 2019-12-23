COPY_TARGET = /Volumes/MSXDOS2

all:
	mkdir -p bin
	java -Xss160K -jar tools/glass.jar -I gen -I lib/neonlib/src/ src/ROM.asm bin/fmpcm.rom bin/fmpcm.sym

copy: all
	cp bin/fmpcm.rom $(COPY_TARGET)/
	diskutil umount $(COPY_TARGET)

run: all
	openmsx -cart bin/fmpcm.rom -romtype ASCII16 -machine Panasonic_FS-A1GT -script openmsx.tcl

run2: all
	openmsx -cart bin/fmpcm.rom -romtype ASCII16 -machine Philips_NMS_8245 -ext fmpac -script openmsx.tcl

run3: all
	openmsx -cart bin/fmpcm.rom -romtype ASCII16 -machine Sanyo_PHC-70FD -script openmsx.tcl
