module cpu

import cpu.arm
import cpu.cpu_enums

pub enum AluOpcode {
	and = 0b0000
	eor = 0b0001
	sub = 0b0010
	rsb = 0b0011
	add = 0b0100
	adc = 0b0101
	sbc = 0b0110
	rsc = 0b0111
	tst = 0b1000
	teq = 0b1001
	cmp = 0b1010
	cmn = 0b1011
	orr = 0b1100
	mov = 0b1101
	bic = 0b1110
	mvn = 0b1111
}

[inline]
fn rotate_right(value u32, amount u32) u32 {
	return (value >> amount) | (value << (32 - amount))
}

[inline]
fn asr(value u32, amount u32) u32 {
	return if value >> 31 == 1 { ~(~value >> amount) } else { value >> amount }
}

[inline]
fn overflow_from_add(op1 u32, op2 u32, res u32) bool {
	return ((op1 ^ res) & (~op1 ^ op2)) >> 31 == 1
}

[inline]
fn overflow_from_sub(op1 u32, op2 u32, res u32) bool {
	return ((op1 ^ op2) & (op1 ^ res)) >> 31 == 1
}

fn (mut cpu Cpu) lsl(value u32, amount u32, flags bool) u32 {
	mut ret := value
	if amount != 0 {
		if amount < 32 {
			if flags {
				cpu.cpsr.set_c((value << (amount - 1)) >> 31 == 1)
			}
			ret <<= amount
		} else {
			if flags {
				if amount == 32 {
					cpu.cpsr.set_c(value & 0x1 == 1)
				} else {
					cpu.cpsr.set_c(false)
				}
			}
			ret = 0
		}
	}
	return ret
}

fn (mut cpu Cpu) lsr(value u32, amount u32, flags bool, immediate bool) u32 {
	mut ret := u32(0)
	if amount != 0 {
		if amount < 32 {
			if flags {
				cpu.cpsr.set_c((value >> (amount - 1)) & 0x1 == 1)
			}
			ret = value >> amount
		} else {
			if flags {
				if amount == 32 {
					cpu.cpsr.set_c(value >> 31 == 1)
				} else {
					cpu.cpsr.set_c(false)
				}
			}
		}
	} else if immediate {
		if flags {
			cpu.cpsr.set_c(value >> 31 == 1)
		}
	}
	return ret
}

fn (mut cpu Cpu) asr(value u32, amount u32, flags bool, immediate bool) u32 {
	mut ret := u32(0)
	if amount != 0 {
		if amount < 32 {
			if flags {
				cpu.cpsr.set_c((value >> (amount - 1)) & 0x1 == 1)
			}
			ret = asr(value, amount)
		} else {
			ret = asr(value, 31)

			if flags {
				cpu.cpsr.set_c(ret & 0x1 == 1)
			}
		}
	} else if immediate {
		ret = asr(value, 31)

		if flags {
			cpu.cpsr.set_c(ret & 0x1 == 1)
		}
	}
	return ret
}

fn (mut cpu Cpu) ror(value u32, amount u32, flags bool, immediate bool) u32 {
	mut ret := u32(0)
	if amount != 0 {
		ret = rotate_right(value, amount)
		if flags {
			cpu.cpsr.set_c(ret >> 31 == 1)
		}
	} else if immediate {
		c := u32(cpu.cpsr.c())
		if flags {
			cpu.cpsr.set_c(value & 0x1 == 1)
		}
		ret = (c << 31) | (value >> 1)
	}
	return ret
}

fn (mut cpu Cpu) calc_shift(value u32, amount u32, shift cpu_enums.ArmShiftType, flags bool, immediate bool) u32 {
	return match shift {
		.lsl { cpu.lsl(value, amount, flags) }
		.lsr { cpu.lsr(value, amount, flags, immediate) }
		.asr { cpu.asr(value, amount, flags, immediate) }
		.ror { cpu.ror(value, amount, flags, immediate) }
	}
}

fn (mut cpu Cpu) register_shift(reg u32, shift arm.RegisterShift, flags bool) u32 {
	value := cpu.get_reg(reg)

	match shift {
		arm.ShiftAmount {
			return cpu.calc_shift(value, shift.amount, shift.typ, flags, true)
		}
		arm.ShiftRegister {
			if shift.reg != 15 {
				return cpu.calc_shift(value, cpu.get_reg(shift.reg), shift.typ, flags,
					false)
			}
			panic("Can't shift by pc")
		}
	}
}

fn (mut cpu Cpu) log(value u32, flags bool) u32 {
	if flags {
		cpu.cpsr.set_z(value == 0)
		cpu.cpsr.set_n(value >> 31 == 1)
	}
	return value
}

fn (mut cpu Cpu) add(op1 u32, op2 u32, flags bool) u32 {
	res := op1 + op2

	if flags {
		cpu.cpsr.set_z(res == 0)
		cpu.cpsr.set_n(res >> 31 == 1)
		cpu.cpsr.set_c(u64(op1) + u64(op2) > 0xffff_ffff)
		cpu.cpsr.set_v(overflow_from_add(op1, op2, res))
	}

	return res
}

fn (mut cpu Cpu) sub(op1 u32, op2 u32, flags bool) u32 {
	res := op1 - op2

	if flags {
		cpu.cpsr.set_z(res == 0)
		cpu.cpsr.set_n(res >> 31 == 1)
		cpu.cpsr.set_c(op2 <= op1)
		cpu.cpsr.set_v(overflow_from_sub(op1, op2, res))
	}

	return res
}

fn (mut cpu Cpu) adc(op1 u32, op2 u32, flags bool) u32 {
	opc := u64(op2) + u64(cpu.cpsr.c())
	res := u32(op1 + opc)

	if flags {
		cpu.cpsr.set_z(res == 0)
		cpu.cpsr.set_n(res >> 31 == 1)
		cpu.cpsr.set_c(u64(op1) + opc > u64(0xffff_ffff))
		cpu.cpsr.set_v(overflow_from_add(op1, op2, res))
	}

	return res
}

fn (mut cpu Cpu) sbc(op1 u32, op2 u32, flags bool) u32 {
	opc := u64(op2) - u64(cpu.cpsr.c()) + 1
	res := u32(op1 - opc)

	if flags {
		cpu.cpsr.set_z(res == 0)
		cpu.cpsr.set_z(res >> 31 == 1)
		cpu.cpsr.set_c(opc <= op1)
		cpu.cpsr.set_v(overflow_from_sub(op1, op2, res))
	}

	return res
}
