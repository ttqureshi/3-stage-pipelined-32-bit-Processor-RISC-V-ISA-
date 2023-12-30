This repository contains the implementation of 3-stage Pipelined Processor based on RISC-V Instruction Set Architecture. Following is the brief description of the project:

*For design diagram of 3-stage pipelined processor, see **[3-stage_pipelined_proc_design_diagram.png](https://github.com/ttqureshi/3-stage-pipelined-32-bit-Processor-RISC-V-ISA-/blob/main/3-stage_pipelined_proc_design_diagram.png "3-stage_pipelined_proc_design_diagram.png")**
or visit [draw.io](https://app.diagrams.net/#G1Q6_c2Uw8DhKzlROVleCqcefcnQ91zmgN "Design diagram").*

# Supported Instructions

### **DATA PROCESSING INSTRUCTIONS:**

**R-type:** ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND

**I-type:** ADDI, SLTI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI

**U-type:** LUI, AUIPC

### MEMORY ACCESS INSTRUCTIONS:

**I-type:** LB, LH, LW, LBU, LHU

**S-type:** SB, SH, SW

### FLOW CONTROL INSTRUCTIONS:

**J-type:** JAL

**I-type:** JALR

**B-type:** BEQ, BNE, BLT, BGE, BLTU, BGEU

### CSR INSTRUCTIONS:

CSRRW, MRET

# Pipelining Hazards: 3-Stage vs 5-Stage Pipeline

### STRUCTURAL HAZARDS

There are no structural hazards in case of both 3-stage and 5-stage pipeline as instruction memory and data memory are separate memories.

### DATA HAZARDS

**3-stage:** Data Hazard between Current Instrucion and 1st-Previous Instruction is handled through *forwarding* from Memory-Writeback stage to Decode-Execute stage. In case of load instuction, 1 stall cycle is necessary.

**5-stage:** Data Hazards between Current Instruction and 1st-Previous Instruction AND Current Instruction and 2nd-Previous Instruction is handled through *forwarding* from Memory to Execute stage and Writeback to Execute stage. In case of load instuction, 1 stall cycle is necessary.

### CONTROL HAZARDS

**3-stage:** Only Decode-Execute stage is flushed In case of branch and jump instructions, as the target address is known after Decode-Execute stage.

**5-stage:** In case of 5-stage pipeline, Decode and Execute stages are flushed, as the target address is known after execute stage.

# Processor's Functionality Testing

The processor's functionality has been tested against two assembly programs GCD and factorial. See ``inst.mem`` for factorial example. For GCD example, go to this [commit](https://github.com/ttqureshi/3-stage-pipelined-32-bit-Processor-RISC-V-ISA-/tree/2e5b24f53889ed2949087df10a61bd21843f21f1 "see GCD example at this commit").

# Compilation & Simulation Guidelines

RTL can be compiled and simulated by just running ``compile.bat`` file which i've created in the same folder

Compilation and Simulation process is explained below:

## Compilation

RTL can be compiled with the command:

```
vlog names_of_all_system_verilog_files
```

or simply:

```
vlog *.sv 
```

Compilation creates a ``work`` folder in your current working directory in which all the files generated after compilation are stored.

## Simulation

The compiled RTL can be simulated with command:

```
vsim -c name_of_toplevel_module -do "run -all"
```

Simulation creates a ``.vcd`` file. This files contains all the simulation behaviour of design.

## Viewing the VCD Waveform File

To view the waveform of the design run the command:

```
gtkwave dumpfile_name.vcd
```

Here dumpfile_name will be ``processor.vcd``

This opens a waveform window. Pull the required signals in the waveform and verify the behaviour of the design.

## License

[CC0 1.0 Universal](LICENSE)
