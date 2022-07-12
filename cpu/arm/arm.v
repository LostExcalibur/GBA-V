module arm

import bitfield as bf
import encoding.binary

pub enum ArmCond {
	eq = 0b0000
	ne = 0b0001
	hs = 0b0010
	lo = 0b0011
	mi = 0b0100
	pl = 0b0101
	vs = 0b0110
	vc = 0b0111
	hi = 0b1000
	ls = 0b1001
	ge = 0b1010
	lt = 0b1011
	gt = 0b1100
	le = 0b1101
	al = 0b1110
	invalid = 0b1111
}

pub enum ArmFormat {
	undefined
	branch_link
	branch_exchange
	software_interrupt
	data_processing
	multiply
	multiply_long
	// PSR vers reg
	psr_to_reg
	// Register vers psr
	reg_to_psr
	// Reg/imm vers psr[flags]
	move_to_flags
	single_data_transfer
	halfword_data_transfer_reg_offset
	halfword_data_transfer_imm_offset
	block_data_transfer
	single_data_swap
}

pub struct ArmInstruction {
pub:
	raw     bf.BitField
	format  ArmFormat
	address u32
}

pub fn new(raw u32) ArmInstruction {
	mut arr := []u8{}
	binary.big_endian_put_u32(mut arr, raw)
	return ArmInstruction{
		raw: bf.from_bytes(arr)
	}
}

pub fn from(raw u32) ArmFormat {
	return if (raw & 0x0fff_fff0) == 0x012f_ff10 {
		.branch_exchange
	} else if (raw & 0x0e00_0000) == 0x0a00_0000 {
		.branch_link
	} else if (raw & 0x0e00_0010) == 0x0600_0010 {
		.undefined
	} else if (raw & 0x0f00_0000) == 0x0f00_0000 {
		.software_interrupt
	} else if (raw & 0x0c00_0000) == 0x0000_0000 {
		.data_processing
	} else if (raw & 0x0fc0_00f0) == 0x0000_0090 {
		.multiply
	} else if (raw & 0x0f80_00f0) == 0x0080_0090 {
		.multiply_long
	} else if (raw & 0x0fbf_0fff) == 0x010f_0000 {
		.psr_to_reg
	} else if (raw & 0x0fbf_fff0) == 0x0129_f000 {
		.reg_to_psr
	} else if (raw & 0x0dbf_f000) == 0x0128_f000 {
		.move_to_flags
	} else if (raw & 0x0c00_0000) == 0x0400_0000 {
		.single_data_transfer
	} else if (raw & 0x0e40_0f90) == 0x0000_0090 {
		.halfword_data_transfer_reg_offset
	} else if (raw & 0x0e40_0090) == 0x0040_0090 {
		.halfword_data_transfer_imm_offset
	} else if (raw & 0x0e00_0000) == 0x0800_0000 {
		.block_data_transfer
	} else if (raw & 0x0fb0_0ff0) == 0x0100_0090 {
		.single_data_swap
	} else {
		.undefined
	}
}

pub fn (instr ArmInstruction) get_cond() ArmCond {
	return ArmCond(instr.raw.extract(0, 4))
}

pub fn (instr ArmInstruction) sets_cond_flags() bool {
	return instr.raw.get_bit(11) == 1
}
