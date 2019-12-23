source lib/neonlib/tools/symbols.tcl
# source lib/neonlib/tools/profile.tcl

symbols::load bin/fmpcm.sym

ext debugdevice
set debugoutput stdout
debug set_watchpoint read_io 0x2E
debug set_watchpoint write_mem 0x0000 {([debug read ioports 0xA8] & 0x0C) == 0x04}
debug set_watchpoint read_mem 0x0000 {([debug read ioports 0xA8] & 0x0C) == 0x04}

proc dihaltcallback {} {
	message "DI; HALT detected, which means a hang. You can just as well reset the machine now..." warning
	debug break
}
set di_halt_callback dihaltcallback

proc cpuspeed {x} {
	variable z80_freq [expr 3579545 * $x]
	variable z80_freq_locked false
	variable cmdtiming broken
	set z80_freq
}

proc my_slot_pc {} {
	address_in_slot [reg pc] 1 0
}

debug set_bp -once [symbol Application_Main] {[my_slot_pc]} {
	set throttle on
}

set throttle off
