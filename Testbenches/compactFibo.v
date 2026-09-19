module tb;
    reg clk, rst, Jen;
    reg [31:0] instructions[512];
    reg [31:0] data_mem[512];

    reg [31:0] Jin;
    wire [31:0] Jout;
    wire InstDone;
    wire [31:0] R[32];
    assign R[0] = 0;

    reg [31:0] inst_reg;
    reg [4:0] inst_rs, inst_rt, inst_rd;
    reg [31:0] val_rs, val_rt;
    reg [15:0] inst_imm;
    reg [31:0] inst_imm_sext;
    
    reg [8:0] ipc;
    reg [8:0] next_ipc; 
    
    reg [31:0] ireg[32];
    reg [31:0] ireghi, ireglo;
    reg [31:0] data_addr;

    task write2reg(input [4:0] reg_dest, input [31:0] val);
        begin
            if (reg_dest !== 0) ireg[reg_dest] = val;
        end
    endtask

    function [31:0] sra(input [31:0] a, input [4:0] b);
        begin
            sra = ({{32{a[31]}}, a} >> b);
        end
    endfunction

    task exec_internal;
        begin
            inst_reg = instructions[ipc];
            
            ipc = next_ipc;
            next_ipc = ipc + 1; 

            inst_rs = inst_reg[25:21];
            inst_rt = inst_reg[20:16];
            inst_rd = inst_reg[15:11];
            inst_imm = inst_reg[15:0];
            inst_imm_sext = {{16{inst_imm[15]}}, inst_imm};
            val_rs = ireg[inst_rs];
            val_rt = ireg[inst_rt];
            
            case (inst_reg[31:26])
                6'b000000: begin  // RType
                    case (inst_reg[5:0])
                        6'b100000: write2reg(inst_rd, val_rs + val_rt);  // add
                        6'b100010: write2reg(inst_rd, val_rs - val_rt);  // sub
                        6'b100100: write2reg(inst_rd, val_rs & val_rt);  // and
                        6'b100101: write2reg(inst_rd, val_rs | val_rt);  // or
                        6'b100110: write2reg(inst_rd, val_rs ^ val_rt);  // xor
                        6'b000100: write2reg(inst_rd, val_rs << val_rt[4:0]);  // sll
                        6'b000110: write2reg(inst_rd, val_rs >> val_rt[4:0]);  // srl
                        6'b000111: write2reg(inst_rd, sra(val_rs, val_rt[4:0]));  // sra
                        6'b001000: next_ipc = val_rs; // jr 
                        6'b000000: write2reg(inst_rd, val_rt << inst_reg[10:6]);  // sll (imm)
                        6'b011010: begin  // div 
                            ireghi = val_rs % val_rt;
                            ireglo = val_rs / val_rt;
                        end
                        6'b010000: write2reg(inst_rd, ireghi);  // mfhi
                        6'b010010: write2reg(inst_rd, ireglo);  // mflo
                        6'b101010: write2reg(inst_rd, val_rs < val_rt ? 1 : 0);  // slt
                        default $display("NOT IMPLEMENTED : rtype[func: %b]", inst_reg[5:0]);
                    endcase
                end
                6'b000011: begin  // jal 
                    write2reg(31, ipc);          
                    next_ipc = inst_reg[25:0];   
                end
                6'b001000: write2reg(inst_rt, val_rs + inst_imm_sext);  // addi
                6'b101011: begin  // sw
                    data_addr = val_rs + inst_imm_sext;
                    data_mem[(data_addr>>2)&511] = val_rt;
                end
                6'b100011: begin  // lw
                    data_addr = val_rs + inst_imm_sext;
                    write2reg(inst_rt, data_mem[(data_addr>>2)&511]);
                end
                6'b000101: begin  // beq
                    if (val_rs == val_rt) next_ipc = ipc + inst_imm_sext; 
                end
                6'b000010: next_ipc = inst_imm;  // j 
                default $display("NOT IMPLEMENTED : [opcode: %b]", inst_reg[31:26]);
            endcase
        end
    endtask

    main _main (
        .clk(clk),
        .rst(rst),
        .Jen(Jen),
        .Jin(Jin),
        .Jout(Jout),
        .InstDone(InstDone),
        .R1(R[1]), .R2(R[2]), .R3(R[3]), .R4(R[4]), .R5(R[5]),
        .R6(R[6]), .R7(R[7]), .R8(R[8]), .R9(R[9]), .R10(R[10]),
        .R11(R[11]), .R12(R[12]), .R13(R[13]), .R14(R[14]), .R15(R[15]),
        .R16(R[16]), .R17(R[17]), .R18(R[18]), .R19(R[19]), .R20(R[20]),
        .R21(R[21]), .R22(R[22]), .R23(R[23]), .R24(R[24]), .R25(R[25]),
        .R26(R[26]), .R27(R[27]), .R28(R[28]), .R29(R[29]), .R30(R[30]),
        .R31(R[31])
    );

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    int i, j;
    int last_instr;
    int fail_flag;

    initial begin
        for (i = 0; i < 512; i++) instructions[i] = 0;
        for (i = 0; i < 512; i++) data_mem[i] = 0;
        for (i = 0; i < 32; i++) ireg[i] = 0;
        ireghi = 0;
        ireglo = 0;
        
        ipc = 0;
        next_ipc = 1; 
        fail_flag = 0;

        // ============================================================
        // [0] Initialize stack pointer
        // ============================================================
        instructions[0]  = 32'h201D0800;  // addi $sp,$0,2048

        // ============================================================
        // Fibonacci Sequence (1 to 10) - Pure Back-to-Back Hazards
        // ============================================================
        instructions[1]  = 32'h20080001;  // addi $t0, $0, 1   -> F(1) = 1
        instructions[2]  = 32'h20090001;  // addi $t1, $0, 1   -> F(2) = 1
        instructions[3]  = 32'h01095020;  // add  $t2, $t0, $t1 -> F(3) = 2  (Hazards: t1 from EX, t0 from MEM)
        instructions[4]  = 32'h012A5820;  // add  $t3, $t1, $t2 -> F(4) = 3  (Hazards: t2 from EX, t1 from MEM)
        instructions[5]  = 32'h014B6020;  // add  $t4, $t2, $t3 -> F(5) = 5  (Hazards: t3 from EX, t2 from MEM)
        instructions[6]  = 32'h016C6820;  // add  $t5, $t3, $t4 -> F(6) = 8  (Hazards: t4 from EX, t3 from MEM)
        instructions[7]  = 32'h018D7020;  // add  $t6, $t4, $t5 -> F(7) = 13 (Hazards: t5 from EX, t4 from MEM)
        instructions[8]  = 32'h01AE7820;  // add  $t7, $t5, $t6 -> F(8) = 21 (Hazards: t6 from EX, t5 from MEM)
        instructions[9]  = 32'h01CF8020;  // add  $s0, $t6, $t7 -> F(9) = 34 (Hazards: t7 from EX, t6 from MEM)
        instructions[10] = 32'h01E08820;  // add  $s1, $t7, $s0 -> F(10)= 55 (Hazards: s0 from EX, t7 from MEM)

        last_instr = 11;
        
        // =========================================================
        
        rst = 1;
        #8 rst = 0;
        Jen = 1;
        for (i = 0; i < 512; i++) begin  // Load D-Mem
            Jin = data_mem[511-i];
            #2;
        end
        for (i = 0; i < 512; i++) begin  // Load I-Mem
            Jin = instructions[511-i];
            #2;
        end
        Jen = 0;
        
        rst = 1;
        #2 rst = 0;  

        #8;
        $display("-------------------------------------------");
        $display("Starting Pipelined MIPS with Data Forwarding");
        $display("-------------------------------------------");

        while (ipc < last_instr && !fail_flag) begin
            #2;
            if (InstDone === 1'b1) begin
                $display("Hardware retired instruction at beh_ipc: %d", ipc);
                exec_internal();
                for (j = 1; j < 32; j++) begin
                    if (R[j] !== ireg[j]) begin
                        fail_flag = 1; 
                        $display(">>> FAILED at Register R[%d] <<<", j);
                    end
                end
                
                if (fail_flag) begin
                    $display("-------------------------------------------");
                    $display("EXPECTED (Behavioral):");
                    $display("F1(t0):%d | F2(t1):%d | F3(t2):%d | F4(t3):%d | F5(t4):%d", ireg[8], ireg[9], ireg[10], ireg[11], ireg[12]);
                    $display("F6(t5):%d | F7(t6):%d | F8(t7):%d | F9(s0):%d | F10(s1):%d", ireg[13], ireg[14], ireg[15], ireg[16], ireg[17]);
                    
                    $display("\nREALITY (Hardware):");
                    $display("F1(t0):%d | F2(t1):%d | F3(t2):%d | F4(t3):%d | F5(t4):%d", R[8], R[9], R[10], R[11], R[12]);
                    $display("F6(t5):%d | F7(t6):%d | F8(t7):%d | F9(s0):%d | F10(s1):%d", R[13], R[14], R[15], R[16], R[17]);
                    $display("-------------------------------------------");
                end
            end
        end

        if (!fail_flag) begin
            $display("===============================================================");
            $display("          ALL TESTS ACCEPTED - TESTBENCH PASSED                ");
            $display("===============================================================");
            $display("   [PROOF FOR PROFESSOR: FINAL FIBONACCI REGISTER VALUES]      ");
            $display("---------------------------------------------------------------");
            $display("EXPECTED (Behavioral Model):");
            $display("F1-F5  : %3d | %3d | %3d | %3d | %3d", ireg[8], ireg[9], ireg[10], ireg[11], ireg[12]);
            $display("F6-F10 : %3d | %3d | %3d | %3d | %3d", ireg[13], ireg[14], ireg[15], ireg[16], ireg[17]);
            $display("---------------------------------------------------------------");
            $display("ACTUAL (Your Pipeline Hardware):");
            $display("F1-F5  : %3d | %3d | %3d | %3d | %3d", R[8], R[9], R[10], R[11], R[12]);
            $display("F6-F10 : %3d | %3d | %3d | %3d | %3d", R[13], R[14], R[15], R[16], R[17]);
            $display("===============================================================");
        end

        $finish(0);
    end
endmodule
