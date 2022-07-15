module cpu

import cpu.psr
import cpu.arm
import sysbus

pub struct Cpu {
mut:
	gpr [14]u32
pub mut:
	pc   u32
	cpsr psr.CPSR
}

pub fn new() Cpu {
	mut cpu := Cpu{
		cpsr: psr.new(0x0000_00d3)
		pc: 0
		gpr: [14]u32{init: 0}
	}
	return cpu
}

pub fn (cpu Cpu) get_word_size() u64 {
	return match cpu.cpsr.state() {
		.arm { 4 }
		.thumb { 2 }
	}
}

pub fn (mut cpu Cpu) reset() {
	cpu.pc = 0
	cpu.cpsr.set_mode(.system)
	cpu.cpsr.set_state(.arm)
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

pub fn (mut cpu Cpu) step(bus &sysbus.Sysbus) {
	match cpu.cpsr.state() {
		.arm { cpu.step_arm(bus) }
		.thumb { panic('Not implemented yet') }
	}
}

pub fn (mut cpu Cpu) step_arm(bus &sysbus.Sysbus) {
	insn := bus.read_32(cpu.pc)
	decoded := arm.new(insn, cpu.pc)
	println(decoded)
	if _unlikely_(decoded.cond != .al) {
		if !cpu.should_execute(decoded) {
			cpu.pc += 4
			return
		}
	}
	cpu.exec_arm(decoded, bus)
}