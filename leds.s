/* INIT TRATAR LED - callee-saved registers renamed to r11..r15 */

/*
    r4: endereco do primeiro caractere do comando
    0x30 : codigo ascii do caractere '0'
    00 : acender led
    01 : apagar led

    0       0       |       0        1       LF
    0       4       8       12       16      20
*/

.equ DATA_LEDS_R, 0x10000000

.global LEDS
LEDS:
    /* START - PROLOGO */
    stw     r11, 0(sp)
    subi    sp, sp, 4
    stw     r12, 0(sp)
    subi    sp, sp, 4
    stw     r13, 0(sp)
    subi    sp, sp, 4
    stw     r14, 0(sp)
    subi    sp, sp, 4
    stw     r15, 0(sp)
    /* END - PROLOGO */

    movia   r11, DATA_LEDS_R        /* guarda o endereco do DATA REG dos LEDS R */

    /* conversao decimal para binario */
    ldw     r13, 4(r5)                 /* pega o digito decimal menos significativo */
    subi    r13, r13, 0x30          /* subtrai 0x30 do digito menos significativo */

    ldw     r14, 0(r5)                 /* pega o digito decimal mais significativo */
    subi    r14, r14, 0x30          /* subtrai 0x30 do digito mais significativo */

    /* multiplica por dez : multiplica por oito e soma duas vezes */
    slli    r15, r14, 3             /* shift left 3 bits == multiplicar por 8 */
    add     r15, r15, r14           /* soma uma vez - primeira */
    add     r15, r15, r14           /* soma uma vez - segunda */

    /* resultado final da soma */
    add     r13, r13, r15

    /* verificar se devemos acender ou apagar o led */
    addi    r14, r0, 1              /* armazena o valor 1 em r14 para comparacao */
    ldw     r15, 0(r4)             /* pega o caractere que define a acao (apagar ou acender) */
    subi    r15, r15, 0x30          /* subtrai 0x30 do valor pego na linha anterior - 1 == 0x31 e 0 == 0x30 */
    beq     r15, r0,  ACENDER_LED   /* codigo 00 */
    beq     r15, r13, APAGAR_LED    /* codigo 01 */

    /*  
        r11 : endereco do DATA REG dos leds r
        r4 : endereco onde comeca o comando na memoria
        r13 : numero decimal que representa o led a ser manipulado
    */
    APAGAR_LED:
        ldwio   r14, 0(r11)          /* LER ESTADO DOS LEDS */
        addi    r15, r0, 1           /* inicializa a mascara como 0b0001 */
        sll     r15, r15, r13        /* leva o digito 1 para a casa binaria correta */
        nor     r16, r15, r0       /* r16 = NOT r15 */
        and     r14, r14, r16      /* limpa somente o bit desejado */        /* estados_dos_leds - mascara => apagar o led */
        stwio   r14, 0(r11)          /* escreve o estado dos leds atualizado */

        /* START - EPILOGO */
        ldw     r15, 0(sp)
        addi    sp, sp, 4
        ldw     r14, 0(sp)
        addi    sp, sp, 4
        ldw     r13, 0(sp)
        addi    sp, sp, 4
        ldw     r12, 0(sp)
        addi    sp, sp, 4
        ldw     r11, 0(sp)
        /* END - EPILOGO */

        ret

    ACENDER_LED:
        ldwio   r14, 0(r11)          /* LER ESTADO DOS LEDS */
        addi    r15, r0, 1           /* inicializa a mascara como 0b0001 */
        sll     r15, r15, r13        /* leva o digito 1 para a casa binaria correta */
        or      r14, r14, r15        /* estados_dos_leds OR mascara => acende o led */
        stwio   r14, 0(r11)          /* escreve o estado dos leds atualizado */

        /* START - EPILOGO */
        ldw     r15, 0(sp)
        addi    sp, sp, 4
        ldw     r14, 0(sp)
        addi    sp, sp, 4
        ldw     r13, 0(sp)
        addi    sp, sp, 4
        ldw     r12, 0(sp)
        addi    sp, sp, 4
        ldw     r11, 0(sp)
        /* END - EPILOGO */

        ret

/* END TRATAR LED */
