module cpu

import cpu.cpu_enums

pub enum Exception {
	reset = 0x0
	undefined_instruction = 0x4
	software_interrupt = 0x8
	prefetch_abort = 0xc
	data_abort = 0x10
	reserved = 0x14 // "not normally used and reserved for future expansion"
	irq = 0x18
	fiq = 0x1c
}

pub fn (mut cpu Cpu) exception(ex Exception, link_reg u32) {
	// Because a match expression results in a cgen error...
	new_mode, irq_disabled, fiq_disabled := if ex == .reset {
		cpu_enums.CpuMode.supervisor, false, false
	} else if ex == .undefined_instruction {
		cpu_enums.CpuMode.undefined, false, false
	} else if ex == .software_interrupt {
		cpu_enums.CpuMode.supervisor, true, false
	} else if ex == .prefetch_abort {
		cpu_enums.CpuMode.abort, true, false
	} else if ex == .data_abort {
		cpu_enums.CpuMode.abort, true, false
	} else if ex == .irq {
		cpu_enums.CpuMode.irq, true, false
	} else if ex == .fiq {
		cpu_enums.CpuMode.fiq, true, true
	} else {
		panic('Cpu resereved instruction')
	}

	new_bank := cpu_enums.bank_index(new_mode)
	println('Hello, $new_bank')
	cpu.banked_regs.banked_spsr[new_bank] = cpu.cpsr
	cpu.banked_regs.banked_r14[new_bank] = link_reg
	cpu.change_mode(cpu.cpsr.get_mode(), new_mode)

	cpu.cpsr.set_state(.arm)
	cpu.cpsr.set_mode(new_mode)

	if irq_disabled {
		cpu.cpsr.set_irq_disabled(true)
	}
	if fiq_disabled {
		cpu.cpsr.set_fiq_disabled(true)
	}

	cpu.pc = u32(ex)
}
