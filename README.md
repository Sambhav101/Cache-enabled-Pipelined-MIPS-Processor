# Cache-enabled Pipelined MIPS Processor

A fully functional 32-bit, five-stage pipelined MIPS processor implemented in Verilog, featuring a complete hazard detection and forwarding unit, and a pluggable data cache subsystem with both direct-mapped and 2-way set-associative implementations.

---

## Architecture Overview

The processor implements the classic **IF → ID → EX → MEM → WB** pipeline with all major hazard types handled in hardware. The data memory is accessed through a cache that issues stall signals to freeze the entire pipeline on a miss.

```
  ┌────┐   ┌────┐   ┌────┐   ┌─────┐   ┌────┐
  │ IF │──▶│ ID │──▶│ EX │──▶│ MEM │──▶│ WB │
  └────┘   └────┘   └────┘   └─────┘   └────┘
              ▲        ▲         │
              │        │         │
         ┌────────────────┐      │
         │  Hazard Unit   │      │
         │  Forwarding    │◀─────┘
         └────────────────┘
```

---

## Pipeline Stages

### IF — Instruction Fetch
- The **Program Counter (PC)** is updated each cycle to `PC + 4`, or redirected to a branch target when a branch is taken.
- Instructions are fetched from a synchronous **instruction memory** (`instr_mem.v`).
- The **IF/ID pipeline register** (`if_id_reg.v`) holds the fetched instruction and `PC+4`. It supports stalling (hold) and flushing (NOP injection) for hazard management.

### ID — Instruction Decode
- The instruction is decoded to extract `opcode`, `rs`, `rt`, `rd`, `shamt`, and `funct` fields.
- The **Control Unit** (`control_unit.v`) generates all datapath control signals: `RegDst`, `ALUSrc`, `MemtoReg`, `RegWrite`, `MemRead`, `MemWrite`, `Branch`, `Jump`, `Jal`, `Jr`.
- The **Register File** (`regfile.v`) performs a synchronous write (WB stage) and two asynchronous reads simultaneously.
- The immediate field is **sign-extended** to 32 bits.
- The **Hazard Detection Unit** monitors register dependencies and issues stall or flush signals as needed.
- The **ID/EX pipeline register** (`id_ex_reg.v`) forwards all control signals and data to the execute stage.

### EX — Execute
- The **ALU Control unit** (`alu_control.v`) derives the 4-bit ALU operation from the 2-bit `ALUOp` control signal and the instruction's `funct`/`opcode` fields.
- The **Forwarding Unit** (`forwarding_unit.v`) resolves data hazards by routing the correct operand to the ALU inputs:
  - `forwardA` / `forwardB`: 2-bit muxes selecting between the register file output, EX/MEM result (EX–EX forwarding), or MEM/WB result (MEM–EX forwarding).
  - `forwardMem`: resolves store-after-load hazards by forwarding the WB writeback data into the MEM stage write data path.
- The **ALU** (`alu.v`) performs arithmetic, logical, shift, and comparison operations and produces a 32-bit result and a `Zero` flag.
- The branch target address is computed as `PC+4 + (sign_ext_imm << 2)`.
- The destination register address is selected between `rd` (R-type) and `rt` (I-type) based on `RegDst`.
- The **EX/MEM pipeline register** (`ex_mem_reg.v`) captures the ALU result, write data, write register address, and all remaining control signals.

### MEM — Memory Access
- All memory accesses go through the **data cache** (see Cache section below).
- On a cache hit the access completes in one cycle; on a miss the cache issues a `cache_stall` signal that freezes the entire pipeline (PC, IF/ID, ID/EX, EX/MEM, MEM/WB write-enables all deasserted) until the miss is resolved.
- **Branch resolution** happens here: `PcSrc = Branch & ~Zero`. A taken branch also flushes the IF/ID and ID/EX registers to discard the two incorrectly fetched instructions.
- The **MEM/WB pipeline register** (`mem_wb_reg.v`) holds the cache read data or ALU result, and the write register address.

### WB — Write Back
- A mux selects between the cache read data (`MemtoReg = 1`) and the ALU result (`MemtoReg = 0`).
- The selected value is written back into the register file at the address stored in the MEM/WB register.

---

## Hazard Handling

### Data Hazards — Forwarding (`forwarding_unit.v`)

The forwarding unit detects when an instruction in EX needs a result that has not yet been written back, and routes the correct value from a later pipeline stage:

| Hazard Type   | Source        | Destination | Signal       |
|---------------|---------------|-------------|--------------|
| EX–EX         | EX/MEM result | ALU input   | `forwardA/B = 2'b10` |
| MEM–EX        | MEM/WB result | ALU input   | `forwardA/B = 2'b01` |
| MEM–MEM (SW)  | MEM/WB result | Store data  | `forwardMem = 1`     |

Register `x0` (zero register) is never forwarded (guard on `write_regaddr != 5'b0`).

### Data Hazards — Stalling (`hazard_unit.v`)

A **load-use hazard** (an instruction immediately following a `LW` that reads the loaded register) cannot be resolved by forwarding alone, because the data is not available until after the MEM stage. The hazard unit handles this by:

1. Asserting `pc_write = 0` to freeze the PC.
2. Asserting `ifid_write = 0` to freeze the IF/ID register.
3. Asserting `idex_flush = 1` to insert a NOP bubble into the ID/EX register.

This produces a one-cycle stall, after which MEM–EX forwarding resolves the dependency.

### Control Hazards — Flushing

Branches are resolved in the MEM stage. When a branch is taken (`branch_taken = Branch & ~Zero`):

1. `ifid_flush = 1` — flushes the instruction in IF/ID (2 cycles ahead).
2. `idex_flush = 1` — flushes the instruction in ID/EX (1 cycle ahead).

This implements a **flush-on-taken** strategy with a fixed 2-cycle branch penalty.

---

## Cache Subsystem

Two cache implementations are provided. The processor uses `sa_cache` (2-way set-associative) by default.

### Direct-Mapped Cache — `dm_cache.v`

| Parameter       | Value                      |
|-----------------|----------------------------|
| Total size      | 8 KB                       |
| Block size      | 32 bytes (8 words)         |
| Number of lines | 256                        |
| Associativity   | 1-way (direct-mapped)      |
| Tag bits        | 19 (bits 31–13)            |
| Index bits      | 8 (bits 12–5)              |
| Block offset    | 5 (bits 4–0)               |
| Write policy    | Write-back + write-allocate |

### 2-Way Set-Associative Cache — `sa_cache.v`

| Parameter       | Value                           |
|-----------------|---------------------------------|
| Total size      | 8 KB                            |
| Block size      | 32 bytes (8 words)              |
| Sets            | 128                             |
| Ways            | 2                               |
| Replacement     | LRU (pseudo-LRU via `use_bit`) |
| Tag bits        | 20 (bits 31–12)                 |
| Index bits      | 7 (bits 11–5)                   |
| Block offset    | 5 (bits 4–0)                    |
| Write policy    | Write-back + write-allocate     |

### Cache FSM

Both caches share the same 3-state FSM:

```
        ┌─────────────────────────────────────┐
        │                                     ▼
     ┌──────┐   miss + dirty   ┌───────────┐
     │      │ ────────────────▶│ WRITEBACK │
     │ IDLE │                  └─────┬─────┘
     │      │◀──────┐                │ done
     └──────┘       │         ┌──────▼──────┐
        │           └─────────│   REFILL    │
        │   miss + clean      └─────────────┘
        └────────────────────────────────────▶
```

- **IDLE**: On a hit, serve the read/write in one cycle. On a miss, save the request and transition to WRITEBACK (if the victim is dirty) or REFILL directly.
- **WRITEBACK**: Write all 8 words of the dirty victim block back to main memory word-by-word, then transition to REFILL.
- **REFILL**: Fetch all 8 words of the new block from main memory. On completion, update the cache metadata, apply any pending CPU write (write-allocate), and return to IDLE.

During any state other than IDLE, `cache_stall = 1`, which freezes the entire pipeline.

### Cache Statistics

Both cache modules track:
- `total_accesses` — total number of memory operations
- `hit_count` — number of cache hits
- `miss_count` — number of cache misses

---

## Module Summary

| File                      | Description                                      |
|---------------------------|--------------------------------------------------|
| `cached_mips_processor.v` | Top-level module wiring all stages together      |
| `pc.v`                    | Program Counter register with write-enable       |
| `instr_mem.v`             | Instruction memory (ROM)                         |
| `if_id_reg.v`             | IF/ID pipeline register (stall + flush)          |
| `control_unit.v`          | Main control unit (opcode/funct decode)          |
| `regfile.v`               | 32×32 register file (2 read, 1 write port)       |
| `id_ex_reg.v`             | ID/EX pipeline register (stall + flush)          |
| `alu_control.v`           | ALU control (maps ALUOp + funct → ALUControl)    |
| `alu.v`                   | 32-bit ALU (add, sub, and, or, slt, shifts)      |
| `forwarding_unit.v`       | Data forwarding (EX–EX, MEM–EX, MEM–MEM)        |
| `hazard_unit.v`           | Hazard detection (load-use stall, branch flush)  |
| `ex_mem_reg.v`            | EX/MEM pipeline register (stall + flush)         |
| `sa_cache.v`              | 2-way set-associative data cache (used by default)|
| `dm_cache.v`              | Direct-mapped data cache (alternative)           |
| `data_mem.v`              | Main memory backing the cache                    |
| `mem_wb_reg.v`            | MEM/WB pipeline register                        |
| `cached_mips_test.v`      | Testbench for the cached processor               |
| `pipelined_mips_processor.v` | Baseline pipelined processor (no cache)       |
| `sc_mips_processor.v`     | Single-cycle MIPS processor (reference)          |
| `programs/`               | Hex programs used for simulation                 |

---

## Simulation

Open the project in any Verilog simulator (e.g. Icarus Verilog, ModelSim, Vivado):

```bash
# Using Icarus Verilog
iverilog -o sim cached_mips_test.v cached_mips_processor.v \
    pc.v instr_mem.v if_id_reg.v control_unit.v regfile.v id_ex_reg.v \
    alu_control.v alu.v forwarding_unit.v hazard_unit.v ex_mem_reg.v \
    sa_cache.v data_mem.v mem_wb_reg.v
vvp sim
```

Waveform dumps (`.vcd` files) for three test programs are included and can be viewed in GTKWave.
