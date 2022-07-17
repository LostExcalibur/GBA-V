module main

import os
import cartridge
import cpu
import sysbus

const (
	bios_rom_path = r'.\gba_bios.bin'
	bios_rom      = os.read_bytes(bios_rom_path) or { panic('err') }
)

fn main() {
	cartridge := cartridge.load_cartridge(r'roms\arm.gba')

	bus := sysbus.Sysbus{
		bios_rom: bios_rom
		cartridge: cartridge
	}

	mut cpu := cpu.new()
	for {
		cpu.step(bus)
	}
	// println(arm.new(cartridge.header.entry_point, sysbus.rom_ws0_addr))
}
