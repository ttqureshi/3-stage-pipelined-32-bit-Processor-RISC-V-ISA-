module hazard_unit
(
    // Forwarding
    input  logic [ 4:0] rs1_DE,
    input  logic [ 4:0] rs2_DE,
    input  logic [ 4:0] rd_MW,
    input  logic        rf_en_MW,
    output logic        forward_a,
    output logic        forward_b,

    // Stalling
    input  logic [31:0] inst_IF,
    input  logic [ 4:0] rd_DE,
    input  logic [ 1:0] wb_sel_DE,
    output logic        stall_IF, // to PC register
    output logic        flush_DE // Flush DE stage
);
    logic stall_lw;

    // Operand A
    always_comb
    begin
        if (rf_en_MW)
        begin
            if ((rs1_DE == rd_MW) & (rs1_DE != 0)) 
            begin
                forward_a = 1'b1;
            end
            else
            begin
                forward_a = 1'b0;
            end
        end
    end
    
    // Operand B
    always_comb
    begin
        if (rf_en_MW)
        begin
            if ((rs2_DE == rd_MW) & (rs2_DE != 0)) 
            begin
                forward_b = 1'b1;
            end
            else
            begin
                forward_b = 1'b0;
            end
        end
    end

    // Stalling
    always_comb
    begin
        if (wb_sel_DE == 2'b10)
        begin
            if ( (inst_IF[19:15] == rd_DE) | (inst_IF[24:20] == rd_DE) )
            begin
                stall_lw = 1'b1;
            end
            else
            begin
                stall_lw = 1'b0;
            end
        end
        else
        begin
            stall_lw = 1'b0;
        end
        stall_IF = stall_lw;
        flush_DE = stall_lw;
    end

endmodule

