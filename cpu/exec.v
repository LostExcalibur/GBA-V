module cpu

import cpu.arm
import cpu.cpu_enums
import cpu.regshift
import sysbus

pub fn (mut cpu Cpu) exec_b_bl(insn &arm.ArmInstruction) cpu_enums.CpuPipelineAction {
	if cpu.verbose {
		println('Executing branch link')
	}
	if insn.link_flag() {
		cpu.set_reg(14, cpu.pc & ~0x1)
	}
	cpu.pc = u32(i64(cpu.pc) + insn.branch_offset())
	return .branch
}

pub fn (mut cpu Cpu) exec_bx(insn &arm.ArmInstruction) cpu_enums.CpuPipelineAction {
	if cpu.verbose {
		println('Executing branch exchange')
	}
	mut addr := cpu.get_reg(insn.rm())
	// Switch to thumb
	if insn.bits.get_bit(31) == 1 {
		addr = addr & ~0x1 // Address aligning
		cpu.cpsr.set_state(.thumb)
	}
	// Switch to ARM
	else {
		addr = addr & ~0x3 // Address aligning
		cpu.cpsr.set_state(.arm)
	}
	cpu.pc = addr
	return .branch
}

[inline]
pub fn (mut cpu Cpu) exec_swi(address u32) cpu_enums.CpuPipelineAction {
	if cpu.verbose {
		println('Executing software interrupt')
	}
	cpu.exception(.software_interrupt, address)
	return .branch
}

pub fn (mut cpu Cpu) exec_data_processing(insn &arm.ArmInstruction) cpu_enums.CpuPipelineAction {
	if cpu.verbose {
		println('Executing data processing')
	}
	op1 := cpu.get_reg(insn.rn())
	oper2 := insn.operand2()
	rd := insn.rd()
	flags := insn.sets_cond_flags() && rd != 15

	op2 := match oper2 {
		regshift.RotatedImmediate { regshift.rotate_right(oper2.immediate, oper2.rotate) }
		regshift.ArmShiftedRegister { cpu.register_shift(oper2.reg, oper2.shift, flags) }
		else { panic('unreachable') }
	}

	opcode := insn.opcode()

	mut res := u32(0)

	match opcode {
		.and { res = cpu.log(op1 & op2, flags) }
		.eor { res = cpu.log(op1 ^ op2, flags) }
		.orr { res = cpu.log(op1 | op2, flags) }
		.mov { res = cpu.log(op2, flags) }
		.bic { res = cpu.log(op1 & (~op2), flags) }
		.mvn { res = cpu.log(~op2, flags) }
		.tst { cpu.log(op1 & op2, true) }
		.teq { cpu.log(op1 ^ op2, true) }
		.cmn { cpu.add(op1, op2, true) }
		.cmp { cpu.sub(op1, op2, true) }
		.add { res = cpu.add(op1, op2, flags) }
		.adc { res = cpu.adc(op1, op2, flags) }
		.sub { res = cpu.sub(op1, op2, flags) }
		.sbc { res = cpu.sbc(op1, op2, flags) }
		.rsb { res = cpu.sub(op2, op1, flags) }
		.rsc { res = cpu.sbc(op2, op1, flags) }
	}
	match opcode {
		.cmp, .cmn, .teq, .tst {}
		else { cpu.set_reg(rd, res) }
	}

	if rd == 15 {
		if insn.sets_cond_flags() {
			cpu.change_mode(cpu.cpsr.get_mode(), cpu.spsr.get_mode())
			cpu.cpsr = cpu.spsr
		}
		return match opcode {
			.cmp, .cmn, .teq, .tst { .sequential }
			else { .branch }
		}
	}
	return .sequential
}

pub fn (mut cpu Cpu) exec_single_data_transfer(insn &arm.ArmInstruction, mut bus sysbus.Sysbus) cpu_enums.CpuPipelineAction {
	rn := insn.rn()
	rd := insn.rd()

	mut addr := cpu.get_reg(rn)

	load := insn.bits.get_bit(11) == 1
	write_back := insn.bits.get_bit(10) == 1
	ubyte := insn.bits.get_bit(9) == 1
	substracted := insn.bits.get_bit(8) == 0
	pre_index := insn.bits.get_bit(7) == 1

	encoded_offset := insn.ldr_str_offset()

	mut offset := match encoded_offset {
		regshift.ImmediateValue {
			u32(encoded_offset)
		}
		regshift.ArmShiftedRegister {
			cpu.register_shift(encoded_offset.reg, encoded_offset.shift, false)
		}
		else {
			panic('Unreachable')
		}
	}

	if substracted {
		offset = twos_complement(offset)
	}

	if pre_index {
		addr += offset
	}

	if load {
		if ubyte {
			cpu.set_reg(rd, u32(bus.read_8(addr)))
		} else {
			cpu.set_reg(rd, bus.read_32_rotate(addr))
		}
	} else {
		value := cpu.get_reg(rd)

		if ubyte {
			bus.write_8(addr, u8(value))
		} else {
			bus.write_32(addr, value)
		}
	}
	return .sequential
}

pub fn (mut cpu Cpu) exec_arm(insn &arm.ArmInstruction, mut bus sysbus.Sysbus) cpu_enums.CpuPipelineAction {
	match insn.format {
		.branch_link {
			return cpu.exec_b_bl(insn)
		}
		.branch_exchange {
			return cpu.exec_bx(insn)
		}
		.software_interrupt {
			return cpu.exec_swi(insn.address)
		}
		.data_processing {
			return cpu.exec_data_processing(insn)
		}
		.single_data_transfer {
			return cpu.exec_single_data_transfer(insn, mut bus)
		}
		else {
			panic('Not implement yet : $insn.format')
		}
	}
}
