module processor 
(
    input logic clk,
    input logic rst,
    input logic timer_interrupt
); 
    // wires
    logic        rf_en;
    logic        sel_b;

    // pc_out
    logic [31:0] pc_out;
    logic [31:0] pc_out_if;
    logic [31:0] pc_out_de;

    logic [31:0] new_pc;

    // inst
    logic [31:0] inst;
    logic [31:0] inst_if;
    logic [31:0] inst_de;

    logic [ 4:0] rd;
    logic [ 4:0] rs1;
    logic [ 4:0] rs2;
    logic [ 6:0] opcode;
    logic [ 2:0] funct3;
    logic [ 6:0] funct7;
    logic [31:0] rdata1;
    logic [31:0] rdata2;
    logic [31:0] opr_a;
    logic [31:0] opr_b;
    logic [31:0] opr_res;
    logic [11:0] imm;
    logic [31:0] imm_val;
    logic [31:0] wdata;
    logic [3 :0] aluop;
    logic [31:0] rdata;
    logic        rd_en;
    logic        wr_en;
    logic [ 1:0] wb_sel;
    logic        br_taken;
    logic        br_take;
    logic [ 2:0] br_type;
    logic [ 2:0] mem_acc_mode;
    logic        csr_rd;
    logic        csr_wr;
    logic [31:0] csr_rdata;
    logic [31:0] epc;
    logic        is_mret;
    logic        epc_taken;
    logic [31:0] epc_pc;

    // --------------------- Instruction Fetch (IF) ---------------------

    // PC MUX
    mux_2x1 mux_2x1_pc
    (
        // inputs
        .in_0        ( pc_out_if + 32'd4 ),
        .in_1        ( opr_res        ),
        .select_line ( br_take        ),

        // outputs
        .out         ( new_pc         )
    );


    mux_2x1 mux_2x1_epc
    (
        // inputs
        .in_0        ( new_pc    ),
        .in_1        ( epc       ),
        .select_line ( epc_taken ),

        // outputs
        .out         ( epc_pc    ) 
    );


    // program counter
    pc pc_i
    (
        // inputs
        .clk   ( clk            ),
        .rst   ( rst            ),
        .pc_in ( epc_pc         ),

        //outputs
        .pc_out( pc_out_if      )
    );


    // instruction memory
    inst_mem inst_mem_i
    (
        // inputs
        .addr  ( pc_out_if      ),

        // outputs
        .data  ( inst_if        )
    );

    // ---------------------------------------------------------------

    // IF <-> DE Buffer
    always_ff @( posedge clk ) 
    begin
        if ( rst )
        begin
            pc_out_de <= 0;
            inst_de  <= 0;
        end
        else
        begin
            pc_out_de <= pc_out_if; // PC 
            inst_de   <= inst_if;   // instruction 
        end
    end

    // --------------------- Decode-Execute (DE) ---------------------


    // instruction decoder
    inst_dec inst_dec_i
    (
        // inputs
        .inst  ( inst_de        ),

        // outputs
        .rs1   ( rs1            ),
        .rs2   ( rs2            ),
        .rd    ( rd             ),
        .opcode( opcode         ),
        .funct3( funct3         ),
        .funct7( funct7         )
    );


    // register file
    reg_file reg_file_i
    (
        // inputs
        .clk   ( clk            ),
        .rf_en ( rf_en          ),
        .rs1   ( rs1            ),
        .rs2   ( rs2            ),
        .rd    ( rd             ),
        .wdata ( wdata          ),

        // outputs
        .rdata1( rdata1         ),
        .rdata2( rdata2         )
    );


    // controller
    controller controller_i
    (
        // inputs
        .opcode         ( opcode         ),
        .funct3         ( funct3         ),
        .funct7         ( funct7         ),
        .br_taken       ( br_taken       ),

        // outputs
        .aluop          ( aluop          ),
        .rf_en          ( rf_en          ),
        .sel_a          ( sel_a          ),
        .sel_b          ( sel_b          ),
        .rd_en          ( rd_en          ),
        .wr_en          ( wr_en          ),
        .wb_sel         ( wb_sel         ),
        .mem_acc_mode   ( mem_acc_mode   ),
        .br_type        ( br_type        ),
        .br_take        ( br_take        ),
        .csr_rd         ( csr_rd         ),
        .csr_wr         ( csr_wr         ),
        .is_mret        ( is_mret        )
    );


    // immediate generator
    imm_gen imm_gen_i
    (
        // inputs
        .inst   ( inst_de       ),

        // outputs
        .imm_val( imm_val       )
    );


    // ALU opr_a MUX
    mux_2x1 mux_2x1_alu_opr_a
    (
        // inputs
        .in_0           ( pc_out_de  ),
        .in_1           ( rdata1     ),
        .select_line    ( sel_a      ),

        // outputs
        .out            ( opr_a      )
    );


    // ALU opr_b MUX
    mux_2x1 mux_2x1_alu_opr_b
    (
        // inputs
        .in_0           ( rdata2  ),
        .in_1           ( imm_val ),
        .select_line    ( sel_b   ),

        // outputs
        .out            ( opr_b   )
    );


    // ALU
    alu alu_i
    (
        // inputs
        .aluop   ( aluop          ),
        .opr_a   ( opr_a          ),
        .opr_b   ( opr_b          ),

        // outputs
        .opr_res ( opr_res        )
    );


    // br_cond
    br_cond br_cond_i
    (
        // inputs
        .rdata1   ( rdata1   ),
        .rdata2   ( rdata2   ),
        .br_type  ( br_type  ),

        // outputs
        .br_taken ( br_taken )
    );

    // ---------------------------------------------------------------
    
    // DE <-> MEM-WB Buffer

    // // --------------------- Memory-Writeback ---------------------


    // data memory
    data_mem data_mem_i
    (
        // inputs
        .clk            ( clk          ),
        .rd_en          ( rd_en        ),
        .wr_en          ( wr_en        ),
        .addr           ( opr_res      ),
        .mem_acc_mode   ( mem_acc_mode ),
        .rdata2         ( rdata2       ),

        // outputs
        .rdata          ( rdata        )
    );


    // csr 
    csr_reg csr_reg_i
    (
        // inputs
        .clk       ( clk             ),
        .rst       ( rst             ),
        .addr      ( imm_val         ),
        .wdata     ( rdata1          ),
        .pc        ( pc_out          ),
        .trap      ( timer_interrupt ),
        .csr_rd    ( csr_rd          ),
        .csr_wr    ( csr_wr          ),
        .is_mret   ( is_mret         ),
        .inst      ( inst            ),

        // outputs
        .rdata     ( csr_rdata       ),
        .epc       ( epc             ),
        .epc_taken ( epc_taken       )
    );


    // Writeback MUX
    mux_4x1 wb_mux
    (
        // inputs
        .in_0           ( pc_out + 32'd4 ),
        .in_1           ( opr_res        ),
        .in_2           ( rdata          ),
        .in_3           ( csr_rdata      ),
        .select_line    ( wb_sel         ),

        // outputs
        .out            ( wdata          )
    );

    // ---------------------------------------------------------------


    
endmodule