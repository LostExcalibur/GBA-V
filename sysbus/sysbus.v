module sysbus

import cartridge

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

pub struct Sysbus {
pub:
	bios_rom  []u8
	cartridge cartridge.Cartridge
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

[inline]
pub fn (bus Sysbus) read_32(addr u32) u32 {
	return bus.read_16(addr) | (u32(bus.read_16(addr + 2)) << 16)
}

[inline]
pub fn (bus Sysbus) read_16(addr u32) u16 {
	return bus.read_8(addr) | (u16(bus.read_8(addr + 1)) << 8)
}

[inline]
pub fn (bus Sysbus) read_8(addr u32) u8 {
	return bus.bios_rom[addr]
}
