module psr

import bitfield as bf
import encoding.binary
import cpu.cpu_enums as cpue

const (
	reserved_bits_mask = bf.from_bytes([u8(0x0f), u8(0xff), u8(0xff), u8(0x00)])
)

pub struct CPSR {
mut:
	raw_bits bf.BitField
}

pub fn new(bits u32) CPSR {
	mut arr := []u8{}
	binary.big_endian_put_u32(mut arr, bits)
	mut b := bf.from_bytes(arr)
	mut ret := CPSR{bf.bf_and(b, bf.bf_not(psr.reserved_bits_mask))}

	ret.set_mode(.system)
	ret.set_state(.arm)

	return ret
}

pub fn (cpsr CPSR) get_state() cpue.CpuState {
	return cpue.CpuState(cpsr.raw_bits.get_bit(5))
}

pub fn (mut cpsr CPSR) set_state(state cpue.CpuState) {
	cpsr.raw_bits.set_bit_to(26, state == .thumb)
}

pub fn (cpsr CPSR) get_mode() cpue.CpuMode {
	// println('${cpsr.raw_bits.extract(0, 5):b}')
	return cpue.CpuMode(cpsr.raw_bits.extract(27, 5))
}

pub fn (mut cpsr CPSR) set_mode(mode cpue.CpuMode) {
	cpsr.raw_bits.insert(27, 5, int(mode))
}

pub fn (cpsr CPSR) n() bool {
	return cpsr.raw_bits.get_bit(0) == 1
}

pub fn (mut cpsr CPSR) set_n(flag bool) {
	cpsr.raw_bits.set_bit_to(0, flag)
}

pub fn (cpsr CPSR) z() bool {
	return cpsr.raw_bits.get_bit(1) == 1
}

pub fn (mut cpsr CPSR) set_z(flag bool) {
	cpsr.raw_bits.set_bit_to(1, flag)
}

pub fn (cpsr CPSR) c() bool {
	return cpsr.raw_bits.get_bit(2) == 1
}

pub fn (mut cpsr CPSR) set_c(flag bool) {
	cpsr.raw_bits.set_bit_to(2, flag)
}

pub fn (cpsr CPSR) v() bool {
	return cpsr.raw_bits.get_bit(3) == 1
}

pub fn (mut cpsr CPSR) set_v(flag bool) {
	cpsr.raw_bits.set_bit_to(3, flag)
}

pub fn (cpsr CPSR) q() bool {
	return cpsr.raw_bits.get_bit(4) == 1
}

pub fn (mut cpsr CPSR) set_q(flag bool) {
	cpsr.raw_bits.set_bit_to(4, flag)
}

pub fn (cpsr CPSR) irq_disabled() bool {
	return cpsr.raw_bits.get_bit(24) == 1
}

pub fn (mut cpsr CPSR) set_irq_disabled(flag bool) {
	cpsr.raw_bits.set_bit_to(24, flag)
}

pub fn (cpsr CPSR) fiq_disabled() bool {
	return cpsr.raw_bits.get_bit(25) == 1
}

pub fn (mut cpsr CPSR) set_fiq_disabled(flag bool) {
	cpsr.raw_bits.set_bit_to(25, flag)
}
