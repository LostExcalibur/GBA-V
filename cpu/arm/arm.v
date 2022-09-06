module arm

import bitfield as bf
import encoding.binary
import cpu.cpu_enums
import cpu.regshift

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
	bits    bf.BitField
	cond    ArmCond
	raw     u32
	format  ArmFormat
	address u32
}

pub fn extract_u32(field &bf.BitField, start int, len int) u32 {
	if start < 0 {
		return 0
	}
	mut output := u32(0)
	for i in 0 .. len {
		output |= u32(field.get_bit(start + len - i - 1)) << i
	}
	return output
}

fn (insn ArmInstruction) set_flag_mark() string {
	return if insn.sets_cond_flags() { 'S' } else { '' }
}

fn (insn ArmInstruction) link_mark() string {
	return if insn.link_flag() { 'l' } else { '' }
}

pub fn (insn ArmInstruction) str() string {
	mut s := '{ '
	s += 'Condition: $insn.cond, '
	match insn.format {
		.branch_exchange {
			s += 'Bx\tR$insn.rn(), '
		}
		.branch_link {
			s += 'B$insn.link_mark()\t${u32(i64(insn.address) + insn.branch_offset())}'
		}
		.data_processing {
			opcode := insn.opcode()
			rd := insn.rd()
			rn := insn.rn()

			match opcode {
				.mov, .mvn {
					s += '$opcode$insn.set_flag_mark()\tR$rd, '
				}
				.cmp, .cmn, .teq, .tst {
					s += '$opcode\tR$rn, '
				}
				else {
					s += '$opcode$insn.set_flag_mark()\tR$rd, R$rn, '
				}
			}
			operand2 := insn.operand2()
			match operand2 {
				regshift.RotatedImmediate {
					value := regshift.decode_rotated_immediate(operand2) or { panic('unreachable') }
					s += '#${value:x}'
				}
				regshift.ArmShiftedRegister {
					s += '$operand2'
				}
				else {
					panic('unreachable')
				}
			}
		}
		else {
			s += '$insn.format'
		}
	}
	s += ', Address: 0x${(insn.address):x} }'
	return s
}

pub fn new(raw u32, addr u32) ArmInstruction {
	mut arr := []u8{len: 4}
	binary.little_endian_put_u32(mut arr, raw)
	bits := bf.from_bytes(arr)
	return ArmInstruction{
		raw: raw
		cond: ArmCond(bits.extract(0, 4))
		bits: bits
		format: from(raw)
		address: addr
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

pub fn (instr ArmInstruction) sets_cond_flags() bool {
	return instr.bits.get_bit(11) == 1
}

pub fn (instr ArmInstruction) rm() u32 {
	return u32(instr.bits.extract(27, 4))
}

pub fn (instr ArmInstruction) rn() u32 {
	return u32(instr.bits.extract(12, 4))
}

pub fn (instr ArmInstruction) rd() u32 {
	return u32(instr.bits.extract(16, 4))
}

pub fn (instr ArmInstruction) rs() u32 {
	return u32(instr.bits.extract(20, 4))
}

pub fn (instr ArmInstruction) link_flag() bool {
	return instr.bits.get_bit(7) == 1
}

pub fn (instr ArmInstruction) branch_offset() i32 {
	offset := (instr.raw & 0xff_ffff)
	m := u32(1) << 23
	signed_offset := (offset ^ m) - m
	return (signed_offset << 2) + 8
	// return ((i64(instr.raw << 8) >> 8) << 2) + 8
}

pub fn (insn ArmInstruction) ldr_str_offset() regshift.ShiftedValue {
	immediate := insn.bits.get_bit(6) == 0

	if immediate {
		return regshift.ImmediateValue(u32(insn.bits.extract(20, 12)))
	} else {
		rm := insn.rm()
		shift := cpu_enums.ArmShiftType(insn.bits.extract(25, 2))
		amount := u32(insn.bits.extract(20, 5))

		return regshift.ArmShiftedRegister{
			reg: rm
			shift: regshift.ShiftAmount{
				amount: amount
				typ: shift
			}
		}
	}
}

pub fn (instr ArmInstruction) opcode() cpu_enums.AluOpcode {
	return cpu_enums.AluOpcode(instr.bits.extract(7, 4))
}

pub fn (instr ArmInstruction) operand2() regshift.ShiftedValue {
	op2 := u32(instr.bits.extract(20, 12))
	if instr.bits.get_bit(6) == 1 { // Immediate
		immed_8 := op2 & 0xff
		rotate_immed := u16(instr.bits.extract(20, 4)) * 2
		return regshift.RotatedImmediate{immed_8, rotate_immed}
	}
	// shifted register by register or by immediate
	else {
		rm := instr.rm()
		shift := regshift.regshift_from(instr.bits)
		return regshift.ArmShiftedRegister{rm, shift}
	}
}
