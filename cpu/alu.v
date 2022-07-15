module cpu

import cpu.arm
import sysbus

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

pub fn (cpu Cpu) exec_alu(insn &arm.ArmInstruction, bus &sysbus.Sysbus) {
}
