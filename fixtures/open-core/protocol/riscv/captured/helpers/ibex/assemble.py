#!/usr/bin/env python3
# SPDX-License-Identifier: 0BSD
"""Hand-assemble the tiny RV32I program used by tb_ibex_rvfi.sv.

No RISC-V toolchain is required: this script encodes the handful of RV32I
instructions the capture needs and writes a $readmemh image.

Memory map (1 KiB, byte addresses 0x000-0x3FF):
  0x000  trap handler (Ibex mtvec resets to boot_addr_i, vectored)
  0x080  reset vector  (Ibex resets to boot_addr_i + 0x80)
  0x200  data scratch
"""

import sys

MEM_WORDS = 256


def r(rd, rs1, rs2, funct3, funct7, opcode=0b0110011):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def i(rd, rs1, imm, funct3, opcode=0b0010011):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def s(rs1, rs2, imm, funct3, opcode=0b0100011):
    imm &= 0xFFF
    return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | \
        (funct3 << 12) | ((imm & 0x1F) << 7) | opcode


def b(rs1, rs2, imm, funct3, opcode=0b1100011):
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | \
        (rs1 << 15) | (funct3 << 12) | (((imm >> 1) & 0xF) << 8) | \
        (((imm >> 11) & 1) << 7) | opcode


def addi(rd, rs1, imm):
    return i(rd, rs1, imm, 0b000)


def add(rd, rs1, rs2):
    return r(rd, rs1, rs2, 0b000, 0b0000000)


def sub(rd, rs1, rs2):
    return r(rd, rs1, rs2, 0b000, 0b0100000)


def xor_(rd, rs1, rs2):
    return r(rd, rs1, rs2, 0b100, 0b0000000)


def sw(rs2, imm, rs1):
    return s(rs1, rs2, imm, 0b010)


def sh(rs2, imm, rs1):
    return s(rs1, rs2, imm, 0b001)


def sb(rs2, imm, rs1):
    return s(rs1, rs2, imm, 0b000)


def lw(rd, imm, rs1):
    return i(rd, rs1, imm, 0b010, 0b0000011)


def lhu(rd, imm, rs1):
    return i(rd, rs1, imm, 0b101, 0b0000011)


def lbu(rd, imm, rs1):
    return i(rd, rs1, imm, 0b100, 0b0000011)


def beq(rs1, rs2, imm):
    return b(rs1, rs2, imm, 0b000)


def bne(rs1, rs2, imm):
    return b(rs1, rs2, imm, 0b001)


def csrrs(rd, csr, rs1):
    return i(rd, rs1, csr, 0b010, 0b1110011)


ECALL = 0x00000073
WFI = 0x10500073

CSR_MCAUSE = 0x342
CSR_MEPC = 0x341

# (byte address, word, assembly text)
HANDLER = [
    (0x000, csrrs(12, CSR_MCAUSE, 0), 'csrrs x12, mcause, x0'),
    (0x004, csrrs(13, CSR_MEPC, 0), 'csrrs x13, mepc, x0'),
    (0x008, addi(14, 0, 42), 'addi x14, x0, 42'),
    (0x00C, WFI, 'wfi'),
]

MAIN = [
    (0x080, addi(1, 0, 0x123), 'addi x1, x0, 0x123'),
    (0x084, addi(2, 0, 0x456), 'addi x2, x0, 0x456'),
    (0x088, add(3, 1, 2), 'add x3, x1, x2'),
    (0x08C, sub(4, 2, 1), 'sub x4, x2, x1'),
    (0x090, addi(5, 0, 0x200), 'addi x5, x0, 0x200'),
    (0x094, sw(3, 0, 5), 'sw x3, 0(x5)'),
    (0x098, lw(6, 0, 5), 'lw x6, 0(x5)'),
    (0x09C, beq(3, 6, 8), 'beq x3, x6, +8'),
    (0x0A0, addi(7, 0, -1), 'addi x7, x0, -1  (skipped)'),
    (0x0A4, addi(8, 0, 0x5A), 'addi x8, x0, 0x5a'),
    (0x0A8, sb(8, 4, 5), 'sb x8, 4(x5)'),
    (0x0AC, lbu(9, 4, 5), 'lbu x9, 4(x5)'),
    (0x0B0, sh(3, 8, 5), 'sh x3, 8(x5)'),
    (0x0B4, lhu(10, 8, 5), 'lhu x10, 8(x5)'),
    (0x0B8, xor_(11, 3, 4), 'xor x11, x3, x4'),
    (0x0BC, addi(15, 0, 3), 'addi x15, x0, 3'),
    (0x0C0, addi(15, 15, -1), 'addi x15, x15, -1   (loop:)'),
    (0x0C4, bne(15, 0, -4), 'bne x15, x0, -4'),
    (0x0C8, ECALL, 'ecall'),
]


def main():
    mem = [0x00000000] * MEM_WORDS
    for addr, word, _text in HANDLER + MAIN:
        mem[addr >> 2] = word

    out = sys.argv[1] if len(sys.argv) > 1 else 'prog.hex'
    with open(out, 'w') as fh:
        for word in mem:
            fh.write('%08x\n' % word)

    listing = sys.argv[2] if len(sys.argv) > 2 else 'prog.lst'
    with open(listing, 'w') as fh:
        fh.write('# addr      word        assembly\n')
        for addr, word, text in HANDLER + MAIN:
            fh.write('0x%03x   0x%08x   %s\n' % (addr, word, text))

    print('wrote %s (%d words) and %s' % (out, MEM_WORDS, listing))


if __name__ == '__main__':
    main()
