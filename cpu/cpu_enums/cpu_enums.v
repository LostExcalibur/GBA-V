module cpu_enums

pub enum CpuState {
	arm = 0
	thumb = 1
}

pub fn (state CpuState) str() string {
	return match state {
		.arm { 'ARM' }
		.thumb { 'THUMB' }
	}
}

pub enum CpuMode {
	user = 0b10000
	fiq = 0b10001
	irq = 0b10010
	supervisor = 0b10011
	abort = 0b10111
	undefined = 0b11011
	system = 0b11111
}

pub fn spsr_index(mode CpuMode) ?int {
	return match mode {
		.fiq, .irq, .supervisor, .abort, .undefined { int(mode) - 17 }
		else { none }
	}
}

pub fn bank_index(mode CpuMode) int {
	return match mode {
		.user, .system { 0 }
		else { int(mode) - 16 }
	}
}

pub enum CpuPipelineAction {
	sequential
	branch
}

pub enum ArmShiftType {
	lsl = 0
	lsr = 1
	asr = 2
	ror = 3
}

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
