module cartridge

import os

pub struct Cart_Header {
	entry_point      [4]u8
	nintendo_logo    [156]u8
	game_title       [12]u8
	game_code        [4]u8
	maker_code       [2]u8
	fixed_value      u8
	main_unit_code   u8
	device_type      u8
	reserved         [7]u8
	software_version u8
	checksum         u8
	reserved_2       [2]u8
}

pub fn (header Cart_Header) str() string {
	mut result := 'Cartridge Header :\n'
	result += '\tEntry Point : $header.entry_point\n'
	result += '\tNintendo logo (cut): ${header.nintendo_logo[..10]}\n'
	result += '\tGame Title : ${header.game_title[..].bytestr()}\n'
	result += '\tGame Code : ${header.game_code[..].bytestr()}\n'
	result += '\tMaker Code : ${header.maker_code[..].bytestr()}\n'
	result += '\tChecksum : ${header.checksum:x}\n'

	return result
}

pub struct Cartridge {
pub mut:
	rom_data []u8
	header   Cart_Header
pub:
	size u64
}

pub fn load_cartridge(path string) Cartridge {
	mut file := os.open(path) or { panic(err) }
	defer {
		file.close()
	}

	file.seek(0, .end) or { panic(err) }
	file_size := file.tell() or { panic(err) }
	file.seek(0, .start) or { panic(err) }

	mut cart := Cartridge{
		size: u64(file_size)
	}
	file.read_struct<Cart_Header>(mut cart.header) or { panic(err) }
	cart.rom_data = file.read_bytes(int(file_size))

	mut chk := 0
	for i in 0x0A0 .. 0x0BC + 1 {
		chk = chk - cart.rom_data[i]
	}
	chk = (chk - 0x19) & 0x0FF

	if chk == cart.header.checksum {
		println('Checksum validated')
	} else {
		println('Wrong checksum : calculated ${chk:x} but read ${cart.header.checksum:x}')
	}

	return cart
}
