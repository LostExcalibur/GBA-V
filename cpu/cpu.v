module cpu

import cpu.psr
import cpu.arm

pub struct Cpu {
mut:
	gpr [15]u32
	pc  u32
pub mut:
	cpsr psr.CPSR
}

pub fn new() Cpu {
	mut cpu := Cpu{
		cpsr: psr.new(0)
	}
	cpu.cpsr.set_mode(.system)
	cpu.cpsr.set_state(.arm)
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

pub fn should_execute(cond arm.ArmCond, cpsr psr.CPSR) bool {
	return match cond {
		.eq {
			cpsr.z()
		}
		.ne {
			!cpsr.z()
		}
		.hs {
			cpsr.c()
		}
		.lo {
			!cpsr.c()
		}
		.mi {
			cpsr.n()
		}
		.pl {
			!cpsr.n()
		}
		.vs {
			cpsr.v()
		}
		.vc {
			!cpsr.v()
		}
		.hi {
			cpsr.c() && !cpsr.z()
		}
		.ls {
			!cpsr.c() || cpsr.z()
		}
		.ge {
			cpsr.v() == cpsr.n()
		}
		.lt {
			cpsr.v() != cpsr.n()
		}
		.gt {
			!cpsr.z() && (cpsr.v() == cpsr.n())
		}
		.le {
			cpsr.z() || (cpsr.v() != cpsr.n())
		}
		.al {
			true
		}
		.invalid {
			false
		}
	}
}
