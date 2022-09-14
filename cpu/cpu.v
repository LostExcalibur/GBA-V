module cpu

import cpu.arm
import cpu.cpu_enums
import cpu.psr
import sysbus

pub struct Cpu {
mut:
	gpr     [15]u32
	verbose bool
	sysbus  &sysbus.Sysbus
pub mut:
	banked_regs psr.BankedRegs
	pc          u32
	cpsr        psr.CPSR
	spsr        psr.CPSR
}

pub fn new(mut bus sysbus.Sysbus) Cpu {
	mut cpu := Cpu{
		sysbus: bus
		cpsr: psr.new(0x0000_00df) // Equivalent to ARM and SYSTEM
		pc: 0
		gpr: [15]u32{init: 0}
		spsr: psr.new(0)
	}
	return cpu
}

pub fn (mut cpu Cpu) skip_bios() {
	cpu.gpr[13] = 0x0300_7f00
	cpu.pc = 0x0800_0000
	cpu.banked_regs.banked_r13[0] = 0x0300_7f00 // USR/SYS
	cpu.banked_regs.banked_r13[1] = 0x0300_7f00 // FIQ
	cpu.banked_regs.banked_r13[2] = 0x0300_7fa0 // IRQ
	cpu.banked_regs.banked_r13[3] = 0x0300_7fe0 // SVC
	cpu.banked_regs.banked_r13[4] = 0x0300_7f00 // ABT
	cpu.banked_regs.banked_r13[5] = 0x0300_7f00 // UND

	cpu.cpsr = psr.new(0x5f)
}

pub fn (cpu Cpu) get_word_size() u32 {
	return match cpu.cpsr.get_state() {
		.arm { 4 }
		.thumb { 2 }
	}
}

pub fn (mut cpu Cpu) reset() {
	cpu.exception(.reset, 0)
}

pub fn (cpu Cpu) should_execute(insn &arm.ArmInstruction) bool {
	return match insn.cond {
		.eq {
			cpu.cpsr.z()
		}
		.ne {
			!cpu.cpsr.z()
		}
		.hs {
			cpu.cpsr.c()
		}
		.lo {
			!cpu.cpsr.c()
		}
		.mi {
			cpu.cpsr.n()
		}
		.pl {
			!cpu.cpsr.n()
		}
		.vs {
			cpu.cpsr.v()
		}
		.vc {
			!cpu.cpsr.v()
		}
		.hi {
			cpu.cpsr.c() && !cpu.cpsr.z()
		}
		.ls {
			!cpu.cpsr.c() || cpu.cpsr.z()
		}
		.ge {
			cpu.cpsr.v() == cpu.cpsr.n()
		}
		.lt {
			cpu.cpsr.v() != cpu.cpsr.n()
		}
		.gt {
			!cpu.cpsr.z() && (cpu.cpsr.v() == cpu.cpsr.n())
		}
		.le {
			cpu.cpsr.z() || (cpu.cpsr.v() != cpu.cpsr.n())
		}
		.al {
			true
		}
		.invalid {
			false
		}
	}
}

pub fn (cpu Cpu) get_reg(num u32) u32 {
	return match num {
		0...14 { cpu.gpr[num] }
		15 { cpu.pc }
		else { panic('Unknown register $num') }
	}
}

pub fn (mut cpu Cpu) set_reg(num u32, val u32) {
	match num {
		0...14 { cpu.gpr[num] = val }
		15 { cpu.pc = val }
		else { panic('Unknown register $num') }
	}
}

pub fn (mut cpu Cpu) set_verbose(value bool) {
	cpu.verbose = value
}

pub fn (mut cpu Cpu) change_mode(curr_mode cpu_enums.CpuMode, new_mode cpu_enums.CpuMode) {
	next_idx := cpu_enums.bank_index(new_mode)
	curr_idx := cpu_enums.bank_index(curr_mode)

	if next_idx == curr_idx {
		return
	}

	cpu.banked_regs.banked_r13[curr_idx] = cpu.gpr[13]
	cpu.banked_regs.banked_r14[curr_idx] = cpu.gpr[14]
	cpu.banked_regs.banked_spsr[curr_idx] = cpu.spsr

	cpu.gpr[13] = cpu.banked_regs.banked_r13[next_idx]
	cpu.gpr[14] = cpu.banked_regs.banked_r14[next_idx]
	cpu.spsr = cpu.banked_regs.banked_spsr[next_idx]

	if new_mode == .fiq {
		for r in 8 .. 13 {
			cpu.banked_regs.banked_r8_12_old[r - 8] = cpu.gpr[r]
			cpu.gpr[r] = cpu.banked_regs.banked_r8_12_fiq[r - 8]
		}
	} else if curr_mode == .fiq {
		for r in 8 .. 13 {
			cpu.banked_regs.banked_r8_12_fiq[r - 8] = cpu.gpr[r]
			cpu.gpr[r] = cpu.banked_regs.banked_r8_12_old[r - 8]
		}
	}

	cpu.cpsr.set_mode(new_mode)
}

pub fn (mut cpu Cpu) advance_pc() {
	cpu.pc += cpu.get_word_size()
}

pub fn (mut cpu Cpu) step() {
	action := match cpu.cpsr.get_state() {
		.arm { cpu.step_arm() }
		.thumb { panic('Not implemented yet') }
	}
	if action == .sequential {
		cpu.advance_pc()
	}
}

pub fn (mut cpu Cpu) step_arm() cpu_enums.CpuPipelineAction {
	insn := cpu.sysbus.read_32(cpu.pc)

	decoded := arm.new(insn, cpu.pc)
	if cpu.verbose {
		println(decoded)
	}

	if _unlikely_(decoded.cond != .al) {
		if !cpu.should_execute(decoded) {
			return .sequential
		}
	}
	return cpu.exec_arm(decoded)
}
