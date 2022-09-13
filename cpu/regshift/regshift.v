module regshift

import cpu.cpu_enums
import bitfield as bf

[inline]
pub fn rotate_right(value u32, amount u32) u32 {
	return (value >> amount) | (value << (32 - amount))
}

[inline]
pub fn asr(value u32, amount u32) u32 {
	return if value >> 31 == 1 { ~(~value >> amount) } else { value >> amount }
}

pub struct RotatedImmediate {
pub:
	immediate u32
	rotate    u16
}

pub type ImmediateValue = u32

pub struct ShiftAmount {
pub:
	amount u32
	typ    cpu_enums.ArmShiftType
}

pub struct ShiftRegister {
pub:
	reg u32
	typ cpu_enums.ArmShiftType
}

pub type RegisterShift = ShiftAmount | ShiftRegister

pub struct ArmShiftedRegister {
pub:
	reg   u32
	shift RegisterShift
}

pub fn (self ArmShiftedRegister) is_lsl0() bool {
	return match self.shift {
		ShiftAmount {
			self.shift.amount == 0 && self.shift.typ == .lsl
		}
		else {
			true
		}
	}
}

pub fn (self ArmShiftedRegister) str() string {
	reg := 'R$self.reg'
	if !self.is_lsl0() {
		return reg
	} else {
		match self.shift {
			ShiftAmount { return '$reg, $self.shift.typ, #$self.shift.amount' }
			ShiftRegister { return '$reg, $self.shift.typ, R$self.shift.reg' }
		}
	}
}

pub fn regshift_from(raw &bf.BitField) RegisterShift {
	typ := cpu_enums.ArmShiftType(raw.extract(26, 2))
	if raw.get_bit(27) == 1 {
		return ShiftRegister{u32(raw.extract(20, 4)), typ}
	}
	return ShiftAmount{u32(raw.extract(20, 5)), typ}
}

pub type ShiftedValue = ArmShiftedRegister | ImmediateValue | RotatedImmediate

pub fn decode_rotated_immediate(shift ShiftedValue) ?u32 {
	match shift {
		RotatedImmediate {
			return rotate_right(shift.immediate, shift.rotate)
		}
		else {
			return none
		}
	}
}
