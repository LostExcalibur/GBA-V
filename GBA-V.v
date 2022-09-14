module main

import os
import cartridge
import cpu
import memory
import sysbus

const (
	bios_rom_path = r'gba_bios.bin'
	bios_rom      = memory.Ram{
		data: os.read_bytes(bios_rom_path) or { panic(err) }
		size: u32(os.file_size(bios_rom_path))
	}
)

fn find_rom_path(args []string) ?string {
	mut found := false
	mut path := ''
	for arg in args {
		if os.is_file(arg) {
			if found {
				panic('Multiple ROM files submitted')
			}
			found = true
			path = arg
		}
	}
	return if found { path } else { none }
}

fn main() {
	args := os.args[1..]
	rom_path := find_rom_path(args) or { 'roms/arm.gba' }
	cartridge := cartridge.load_cartridge(rom_path)

	// mut f := os.open_file('bios_dump', 'w') or { panic(err) }
	//
	// defer {
	// 	f.close()
	// }
	//
	// for i in 0 .. 0x0080_0000 {
	// 	f.write('${arm.new(bios_rom.read_32(i), i)}\n'.bytes()) or { panic(err) }
	// }

	// println('${cartridge.read<u32>(0):x}')

	mut bus := sysbus.Sysbus{
		bios: bios_rom
		cartridge: cartridge
	}
	mut cpu := cpu.new(mut bus)

	if '--skip-bios' in args {
		cpu.skip_bios()
	}

	if '--repl' in args {
		cpu.set_verbose(true)
		cpu.start_repl()
	} else {
		if '-v' in args {
			cpu.set_verbose(true)
		}
		for {
			cpu.step()
		}
	}
}
