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
    reg [31:0] temp;

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
                6'b000100: begin  // beq
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
	// Test 1 : EX-stage forwarding
	// ============================================================
	instructions[1]  = 32'h20080005;  // addi $t0,$0,5
	instructions[2]  = 32'h2009000A;  // addi $t1,$0,10
	instructions[3]  = 32'h01095020;  // add  $t2,$t0,$t1      (15)
	instructions[4]  = 32'h01485822;  // sub  $t3,$t2,$t0      (10)

	// ============================================================
	// Test 2 : MEM-stage forwarding
	// ============================================================
	instructions[5]  = 32'h01496020;  // add  $t4,$t2,$t1      (25)
	instructions[6]  = 32'h00000000;  // nop
	instructions[7]  = 32'h01896822;  // sub  $t5,$t4,$t1      (15)
	
	
	// ============================================================                                  	  
        // Test 3 : Forwarding from 3 instructions ago
        // ============================================================
	instructions[6] = 32'h20080064;  // addi $t0, $0, 100
	instructions[7] = 32'h2084FFFF;  // addi $a0,$a0,-1    (independent)
	instructions[8] = 32'h20020002;  // addi $v0, $0, 2      (independent)
	instructions[9] = 32'h01095820;  // add  $t3, $t0, $t1   (must forward $t0 from MEM/WB)
	
	// ============================================================
	// Test 4 : Simultaneous ForwardA and ForwardB
	// Both ALU inputs require forwarding.
	// ============================================================
	instructions[10] = 32'h20080007;  // addi $t0,$0,7
	instructions[11] = 32'h01084020;  // add  $t0,$t0,$t0      (14)
	instructions[12] = 32'h01084820;  // add  $t1,$t0,$t0      (28)

	// ============================================================
	// Test 5 : EX/MEM priority over MEM/WB
	// The newest value must be selected.
	// ============================================================
	instructions[13] = 32'h200A0001;  // addi $t2,$0,1
	instructions[14] = 32'h214A0001;  // addi $t2,$t2,1        (2)
	instructions[15] = 32'h214A0001;  // addi $t2,$t2,1        (3)
	instructions[16] = 32'h01485820;  // add  $t3,$t2,$t0
                                  	  // must use newest t2 (=3)
         
        // ============================================================
        // Test 6: EX/MEM priority over 3 instruction ago
        // The newest value must be selected.
        // ============================================================
    instructions[17] = 32'h2008000A;  // addi $t0,$0,10   // 5 instruction ago, $t0 value shouldn't be used
	instructions[18] = 32'h20090002;  // addi $t1,$0,2    // 4 instruction ago, $t1 value shouldn't be used
    instructions[19] = 32'h20080005;  // addi $t0,$0,5
	instructions[20] = 32'h20090001;  // addi $t1,$0,1
	instructions[21] = 32'h21080002;  // addi $t0,$t0,2
	instructions[22] = 32'h01095020;  // add  $t2,$t0,$t1
	
	// ============================================================
	// Test 7: MEM/WB priority over 3 operations ago
	// The newest value must be selected.
        // ============================================================
	instructions[23] = 32'h2008000A;  // addi $t0,$0,10   // 5 instruction ago, $t0 value shouldn't be used
	instructions[24] = 32'h20090002;  // addi $t1,$0,2    // 4 instruction ago, $t1 value shouldn't be used
	instructions[25] = 32'h20080005;  // addi $t0,$0,5
	instructions[26] = 32'h21080002;  // addi $t0,$t0,2
	instructions[27] = 32'h20090001;  // addi $t1,$0,1
	instructions[28] = 32'h01095020;  // add  $t2,$t0,$t1


	// ============================================================
	// Test 8 : Ignore forwarding from register $zero
	// ============================================================
	instructions[29] = 32'h20080063;  // addi $t0,$0,99
	instructions[30] = 32'h01090020;  // add  $zero,$t0,$t1
	instructions[31] = 32'h00086020;  // add  $t4,$zero,$t0
                                 	  // t4 must equal 99

	// ============================================================
	// Test 9 : SLT
	// ============================================================
	instructions[32] = 32'h2008FFFB;  // addi $t0,$0,-5
	instructions[33] = 32'h20090003;  // addi $t1,$0,3
	instructions[34] = 32'h0109502A;  // slt  $t2,$t0,$t1
        	                          // t2 = 1
		
	instructions[35] = 32'h0128582A;  // slt  $t3,$t1,$t0
        	                          // t3 = 0
        	                          
        
        // ============================================================
	// Test 10 : Load-use hazard
	// ============================================================
	instructions[36]  = 32'hAFAD0000;  // sw   $t5,0($sp)
	instructions[37]  = 32'h8FAE0000;  // lw   $t6,0($sp)
	instructions[38]  = 32'h01C87820;  // add  $t7,$t6,$t0

	// ============================================================
	// Test 11 : BEQ not taken, using register from previous instruction
	// ============================================================
	instructions[39] = 32'h200C0002;  // addi $t4,$0,2
	instructions[40] = 32'h200D0002;  // addi $t5,$0,2
	instructions[41] = 32'h00000000;  // nop
	instructions[42] = 32'h00000000;  // nop
	instructions[43] = 32'h00000000;  // nop
	instructions[44] = 32'h200C0001;  // addi $t4,$0,1
	instructions[45] = 32'h118D0002;  // beq  $t4,$t5,+2
	instructions[46] = 32'h00000000;  // nop
	instructions[47] = 32'h200E006F;  // addi $t6,$0,111 (not skipped, must be executed)

	// ============================================================
	// Test 12 : BEQ taken, using register from previous instruction
	// ============================================================
	instructions[48] = 32'h200C0004;  // addi $t4,$0,4
	instructions[49] = 32'h200D0005;  // addi $t5,$0,5
	instructions[50] = 32'h00000000;  // nop
	instructions[51] = 32'h00000000;  // nop
	instructions[52] = 32'h00000000;  // nop
	instructions[53] = 32'h200C0005;  // addi $t4,$0,5
	instructions[54] = 32'h118D0002;  // beq  $t4,$t5,+2
	instructions[55] = 32'h00000000;  // nop
	instructions[56] = 32'h200E00DE;  // addi $t6,$0,222 (skipped)
	instructions[57] = 32'h200E014D;  // addi $t6,$0,333
	
	// ============================================================
	// Test 13 : BEQ uses result from 2 instructions earlier
	// ============================================================
	instructions[58] = 32'h200A0005;  // addi $t2, $0, 5
	instructions[59] = 32'h20090000;  // addi $t1, $0, 0
	instructions[60] = 32'h11490002;  // beq  $t2, $t1, +2
	instructions[61] = 32'h00000000;  // nop
	instructions[62] = 32'h200B1111;  // addi $t3, $0, 0x1111 (should be skipped)
	instructions[63] = 32'h200B2222;  // addi $t3, $0, 0x2222
	
	// ============================================================
	// Test 14 : BEQ uses value written 3 instructions ago
	// ============================================================
	instructions[64] = 32'h20080002;  // addi $t0,$0,2
	instructions[65] = 32'h20090001;  // addi $t1,$0,1
	instructions[66] = 32'h200A0002;  // addi $t2,$0,2
	instructions[67] = 32'h110A0002;  // beq  $t0,$t2,+2
	instructions[68] = 32'h00000000;  // nop
	instructions[69] = 32'h200B1111;  // addi $t3,$0,0x1111 (should be skipped)
	instructions[70] = 32'h200B2222;  // addi $t3,$0,0x2222
	
	
	// ============================================================
	// Test 15 : BEQ uses value written 4 instructions ago
	// ============================================================
	instructions[71] = 32'h20080005;  // addi $t0,$0,5
	instructions[72] = 32'h20090001;  // addi $t1,$0,1
	instructions[73] = 32'h200A0002;  // addi $t2,$0,2
	instructions[74] = 32'h200B0003;  // addi $t3,$0,3
	instructions[75] = 32'h110B0002;  // beq  $t0,$t3,+2
	instructions[76] = 32'h00000000;  // nop
	instructions[77] = 32'h200C1111;  // addi $t4,$0,0x1111  (should be executed)
	instructions[78] = 32'h200C2222;  // addi $t4,$0,0x2222
	
	// ============================================================
	// Test 16 : Branch Priorities result of 1 instruction ago over 2 instructions ago
	// ============================================================
	instructions[79] = 32'h200A0006;  // addi $t2,$0,6
	instructions[80] = 32'h20080005;  // addi $t0,$0,5
	instructions[81] = 32'h21080001;  // addi $t0,$t0,1
	instructions[82] = 32'h110A0003;  // beq  $t0,$t2,+3
	instructions[83] = 32'h00000000;  // nop
	instructions[84] = 32'h200C1111;  // addi $t4,$0,0x1111 (should be skipped)
	instructions[85] = 32'h200D2222;  // addi $t5,$0,0x2222 (should be skipped)
	
	// ============================================================
	// Test 17 : Branch Priorities result of 2 instructions ago over 3 instructions ago
	// ============================================================
	instructions[86] = 32'h20080005;  // addi $t0,$0,5
	instructions[87] = 32'h21080001;  // addi $t0,$t0,1
	instructions[88] = 32'h20090005;  // addi $t1,$0,5
	instructions[89] = 32'h110A0002;  // beq  $t0,$t2,+2
	instructions[90] = 32'h00000000;  // nop
	instructions[91] = 32'h200F1111;  // addi $t7,$0,0x1111 (should be executed)
	instructions[92] = 32'h200F2222;  // addi $t7,$0,0x2222
	
	
	// ============================================================
	// Test 18 : Branch Priorities result of 1 instruction ago over 4 instructions ago
	// ============================================================
	instructions[93] = 32'h20080005;  // addi $t0,$0,5
	instructions[94] = 32'h20090001;  // addi $t1,$0,1
	instructions[95] = 32'h200A0007;  // addi $t2,$0,7
	instructions[96] = 32'h21080002;  // addi $t0,$t0,2
	instructions[97] = 32'h110A0003;  // beq  $t0,$t2,+3
	instructions[98] = 32'h00000000;  // nop
	instructions[99] = 32'h20101111;  // addi $s0,$0,0x1111  (should be skipped)
	instructions[100] = 32'h20102222;  // addi $s0,$0,0x2222 (should be skipped)
	
	// ============================================================
	// Test 19 : Both BEQ operands forwarded
	// ============================================================
	instructions[101] = 32'h200E000A;  // addi $t6, $0, 10
	instructions[102] = 32'h200F000A;  // addi $t7, $0, 10
	instructions[103] = 32'h11CF0002;  // beq  $t6, $t7, +2
	instructions[104] = 32'h00000000;  // nop
	instructions[105] = 32'h20100001;  // skipped
	instructions[106] = 32'h20100002;  // executed
	
	
	// ============================================================
	// Test 20 : AND
	// ============================================================
	instructions[107] = 32'h2008000F;  // addi $t0,$0,15
	instructions[108] = 32'h2009000A;  // addi $t1,$0,10
	instructions[109] = 32'h01095024;  // and  $t2,$t0,$t1
                                  	  // expected: 10
	
	// ============================================================
	// Test 21 : OR
	// ============================================================
	instructions[110] = 32'h2008000C;  // addi $t0,$0,12
	instructions[111] = 32'h20090003;  // addi $t1,$0,3
	instructions[112] = 32'h01095825;  // or   $t3,$t0,$t1
        	                          // expected: 15
        	                          
        // ============================================================
	// Test 22 : Forwarding to SW (store uses previous ALU result)
	// ============================================================
	instructions[113] = 32'h2008000A;  // addi $t0,$0,10
	instructions[114] = 32'h00000000;  // nop
	instructions[115] = 32'h21080005;  // addi $t0,$t0,5      (t0 = 15)
	instructions[116] = 32'hAFA80000;  // sw   $t0,0($sp)     (must store forwarded value 15)
	instructions[117] = 32'h8FA90000;  // lw   $t1,0($sp)     (t1 = 15)
	instructions[118] = 32'h212A0001;  // addi $t2,$t1,1      (t2 = 16)

	last_instr = 119;
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
                    $display("t0:%x | t1:%x | t2:%x | t3:%x", ireg[8], ireg[9], ireg[10], ireg[11]);
                    $display("t4:%x | t5:%x | t6:%x | t7:%x", ireg[12], ireg[13], ireg[14], ireg[15]);
                    $display("v0:%x | a0:%x", ireg[2], ireg[4]);
                    
                    $display("\nREALITY (Hardware):");
                    $display("t0:%x | t1:%x | t2:%x | t3:%x", R[8], R[9], R[10], R[11]);
                    $display("t4:%x | t5:%x | t6:%x | t7:%x", R[12], R[13], R[14], R[15]);
                    $display("v0:%x | a0:%x", R[2], R[4]);
                    $display("-------------------------------------------");
                end
            end
        end

        if (!fail_flag) begin
            $display("===========================================");
            $display("    ALL TESTS ACCEPTED - PROJECT 8 PASSED  ");
            $display("===========================================");
        end

        $finish(0);
    end
endmodule
