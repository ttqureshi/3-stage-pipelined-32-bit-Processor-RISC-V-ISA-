module processor 
(
    input logic clk,
    input logic rst,
    input logic timer_interrupt
); 
    // wires

    // pc_out
    logic [31:0] pc_out_IF;
    logic [31:0] pc_out_DE;
    logic [31:0] pc_out_MW;

    logic [31:0] new_pc;

    // inst
    logic [31:0] inst_IF;
    logic [31:0] inst_DE;
    logic [31:0] inst_MW;

    logic [ 4:0] waddr;
    logic [ 4:0] rd;
    logic [ 4:0] rs1;
    logic [ 4:0] rs2;
    logic [ 6:0] opcode;
    logic [ 2:0] funct3;
    logic [ 6:0] funct7;

    // rdata1
    logic [31:0] rdata1_DE;
    logic [31:0] rdata1_MW;

    // rdata2
    logic [31:0] rdata2_DE;
    logic [31:0] rdata2_MW;

    logic [31:0] opr_a;
    logic [31:0] opr_b;

    // opr_res
    logic [31:0] opr_res_IF;
    logic [31:0] opr_res_DE;
    logic [31:0] opr_res_MW;

    // imm_val
    logic [31:0] imm_val_DE;
    logic [31:0] imm_val_MW;

    // wdata
    logic [31:0] wdata_DE;
    logic [31:0] wdata_MW;

    logic [31:0] rdata;
    logic        br_taken;
    logic [3 :0] aluop;

    // rf_en
    logic        rf_en_DE;
    logic        rf_en_MW;

    logic        sel_a;
    logic        sel_b;

    // rd_en
    logic        rd_en_DE;
    logic        rd_en_MW;

    // wr_en
    logic        wr_en_DE;
    logic        wr_en_MW;

    // wb_sel
    logic [ 1:0] wb_sel_DE;
    logic [ 1:0] wb_sel_MW;

    // mem_acc_mode
    logic [ 2:0] mem_acc_mode_DE;
    logic [ 2:0] mem_acc_mode_MW;

    logic [ 2:0] br_type;

    // br_take
    logic        br_take_IF;
    logic        br_take_DE;

    // csr_rd
    logic        csr_rd_DE;
    logic        csr_rd_MW;
    
    // csr_wr
    logic        csr_wr_DE;
    logic        csr_wr_MW;

    // is_mret
    logic        is_mret_DE;
    logic        is_mret_MW;

    logic [31:0] csr_rdata;

    // epc
    logic [31:0] epc_IF;
    logic [31:0] epc_MW;

    // epc_taken
    logic        epc_taken_IF;
    logic        epc_taken_MW;

    logic [31:0] epc_pc;

    // --------------------- Instruction Fetch (IF) ---------------------

    // PC MUX
    mux_2x1 mux_2x1_pc
    (
        // inputs
        .in_0        ( pc_out_IF + 32'd4 ),
        .in_1        ( opr_res_IF        ),
        .select_line ( br_take_IF        ),

        // outputs
        .out         ( new_pc         )
    );


    mux_2x1 mux_2x1_epc
    (
        // inputs
        .in_0        ( new_pc       ),
        .in_1        ( epc_IF       ),
        .select_line ( epc_taken_IF ),

        // outputs
        .out         ( epc_pc       ) 
    );


    // program counter
    pc pc_i
    (
        // inputs
        .clk   ( clk            ),
        .rst   ( rst            ),
        .pc_in ( epc_pc         ),

        //outputs
        .pc_out( pc_out_IF      )
    );


    // instruction memory
    inst_mem inst_mem_i
    (
        // inputs
        .addr  ( pc_out_IF      ),

        // outputs
        .data  ( inst_IF        )
    );

    // ---------------------------------------------------------------

    // IF <-> DE Buffer
    always_ff @( posedge clk ) 
    begin
        if ( rst )
        begin
            pc_out_DE <= 0;
            inst_DE  <= 0;
        end
        else
        begin
            pc_out_DE <= pc_out_IF; // PC 
            inst_DE   <= inst_IF;   // instruction 
        end
    end

    // --------------------- Decode-Execute (DE) ---------------------


    // instruction decoder
    inst_dec inst_dec_i
    (
        // inputs
        .inst  ( inst_DE        ),

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
        .rf_en ( rf_en_MW       ),
        .rs1   ( rs1            ),
        .rs2   ( rs2            ),
        .rd    ( waddr          ),
        .wdata ( wdata_DE       ),

        // outputs
        .rdata1( rdata1_DE      ),
        .rdata2( rdata2_DE      )
    );


    // controller
    controller controller_i
    (
        // inputs
        .opcode         ( opcode          ),
        .funct3         ( funct3          ),
        .funct7         ( funct7          ),
        .br_taken       ( br_taken        ),

        // outputs
        .aluop          ( aluop           ),
        .rf_en          ( rf_en_DE        ),
        .sel_a          ( sel_a           ),
        .sel_b          ( sel_b           ),
        .rd_en          ( rd_en_DE        ),
        .wr_en          ( wr_en_DE        ),
        .wb_sel         ( wb_sel_DE       ),
        .mem_acc_mode   ( mem_acc_mode_DE ),
        .br_type        ( br_type         ),
        .br_take        ( br_take_DE      ),
        .csr_rd         ( csr_rd_DE       ),
        .csr_wr         ( csr_wr_DE       ),
        .is_mret        ( is_mret_DE      )
    );


    // immediate generator
    imm_gen imm_gen_i
    (
        // inputs
        .inst   ( inst_DE       ),

        // outputs
        .imm_val( imm_val_DE    )
    );


    // ALU opr_a MUX
    mux_2x1 mux_2x1_alu_opr_a
    (
        // inputs
        .in_0           ( pc_out_DE  ),
        .in_1           ( rdata1_DE  ),
        .select_line    ( sel_a      ),

        // outputs
        .out            ( opr_a      )
    );


    // ALU opr_b MUX
    mux_2x1 mux_2x1_alu_opr_b
    (
        // inputs
        .in_0           ( rdata2_DE  ),
        .in_1           ( imm_val_DE ),
        .select_line    ( sel_b      ),

        // outputs
        .out            ( opr_b      )
    );


    // ALU
    alu alu_i
    (
        // inputs
        .aluop   ( aluop          ),
        .opr_a   ( opr_a          ),
        .opr_b   ( opr_b          ),

        // outputs
        .opr_res ( opr_res_DE     )
    );


    // br_cond
    br_cond br_cond_i
    (
        // inputs
        .rdata1   ( rdata1_DE ),
        .rdata2   ( rdata2_DE ),
        .br_type  ( br_type   ),

        // outputs
        .br_taken ( br_taken )
    );

    // ---------------------------------------------------------------
    
    // Feedback to IF stage
    always_comb 
    begin
        br_take_IF = br_take_DE;
        opr_res_IF = opr_res_DE;
    end

    // DE <-> MEM-WB Buffer
    always_ff @ ( posedge clk )
    begin
        if ( rst )
        begin
            pc_out_MW       <= 0;
            inst_MW         <= 0;
            opr_res_MW      <= 0;
            rdata1_MW       <= 0;
            rdata2_MW       <= 0;
            imm_val_MW      <= 0;

            // control signals
            rf_en_MW        <= 0;
            rd_en_MW        <= 0;
            wr_en_MW        <= 0;
            mem_acc_mode_MW <= 0;
            csr_rd_MW       <= 0;
            csr_wr_MW       <= 0;
            is_mret_MW      <= 0;
            wb_sel_MW       <= 0;
        end
        else
        begin
            pc_out_MW       <= pc_out_DE;
            inst_MW         <= inst_DE;
            opr_res_MW      <= opr_res_DE;
            rdata1_MW       <= rdata1_DE;
            rdata2_MW       <= rdata2_DE;
            imm_val_MW      <= imm_val_DE;

            // control signals
            rf_en_MW        <= rf_en_DE;
            rd_en_MW        <= rd_en_DE;
            wr_en_MW        <= wr_en_DE;
            mem_acc_mode_MW <= mem_acc_mode_DE;
            csr_rd_MW       <= csr_rd_DE;
            csr_wr_MW       <= csr_wr_DE;
            is_mret_MW      <= is_mret_DE;
            wb_sel_MW       <= wb_sel_DE;
        end
    end

    // ----------------------- Memory-Writeback ----------------------


    // data memory
    data_mem data_mem_i
    (
        // inputs
        .clk            ( clk             ),
        .rd_en          ( rd_en_MW        ),
        .wr_en          ( wr_en_MW        ),
        .addr           ( opr_res_MW      ),
        .mem_acc_mode   ( mem_acc_mode_MW ),
        .rdata2         ( rdata2_MW       ),

        // outputs
        .rdata          ( rdata        )
    );


    // csr 
    csr_reg csr_reg_i
    (
        // inputs
        .clk       ( clk             ),
        .rst       ( rst             ),
        .addr      ( imm_val_MW      ),
        .wdata     ( rdata1_MW       ),
        .pc        ( pc_out_MW       ),
        .trap      ( timer_interrupt ),
        .csr_rd    ( csr_rd_MW          ),
        .csr_wr    ( csr_wr_MW          ),
        .is_mret   ( is_mret_MW         ),
        .inst      ( inst_MW            ),

        // outputs
        .rdata     ( csr_rdata       ),
        .epc       ( epc_MW             ),
        .epc_taken ( epc_taken_MW       )
    );


    // Writeback MUX
    mux_4x1 wb_mux
    (
        // inputs
        .in_0           ( pc_out_MW + 32'd4 ),
        .in_1           ( opr_res_MW        ),
        .in_2           ( rdata             ),
        .in_3           ( csr_rdata         ),
        .select_line    ( wb_sel_MW         ),

        // outputs
        .out            ( wdata_MW          )
    );

    // ---------------------------------------------------------------

    // Feedback to IF stage
    always_comb
    begin
        epc_IF       = epc_MW;
        epc_taken_IF = epc_taken_MW;
        wdata_DE     = wdata_MW;
        waddr        = inst_MW[11:7];
    end
    
endmodule