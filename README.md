# 32-Bit Custom MIPS-Style Single-Cycle CPU

A synthesizable, 32-bit single-cycle processor designed originally in Logisim Evolution and translated into idiomatic Verilog (IEEE 1364-2001). The repository includes the complete hardware RTL, self-checking testbenches, and a custom C-based two-pass assembler and disassembler toolchain operating with Big-Endian binary encoding.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Instruction Set Architecture (ISA)](#instruction-set-architecture-isa)
  - [Instruction Formats](#instruction-formats)
  - [Supported Instructions](#supported-instructions)
- [Repository Structure](#repository-structure)
- [Toolchain (Assembler & Disassembler)](#toolchain-assembler--disassembler)
  - [Building the Tools](#building-the-tools)
  - [Assembling Programs](#assembling-programs)
  - [Disassembling Binaries](#disassembling-binaries)
  - [Simulation & Verification](#simulation--verification)
  - [Prerequisites](#prerequisites)
  - [Running the CPU Simulation](#running-the-cpu-simulation)
  - [Viewing Waveforms](#viewing-waveforms)
- [Logisim Translation Notes](#logisim-translation-notes)

---

## Architecture Overview

The CPU implements a classic single-cycle datapath executing one instruction per clock edge:

- **Word Size:** 32-bit datapath and memory access.
- **Register File:** 32 general-purpose registers (`X0` to `X31`), each 32 bits wide. `X0` is hardwired to `0`. Dual asynchronous read ports and a single synchronous write port.
- **ALU:** Supports arithmetic, logical, shift operations, signed comparisons (`SLT`), and hardware multiplication (`MUL`).
- **Control Unit:** Microcoded ROM lookup table driving datapath enables and multiplexers, paired with an auxiliary `alu_decoder`.
- **Memory Architecture:**
  - **Instruction Memory (ROM):** 1024-word memory preloaded with big-endian machine words.
  - **Data Memory (RAM):** 1024-word synchronous write, asynchronous read RAM.
- **Endianness:** Big-Endian byte ordering across all binaries, assembler outputs, and Verilog `$fread` loaders.

---

## Instruction Set Architecture (ISA)

### Instruction Formats

#### R-Type (Register)
```
 31       26 25     21 20     16 15     11 10                       0
+-----------+---------+---------+---------+--------------------------+
|  Opcode   |   Rs    |   Rt    |   Rd    |          Funct           |
|  (6 bits) | (5 bits)| (5 bits)| (5 bits)|         (11 bits)        |
+-----------+---------+---------+---------+--------------------------+
```

#### I-Type (Immediate)
```
 31       26 25     21 20     16 15                                0
+-----------+---------+---------+----------------------------------+
|  Opcode   |   Rs    |  Rt/Rd  |            Immediate             |
|  (6 bits) | (5 bits)| (5 bits)|            (16 bits)             |
+-----------+---------+---------+----------------------------------+
```

#### J-Type (Jump)
```
 31       26 25                                                    0
+-----------+------------------------------------------------------+
|  Opcode   |                     Jump Target                      |
|  (6 bits) |                      (26 bits)                       |
+-----------+------------------------------------------------------+
```

---

### Supported Instructions

| Mnemonic | Type | Opcode | Funct | Description |
| :--- | :---: | :---: | :---: | :--- |
| **`ADD`**  | R | `0x00` | `0x000` | `Rd = Rs + Rt` |
| **`SUB`**  | R | `0x00` | `0x001` | `Rd = Rs - Rt` |
| **`AND`**  | R | `0x00` | `0x002` | `Rd = Rs & Rt` |
| **`OR`**   | R | `0x00` | `0x003` | `Rd = Rs \| Rt` |
| **`XOR`**  | R | `0x00` | `0x004` | `Rd = Rs ^ Rt` |
| **`SLL`**  | R | `0x00` | `0x005` | `Rd = Rs << Rt[4:0]` |
| **`SRL`**  | R | `0x00` | `0x006` | `Rd = Rs >> Rt[4:0]` (Logical) |
| **`SRA`**  | R | `0x00` | `0x007` | `Rd = Rs >>> Rt[4:0]` (Arithmetic) |
| **`SLT`**  | R | `0x00` | `0x008` | `Rd = (Rs < Rt) ? 1 : 0` (Signed) |
| **`MUL`**  | R | `0x00` | `0x009` | `Rd = (Rs * Rt)[31:0]` |
| **`ADDI`** | I | `0x01` | — | `Rt = Rs + SignExt(Imm)` |
| **`ANDI`** | I | `0x02` | — | `Rt = Rs & ZeroExt(Imm)` |
| **`ORI`**  | I | `0x03` | — | `Rt = Rs \| ZeroExt(Imm)` |
| **`LUI`**  | I | `0x04` | — | `Rt = Imm << 16` |
| **`LW`**   | I | `0x05` | — | `Rt = Memory[Rs + SignExt(Imm)]` |
| **`SW`**   | I | `0x06` | — | `Memory[Rs + SignExt(Imm)] = Rt` |
| **`BEQ`**  | I | `0x07` | — | `if (Rs == Rt) PC = PC + 4 + ByteOffset` |
| **`BNE`**  | I | `0x08` | — | `if (Rs != Rt) PC = PC + 4 + ByteOffset` |
| **`J`**    | J | `0x09` | — | `PC = {PC[31:26], JumpAddr[25:0]}` |
| **`JAL`**  | J | `0x0A` | — | `X31 = PC + 4; PC = {PC[31:26], JumpAddr}` |
| **`JR`**   | R | `0x0B` | — | `PC = Rs` |

*Note: The assembler also provides a software pseudo-instruction `DIV Rd, Rs, Rt` expanded via preprocessor macros using non-restoring subtraction.*

---

## Repository Structure

```
├── README.md               # Project documentation
├── cpu.v               # Top-level datapath, PC, RAM, and fetch unit
├── decoder.v           # Instruction bit-splitter module
├── control.v           # Main ROM control unit
├── alu_decoder.v       # ALU control signal generator
├── register.v          # 32x32-bit register file (dual read, sync write)
├── tb_cpu.v            # Top-level self-checking CPU testbench
└── alu.v               # 32-bit Arithmetic Logic Unit

```
---

## Simulation & Verification

### Prerequisites

- [Icarus Verilog (`iverilog`)](http://iverilog.icarus.com/) (version 10.0 or later)
- [GTKWave](http://gtkwave.sourceforge.net/) (for inspecting `.vcd` waveform traces)


The simulation will load `rom.bin` from the current working directory, print a cycle-by-cycle execution trace with program counter and core register values, and display a final register dump when the loop terminates.

### Viewing Waveforms

```bash
gtkwave cpu_waves.vcd
```

Add `uut.pc`, `uut.instr`, `uut.alu_result`, and `uut.u_registers.rf` to observe datapath transitions.

---

## Logisim Translation Notes

When porting designs from Logisim Evolution to synthesizable Verilog:
1. **Asynchronous Memory:** Logisim’s default asynchronous RAM blocks trigger FPGA synthesis errors; the Verilog implementation replaces them with clocked block-RAM compatible RTL.
2. **Jump Offsets:** Logisim diagrams frequently wire addresses directly as absolute bytes; avoid double-shifting jump addresses in hardware if your assembler already calculates byte offsets.
3. **Sign Extension:** Differentiate zero-extended bitwise immediates (`ANDI`, `ORI`) from sign-extended arithmetic offsets (`ADDI`, `LW`, `SW`, `BEQ`, `BNE`) inside the immediate generation unit.