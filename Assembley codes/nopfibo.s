.text
    .globl main

main:
    # ============================================================
    # [0] Initialize stack pointer
    # ============================================================
    addi $sp, $0, 2048

    # ============================================================
    # Fibonacci Sequence (1 to 10) - WITHOUT Data Forwarding
    # ============================================================
    addi $t0, $0, 1      # F(1) = 1
    addi $t1, $0, 1      # F(2) = 1
    
    # Hazard: $t1 and $t0 are not in Register File yet! (3 NOPs)
    nop
    nop
    nop
    add  $t2, $t0, $t1   # F(3) = 2
    
    # Hazard: $t2 is not in Register File yet! (3 NOPs)
    nop
    nop
    nop
    add  $t3, $t1, $t2   # F(4) = 3
    
    # Hazard: $t3 is not in Register File yet! (3 NOPs)
    nop
    nop
    nop
    add  $t4, $t2, $t3   # F(5) = 5
    
    # Hazard: $t4 is not in Register File yet! (3 NOPs)
    nop
    nop
    nop
    add  $t5, $t3, $t4   # F(6) = 8
    
    # Hazard: $t5 is not in Register File yet! (3 NOPs)
    nop
    nop
    nop
    add  $t6, $t4, $t5   # F(7) = 13
    
    # Hazard: $t6 is not in Register File yet! (3 NOPs)
    nop
    nop
    nop
    add  $t7, $t5, $t6   # F(8) = 21
    
    # Hazard: $t7 is not in Register File yet! (3 NOPs)
    nop
    nop
    nop
    add  $s0, $t6, $t7   # F(9) = 34
    
    # Hazard: $s0 is not in Register File yet! (3 NOPs)
    nop
    nop
    nop
    add  $s1, $t7, $s0   # F(10)= 55


    li $v0, 10
    syscall