module main

import cpu
import cpu.arm
import sysbus
import os
import cartridge

fn main() {
	cartridge := cartridge.load_cartridge(r'roms\arm.gba')
	bios_rom_path := r'.\roms\Pokemon - Fire Red Version (U) (V1.1).gba'
	bios_rom := os.read_bytes(bios_rom_path) or { panic('err') }

	bus := sysbus.Sysbus{
		bios_rom: bios_rom
		cartridge: cartridge
	}

	mut cpu := cpu.new()
	for {
		cpu.step(bus)
	}
	// println(arm.new(cartridge.header.entry_point).cond)
	// println('$cartridge.header, $cartridge.size')
}
