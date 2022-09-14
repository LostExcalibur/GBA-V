module memory

[heap]
pub struct Ram {
pub:
	size u32
mut:
	data []u8
}

pub fn (instance Ram) read<T>(addr_ u32) T {
	mut addr := addr_ & ~(sizeof(T) - 1)
	addr &= (instance.size - 1)
	assert addr + sizeof(T) <= instance.size

	unsafe {
		return *(&T(&instance.data[0] + addr))
	}
}

[inline]
pub fn (instance Ram) read_32(addr u32) u32 {
	return instance.read_16(addr) | (u32(instance.read_16(addr + 2)) << 16)
}

[inline]
pub fn (instance Ram) read_16(addr u32) u16 {
	return instance.read_8(addr) | (u16(instance.read_8(addr + 1)) << 8)
}

[inline]
pub fn (instance Ram) read_8(addr u32) u8 {
	return instance.data[addr]
}

[inline]
pub fn (mut instance Ram) write_32(addr u32, value u32) {
	instance.data[addr] = u8(value)
	instance.data[addr + 1] = u8(value >> u32(8))
	instance.data[addr + 2] = u8(value >> u32(16))
	instance.data[addr + 3] = u8(value >> u32(24))
}

[inline]
pub fn (mut instance Ram) write_16(addr u32, value u16) {
	instance.data[addr] = u8(value)
	instance.data[addr + 1] = u8(value >> 8)
}

[inline]
pub fn (mut instance Ram) write_8(addr u32, value u8) {
	instance.data[addr] = value
}
