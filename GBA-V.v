module main

import cpu
import sysbus
import os
import cartridge

fn main() {
	bios_rom_path := './gba_bios.bin'
	bios_rom := os.read_bytes(bios_rom_path) or { panic('err') }
	mut sysbus := sysbus.Sysbus{bios_rom}
	mut cpu := cpu.Cpu{}
	// println(cpu.cpsr.mode())
	cartridge := cartridge.load_cartridge(r'roms\Metroid Fusion (Europe) (En,Fr,De,Es,It).gba')

	// println('$cartridge.header, $cartridge.size')
}
