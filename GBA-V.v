module main

import encoding.binary
import os
import cartridge
import cpu
import sysbus

const (
	bios_rom_path = r'.\gba_bios.bin'
	bios_rom      = sysbus.Readable{
		data: os.read_bytes(bios_rom_path) or { panic('err') }
	}
)

fn main() {
	cartridge := cartridge.load_cartridge(r'roms\arm.gba')

	mut bus := sysbus.Sysbus{
		bios: bios_rom
		cartridge: cartridge
	}

	mut cpu := cpu.new()
	cpu.set_verbose(true)
	for {
		cpu.step(mut bus)
	}
}
