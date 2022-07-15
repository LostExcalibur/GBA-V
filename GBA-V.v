module main

import cpu
import cpu.arm
import sysbus
import os
import cartridge

fn main() {
	cartridge := cartridge.load_cartridge(r'roms\arm.gba')
	bios_rom_path := './gba_bios.bin'
	bios_rom := os.read_bytes(bios_rom_path) or { panic('err') }

	bus := sysbus.Sysbus{
		bios_rom: bios_rom
		cartridge: cartridge
	}

	mut cpu := cpu.Cpu{}
	println(cpu.pc)
	for {
		cpu.step(bus)
		println(cpu.pc)
	}
	// println(arm.new(cartridge.header.entry_point).cond)
	// println('$cartridge.header, $cartridge.size')
}
