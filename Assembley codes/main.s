# ============================================================
    # [0] Initialize stack pointer
    # ============================================================
    addi $sp, $0, 2048

    # ============================================================
    # Test 1 : EX-stage forwarding
    # ============================================================
    addi $t0, $0, 5
    addi $t1, $0, 10
    add  $t2, $t0, $t1       # (15)
    sub  $t3, $t2, $t0       # (10)

    # ============================================================
    # Test 2 : MEM-stage forwarding
    # ============================================================
    add  $t4, $t2, $t1       # (25)
    nop
    sub  $t5, $t4, $t1       # (15)
    
    # ============================================================                                      
    # Test 3 : Forwarding from 3 instructions ago
    # ============================================================
    addi $t0, $0, 100
    addi $a0, $a0, -1        # (independent)
    addi $v0, $0, 2          # (independent)
    add  $t3, $t0, $t1       # (must forward $t0 from MEM/WB)
    
    # ============================================================
    # Test 4 : Simultaneous ForwardA and ForwardB
    # Both ALU inputs require forwarding.
    # ============================================================
    addi $t0, $0, 7
    add  $t0, $t0, $t0       # (14)
    add  $t1, $t0, $t0       # (28)

    # ============================================================
    # Test 5 : EX/MEM priority over MEM/WB
    # The newest value must be selected.
    # ============================================================
    addi $t2, $0, 1
    addi $t2, $t2, 1         # (2)
    addi $t2, $t2, 1         # (3)
    add  $t3, $t2, $t0       # must use newest t2 (=3)
         
    # ============================================================
    # Test 6: EX/MEM priority over 3 instruction ago
    # The newest value must be selected.
    # ============================================================
    addi $t0, $0, 10         # 5 instruction ago, $t0 value shouldn't be used
    addi $t1, $0, 2          # 4 instruction ago, $t1 value shouldn't be used
    addi $t0, $0, 5
    addi $t1, $0, 1
    addi $t0, $t0, 2
    add  $t2, $t0, $t1
    
    # ============================================================
    # Test 7: MEM/WB priority over 3 operations ago
    # The newest value must be selected.
    # ============================================================
    addi $t0, $0, 10         # 5 instruction ago, $t0 value shouldn't be used
    addi $t1, $0, 2          # 4 instruction ago, $t1 value shouldn't be used
    addi $t0, $0, 5
    addi $t0, $t0, 2
    addi $t1, $0, 1
    add  $t2, $t0, $t1

    # ============================================================
    # Test 8 : Ignore forwarding from register $zero
    # ============================================================
    addi $t0, $0, 99
    add  $zero, $t0, $t1
    add  $t4, $zero, $t0     # t4 must equal 99

    # ============================================================
    # Test 9 : SLT
    # ============================================================
    addi $t0, $0, -5
    addi $t1, $0, 3
    slt  $t2, $t0, $t1       # t2 = 1
    slt  $t3, $t1, $t0       # t3 = 0
                                      
    # ============================================================
    # Test 10 : Load-use hazard
    # ============================================================
    sw   $t5, 0($sp)
    lw   $t6, 0($sp)
    add  $t7, $t6, $t0

    # ============================================================
    # Test 11 : BEQ not taken, using register from previous instruction
    # ============================================================
    addi $t4, $0, 2
    addi $t5, $0, 2
    nop
    nop
    nop
    addi $t4, $0, 1
    beq  $t4, $t5, 2
    nop
    addi $t6, $0, 111        # (not skipped, must be executed)

    # ============================================================
    # Test 12 : BEQ taken, using register from previous instruction
    # ============================================================
    addi $t4, $0, 4
    addi $t5, $0, 5
    nop
    nop
    nop
    addi $t4, $0, 5
    beq  $t4, $t5, 2
    nop
    addi $t6, $0, 222        # (skipped)
    addi $t6, $0, 333
    
    # ============================================================
    # Test 13 : BEQ uses result from 2 instructions earlier
    # ============================================================
    addi $t2, $0, 5
    addi $t1, $0, 0
    beq  $t2, $t1, 2
    nop
    addi $t3, $0, 0x1111     # (should be skipped)
    addi $t3, $0, 0x2222
    
    # ============================================================
    # Test 14 : BEQ uses value written 3 instructions ago
    # ============================================================
    addi $t0, $0, 2
    addi $t1, $0, 1
    addi $t2, $0, 2
    beq  $t0, $t2, 2
    nop
    addi $t3, $0, 0x1111     # (should be skipped)
    addi $t3, $0, 0x2222
    
    # ============================================================
    # Test 15 : BEQ uses value written 4 instructions ago
    # ============================================================
    addi $t0, $0, 5
    addi $t1, $0, 1
    addi $t2, $0, 2
    addi $t3, $0, 3
    beq  $t0, $t3, 2
    nop
    addi $t4, $0, 0x1111     # (should be executed)
    addi $t4, $0, 0x2222
    
    # ============================================================
    # Test 16 : Branch Priorities result of 1 instruction ago over 2 instructions ago
    # ============================================================
    addi $t2, $0, 6
    addi $t0, $0, 5
    addi $t0, $t0, 1
    beq  $t0, $t2, 3
    nop
    addi $t4, $0, 0x1111     # (should be skipped)
    addi $t5, $0, 0x2222     # (should be skipped)
    
    # ============================================================
    # Test 17 : Branch Priorities result of 2 instructions ago over 3 instructions ago
    # ============================================================
    addi $t0, $0, 5
    addi $t0, $t0, 1
    addi $t1, $0, 5
    beq  $t0, $t2, 2
    nop
    addi $t7, $0, 0x1111     # (should be executed)
    addi $t7, $0, 0x2222
    
    # ============================================================
    # Test 18 : Branch Priorities result of 1 instruction ago over 4 instructions ago
    # ============================================================
    addi $t0, $0, 5
    addi $t1, $0, 1
    addi $t2, $0, 7
    addi $t0, $t0, 2
    beq  $t0, $t2, 3
    nop
    addi $s0, $0, 0x1111     # (should be skipped)
    addi $s0, $0, 0x2222     # (should be skipped)
    
    # ============================================================
    # Test 19 : Both BEQ operands forwarded
    # ============================================================
    addi $t6, $0, 10
    addi $t7, $0, 10
    beq  $t6, $t7, 2
    nop
    addi $t0, $0, 1          # skipped
    addi $t0, $0, 2          # executed
    
    # ============================================================
    # Test 20 : AND
    # ============================================================
    addi $t0, $0, 15
    addi $t1, $0, 10
    and  $t2, $t0, $t1       # expected: 10
    
    # ============================================================
    # Test 21 : OR
    # ============================================================
    addi $t0, $0, 12
    addi $t1, $0, 3
    or   $t3, $t0, $t1       # expected: 15
                                      
    # ============================================================
    # Test 22 : Forwarding to SW (store uses previous ALU result)
    # ============================================================
    addi $t0, $0, 10
    nop
    addi $t0, $t0, 5         # (t0 = 15)
    sw   $t0, 0($sp)         # (must store forwarded value 15)
    lw   $t1, 0($sp)         # (t1 = 15)
    addi $t2, $t1, 1         # (t2 = 16)