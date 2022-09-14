module cartridge

import os
import memory

pub struct Cart_Header {
pub:
	entry_point      u32
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
	result += '\tEntry Point : ${header.entry_point:x}\n'
	result += '\tNintendo logo (cut): ${header.nintendo_logo[..10]}\n'
	result += '\tGame Title : ${header.game_title[..].bytestr()}\n'
	result += '\tGame Code : ${header.game_code[..].bytestr()}\n'
	result += '\tMaker Code : ${header.maker_code[..].bytestr()}\n'
	result += '\tChecksum : ${header.checksum:x}\n'

	return result
}

pub struct Cartridge {
	memory.Ram
mut:
	header Cart_Header
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
		size: u32(file_size)
	}
	file.read_struct<Cart_Header>(mut cart.header) or { panic(err) }
	cart.data = file.read_bytes(int(file_size))

	mut chk := 0
	for i in 0x0A0 .. 0x0BC + 1 {
		chk = chk - cart.data[i]
	}
	chk = (chk - 0x19) & 0x0FF

	if chk != cart.header.checksum {
		println('Wrong checksum : calculated ${chk:x} but read ${cart.header.checksum:x}')
	}

	return cart
}

// pub fn (cart Cartridge) read_8(addr u32) u8 {
// 	if addr < cart.size {
// 		return cart.rom_data[addr]
// 	}
// 	// TODO: read out of bounds or when no cartridge is loaded
// 	panic('Out of bounds')
//
//
// ub fn (cart Cartridge) read_16(addr u32) u16 {
// 	return cart.read_8(addr) | (u16(cart.read_8(addr + 1)) << 8)
//
//
// ub fn (cart Cartridge) read_32(addr u32) u32 {
// 	return cart.read_16(addr) | (u32(cart.read_16(addr + 2)) << 16)
//
