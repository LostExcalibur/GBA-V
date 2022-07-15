module cpu

import cpu.arm
import sysbus

pub fn (mut cpu Cpu) exec_arm(insn arm.ArmInstruction, bus sysbus.Sysbus) {
	match insn.format {
		.branch_link {
			println('Executing branch link')
			if insn.link_flag() {
				cpu.set_reg(14, cpu.pc & ~0x1)
			}
			cpu.pc = u32(i64(cpu.pc) + insn.branch_offset())
		}
		.branch_exchange {
			println('Executing branch exchange')
			mut addr := cpu.get_reg(insn.rn())
			// Switch to thumb
			if insn.bits.get_bit(31) == 1 {
				addr = addr & ~0x1
				cpu.cpsr.set_state(.thumb)
			}
			// Switch to ARM
			else {
				addr = addr & ~0x3
				cpu.cpsr.set_state(.arm)
			}
			cpu.pc = addr
		}
		else {
			panic('Not implement yet : $insn.format')
		}
	}
}
