.equ SWITCHES, 0x10000040 # Endereço dos switches no simulador
.equ HEX3_HEX0, 0x10000020 # Endereço dos displays HEX0 a HEX3

.text
.global TRIANGULAR

TRIANGULAR:
    # PROLOGO (montar stack frame)
    /* Adjust the stack pointer */
    addi sp, sp, -8 /* make an 8-byte frame to save fp and ra */
    /* Store registers to the frame */
    stw fp, 4(sp) /* store the frame pointer*/
    stw ra, 0(sp) /* store the return address */
    /* Set the new frame pointer */
    mov fp, sp

    # Ler os switches
    movia r2, SWITCHES 
    ldwio r3, 0(r2) # r3 contém o valor dos switches (n)

    # Calcula o número triangular
    mov r4, r3 # r4 = n
    addi r5, r3, 1 # r5 = n + 1
    # Multiply r4 * r5 -> r6 using shift-and-add (no mul)
    mov r6, r0       # r6 = 0 (accumulator)
    mov r7, r4       # r7 = multiplicand (n)
    mov r8, r5       # r8 = multiplier (n+1)
multiply_loop:
    andi r9, r8, 1
    beq r9, r0, skip_add
    add r6, r6, r7
skip_add:
    srli r8, r8, 1
    slli r7, r7, 1
    bne r8, r0, multiply_loop
    srli r6, r6, 1 # r6 = T = (n(n+1))/2

    # Converter para decimal
    mov r7, r6 # r7 = T (número triangular)
    movi r8, 1000 # Divisão por 1000 (para centenas de milhar, milhar, centenas, etc.)
    # calcula milhar e milhar*1000 sem div/muli
    mov r9, r0        # r9 = milhar (contador)
    mov r10, r0       # r10 = milhar*1000 (acumulador)
    mov r14, r7       # r14 = T (tmp para subtrações)
thousand_loop:
    blt r14, r8, thousand_done  # se tmp < 1000 sai
    sub r14, r14, r8
    addi r9, r9, 1
    add r10, r10, r8
    beq r0, r0, thousand_loop   # salto incondicional
thousand_done:
    sub r7, r7, r10 # r7 = T - milhar*1000

    movi r8, 100 # Divisão por 100 (para centenas)
    movi r8, 100        # Divisor = 100
    mov r10, r0         # r10 = centenas (contador)
    mov r11, r0         # r11 = centenas*100 (acumulador)
    mov r14, r7         # tmp = r7 (resto parcial)
hundred_loop:
    blt r14, r8, hundred_done
    sub r14, r14, r8
    addi r10, r10, 1
    add r11, r11, r8
    beq r0, r0, hundred_loop
hundred_done:
    sub r7, r7, r11 # r7 = T - centenas*100

    movi r8, 10 # Divisão por 10 (para dezenas)
    mov r11, r0       # r11 = dezenas (contador)
    mov r12, r0       # r12 = dezenas*10 (acumulador)
    mov r14, r7       # tmp = r7 (resto parcial)
ten_loop:
    blt r14, r8, ten_done
    sub r14, r14, r8
    addi r11, r11, 1
    add r12, r12, r8
    beq r0, r0, ten_loop
ten_done:
    sub r7, r7, r12 # r7 = T - dezenas*10

    # Agora r9 = milhar, r10 = centenas, r11 = dezenas, r7 = unidades
    # Converter cada dígito para código 7 segmentos
    movia r2, HEX3_HEX0

    # Unidades (HEX0)
    mov r3, r7
    call convert_to_hex
    mov r16, r12 # r16 = código HEX0

    # Dezenas (HEX1)
    mov r3, r11
    call convert_to_hex
    slli r12, r12, 8
    or r16, r16, r12 # combina HEX1

    # Centenas (HEX2)
    mov r3, r10
    call convert_to_hex
    slli r12, r12, 16
    or r16, r16, r12 # combina HEX2

    # Milhar (HEX3)
    mov r3, r9
    call convert_to_hex
    slli r12, r12, 24
    or r16, r16, r12 # combina HEX3

    # Grava todos os HEX de uma vez
    stwio r16, 0(r2)
STOP:
    # EPILOGO (desmonstar stack frame)
    /* Restore ra and fp */
    ldw ra, 0(fp)
    ldw fp, 4(fp)
    addi sp, sp, 8
    ret

convert_to_hex:
    mov r12, r3
    movia r13, hex_table
    slli r12, r12, 2
    add r13, r13, r12
    ldw r12, 0(r13)
    ret

.data
hex_table:
    .word 0x3F # 0
    .word 0x06 # 1
    .word 0x5B # 2
    .word 0x4F # 3
    .word 0x66 # 4
    .word 0x6D # 5
    .word 0x7D # 6
    .word 0x07 # 7
    .word 0x7F # 8
    .word 0x6F # 9