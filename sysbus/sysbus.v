module sysbus

import encoding.binary
import cartridge
import cpu.regshift

pub const (
	bios_addr    = 0
	ewram_addr   = 0x0200_0000
	iwram_addr   = 0x0300_0000
	io_regs_addr = 0x0400_0000
	pal_ram_addr = 0x0500_0000
	vram_addr    = 0x0600_0000
	oam_addr     = 0x0700_0000
	rom_ws0_addr = 0x0800_0000
	rom_ws1_addr = 0x0a00_0000
	rom_ws2_addr = 0x0c00_0000
	sram_addr    = 0x0e00_0000
)

pub struct Readable {
mut:
	data []u8
}

pub struct BiosRom {
	Readable
}

pub struct Sysbus {
pub mut:
	bios  Readable
	ewram Readable
	iwram Readable
pub:
	cartridge cartridge.Cartridge
}

[inline]
pub fn (instance Readable) read_32(addr u32) u32 {
	return instance.read_16(addr) | (u32(instance.read_16(addr + 2)) << 16)
}

[inline]
pub fn (instance Readable) read_16(addr u32) u16 {
	return instance.read_8(addr) | (u16(instance.read_8(addr + 1)) << 8)
}

[inline]
pub fn (instance Readable) read_8(addr u32) u8 {
	return instance.data[addr]
}

[inline]
pub fn (mut instance Readable) write_32(addr u32, value u32) {
	instance.data[addr] = u8(value)
	instance.data[addr + 1] = u8(value >> u32(8))
	instance.data[addr + 2] = u8(value >> u32(16))
	instance.data[addr + 3] = u8(value >> u32(24))
}

[inline]
pub fn (mut instance Readable) write_16(addr u32, value u16) {
	instance.data[addr] = u8(value)
	instance.data[addr + 1] = u8(value >> 8)
}

[inline]
pub fn (mut instance Readable) write_8(addr u32, value u8) {
	instance.data[addr] = value
}

// pub interface Bus {
// 	read_8(u32) u8
// 	read_16(u32) u16
// 	read_32(u32) u32
// mut:
// 	write_8(u32, u8)
// 	write_16(u32, u16)
// 	write_32(u32, u32)
// }

pub fn (bus Sysbus) read_8(addr u32) u8 {
	return match addr & 0xff00_0000 {
		sysbus.bios_addr {
			bus.bios.read_8(addr)
		}
		else {
			panic('Addresse pas encore gérée : ${addr:x}')
		}
		// sysbus.ewram_addr {}
	}
}

pub fn (bus Sysbus) read_32(addr u32) u32 {
	return match addr & 0xff00_0000 {
		sysbus.bios_addr {
			bus.bios.read_32(addr)
		}
		else {
			panic('Addresse pas encore gérée : ${addr:x}')
		}
		// sysbus.ewram_addr {}
	}
}

pub fn (mut bus Sysbus) write_8(addr u32, data u8) {
	match addr & 0xff00_0000 {
		sysbus.bios_addr {
			bus.bios.write_8(addr, data)
		}
		else {
			panic('Addresse pas encore gérée : ${addr:x}')
		}
		// sysbus.ewram_addr {}
	}
}

pub fn (mut bus Sysbus) write_32(addr u32, data u32) {
	match addr & 0xff00_0000 {
		sysbus.bios_addr {
			bus.bios.write_32(addr, data)
		}
		else {
			panic('Addresse pas encore gérée : ${addr:x}')
		}
		// sysbus.ewram_addr {}
	}
}

pub fn (bus Sysbus) read_32_rotate(addr u32) u32 {
	val := bus.read_32(addr)

	return regshift.rotate_right(val, 8 * (addr & 0x3))
}
