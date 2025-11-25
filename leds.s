/* INIT LEDS - callee-saved r11..r15 */

.equ DATA_LEDS_R, 0x10000000

.global LEDS
LEDS:
    /*PROLOGO */
    stw     r11, 0(sp)
    subi    sp, sp, 4
    stw     r12, 0(sp)
    subi    sp, sp, 4
    stw     r13, 0(sp)
    subi    sp, sp, 4
    stw     r14, 0(sp)
    subi    sp, sp, 4
    stw     r15, 0(sp)
    /*PROLOGO */

    movia   r11, DATA_LEDS_R        /* guardando o endereco dos LEDS em r11 */

    /* convertendo num decimal para binario */
    /* registrador r5 contem entrada do usuario em ascii */
    ldw     r13, 4(r5)              /* carrega caractere decimal que representa a unidade em r13 */
    subi    r13, r13, 0x30          /* subtrai 0x30 para converter numero ascii para binario */

    ldw     r14, 0(r5)              /* carrega caractere decimal que representa a dezena em r14 */
    subi    r14, r14, 0x30          /* subtrai 0x30 para converter numero ascii para binario */

    /* multiplica r14 por 10 */
    /* multiplicacao em etapas (multiplica por 8 e soma o numero duas vezes) */
    slli    r15, r14, 3             /* shift left 3 bits para multiplicar por 8 */
    add     r15, r15, r14           /* somando r14 pela primeira vez */
    add     r15, r15, r14           /* somando r14 pela segunda vez */

    /* Resultado final em binario da entrada do usuario */
    /* Soma da dezena e unidade obtidos anteriormente em r13 */
    add     r13, r13, r15

    /* checa se comando indica para acender ou apagar led */
    addi    r14, r0, 1              /* armazena 1 em r14 para comparacao futura */
    ldw     r15, 0(r4)              /* pega o caractere que indica o comando e armazena em r15 */
    subi    r15, r15, 0x30          /* conversao do caractere ascii do comando em r15 para binario */
    beq     r15, r0,  ACENDER_LED   /* codigo 00 */
    beq     r15, r13, APAGAR_LED    /* codigo 01 */

    ACENDER_LED:
        ldwio   r14, 0(r11)          /* le atual estado dos leds */
        addi    r15, r0, 1           /* inicia mascara como 0b0001 */
        sll     r15, r15, r13        /* desloca o digito 1 para a casa binaria que representa o led a ser aceso */
        or      r14, r14, r15        /* acende o led com base na posicao definida em r15 */
        stwio   r14, 0(r11)          /* atualiza o estado dos leds */

        /* EPILOGO */
        ldw     r15, 0(sp)
        addi    sp, sp, 4
        ldw     r14, 0(sp)
        addi    sp, sp, 4
        ldw     r13, 0(sp)
        addi    sp, sp, 4
        ldw     r12, 0(sp)
        addi    sp, sp, 4
        ldw     r11, 0(sp)
        /* EPILOGO */

        ret

    APAGAR_LED:
        ldwio   r14, 0(r11)          /* le atual estado dos leds */
        addi    r15, r0, 1           /* inicia a mascara como 0b0001 */
        sll     r15, r15, r13        /* desloca o digito 1 para a casa binaria que representa o led a ser aceso */
        sub     r14, r14, r15        /* apaga o led com base na posicao definida em r15 */
        stwio   r14, 0(r11)          /* atualiza o estado dos leds */

        /* EPILOGO */
        ldw     r15, 0(sp)
        addi    sp, sp, 4
        ldw     r14, 0(sp)
        addi    sp, sp, 4
        ldw     r13, 0(sp)
        addi    sp, sp, 4
        ldw     r12, 0(sp)
        addi    sp, sp, 4
        ldw     r11, 0(sp)
        /* EPILOGO */

        ret
/* FIM LEDS */