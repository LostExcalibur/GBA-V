module cpu_enums

pub enum CpuState {
	arm = 0
	thumb = 1
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
