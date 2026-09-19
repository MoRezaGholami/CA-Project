.text
    .globl main

main:
    # ============================================================
    # [0] Initialize stack pointer
    # ============================================================
    addi $sp, $0, 2048

    # ============================================================
    # Fibonacci Sequence (1 to 10) - Pure Back-to-Back Hazards
    # ============================================================
    addi $t0, $0, 1      # F(1) = 1
    addi $t1, $0, 1      # F(2) = 1
    add  $t2, $t0, $t1   # F(3) = 2  (Hazards: t1 from EX, t0 from MEM)
    add  $t3, $t1, $t2   # F(4) = 3  (Hazards: t2 from EX, t1 from MEM)
    add  $t4, $t2, $t3   # F(5) = 5  (Hazards: t3 from EX, t2 from MEM)
    add  $t5, $t3, $t4   # F(6) = 8  (Hazards: t4 from EX, t3 from MEM)
    add  $t6, $t4, $t5   # F(7) = 13 (Hazards: t5 from EX, t4 from MEM)
    add  $t7, $t5, $t6   # F(8) = 21 (Hazards: t6 from EX, t5 from MEM)
    add  $s0, $t6, $t7   # F(9) = 34 (Hazards: t7 from EX, t6 from MEM)
    add  $s1, $t7, $s0   # F(10)= 55 (Hazards: s0 from EX, t7 from MEM)

    # ============================================================
    # Exit gracefully (Required for MARS/SPIM simulators)
    # ============================================================
    li $v0, 10           # System call code for exit
    syscall              # Terminate execution