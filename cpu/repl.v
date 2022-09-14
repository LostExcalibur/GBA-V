module cpu

import os
import cpu.arm

pub fn (cpu Cpu) registers_string() string {
	mut s := 'r0 : 0x${cpu.gpr[0]:x}, r1 : 0x${cpu.gpr[1]:x}, r2 : 0x${cpu.gpr[2]:x}, r3 : 0x${cpu.gpr[3]:x}, r4 : 0x${cpu.gpr[4]:x}, r5 : 0x${cpu.gpr[5]:x},'
	s += ' r6 : 0x${cpu.gpr[6]:x}, r7 : 0x${cpu.gpr[7]:x}, r8 : 0x${cpu.gpr[8]:x}, r9 : 0x${cpu.gpr[9]:x}, r10 : 0x${cpu.gpr[10]:x},'
	s += ' r11 : 0x${cpu.gpr[11]:x}, r12 : 0x${cpu.gpr[12]:x}, r13 : 0x${cpu.gpr[13]:x}, r14 : 0x${cpu.gpr[14]:x}'
	return s
}

pub fn (cpu Cpu) print_state() {
	mut s := 'Registers :\n$cpu.registers_string()\n'
	s += 'PC : 0x${(cpu.pc):x}\n'
	s += 'Status : $cpu.cpsr'
	println(s)
}

pub fn (mut cpu Cpu) start_repl() {
	println('Starting repl...')
	cpu.print_state()

	mut insn := cpu.sysbus.read_32(cpu.pc)
	mut decoded := arm.new(insn, cpu.pc)

	for {
		line := (os.input_opt('GBA-V>> ') or {
			println('\nQuitting...')
			return
		}).trim_space()
		if line == '' {
			continue
		}

		insn = cpu.sysbus.read_32(cpu.pc)
		decoded = arm.new(insn, cpu.pc)

		s := line.split(' ')

		match s[0] {
			's' {
				cpu.step()
			}
			'n', 'nd' {
				for !cpu.should_execute(decoded) {
					cpu.step()
					insn = cpu.sysbus.read_32(cpu.pc)
					decoded = arm.new(insn, cpu.pc)
				}
				if s[0] == 'n' {
					cpu.step()
				}
			}
			'i', 'ir' {
				if s[0] == 'ir' {
					println('${insn:x}')
					continue
				}
				println(decoded)
				continue
			}
			'e' {
				print('Instruction will ')
				if !cpu.should_execute(decoded) {
					print('not ')
				}
				println('execute')
				continue
			}
			'p' {
				if s.len <= 2 {
					println('Syntax : p <size : 8 | 32> <address>')
					continue
				}
				mut addr := u32(0)
				if s[2] == 'pc' {
					addr = cpu.pc
				} else {
					addr = u32(s[2].int())
				}
				match s[1].int() {
					8 {
						read := cpu.sysbus.read_8(addr)
						println('${read:x}')
						continue
					}
					16 {
						println('16 bit reads and writes are unsupported for now')
						continue
						// cpu.sysbus.read_16(u32(s[2].int()))
					}
					32 {
						read := cpu.sysbus.read_32(addr)
						println('${read:x}')
						continue
					}
					else {
						println('Unsupported data size : ${s[1].int()}')
						continue
					}
				}
			}
			'c' {
				print('\e[1;1H\e[2J')
			}
			'q' {
				println('Quitting...')
				return
			}
			else {
				println('Unsupported instruction : ${s[0]}')
			}
		}
		cpu.print_state()
	}
}
