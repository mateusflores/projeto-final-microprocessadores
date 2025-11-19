/*
PROJETO FINAL DE MICROPROCESSADORES

r8 ... r15  CALLEE-SAVED
r16 ... r23 CALLER-SAVED
*/

.equ LEFTMOST_LED_R_ON,  0x20000
.equ INIT_STACK,         0x30000
.equ DATA_LEDS_R,        0x10000000
.equ UART_DATA_REG,      0x10001000
.equ UART_CONTROL_REG,   0x10001004
.equ SWITCHES_REG,       0x10000040
.equ PUSHBTN,            0x10000050
.equ TIMER_STATUS_REG,   0x10002000
.equ DISPLAY_7SEG_REG,   0x10000020

.org 0x20
    /* START - PROLOGO */
    stw     r8, 0(sp)
    subi    sp, sp, 4
    stw     r9, 0(sp)
    subi    sp, sp, 4
    stw     r10, 0(sp)
    subi    sp, sp, 4
    stw     ra, 0(sp)
    /* END - PROLOGO */
    
    rdctl   et, ipending              /* checa se houve interrupcao */
    subi    ea, ea, 4                 /* decrementa ea para retornar corretamente ao main */

    andi    r8, et, 0b0001            /* aplica mascara para pegar valor do b0 (IRQ #0) */
    beq     r8, r0, OTHER_INTERRUPTS  /* se nao foi, ir para outras interrupcoes */
    call    EXT_IRQ0                  /* chamar rotina para tratar IRQ #0 (TIMER) */
    br      END_HANDLER

OTHER_INTERRUPTS:
    /* se chegou aqui, e é interrupção, então é interrup de pushbtn e não de interval timer */

    /* START PROLOGO */
    stw     ra, 0(sp)
    subi    sp, sp, 4
    /* END PROLOGO */

    /* Verificar qual botão foi pressionado */
    movia   r8, PUSHBTN
    ldwio   r9, 0(r8)           /* ler estado dos botões */
    
    /* Verificar KEY1 (bit 1) */
    andi    r10, r9, 0b0010      /* máscara para KEY1 */
    beq     r10, r0, CHECK_KEY2
    # call    _inverter_direcao_rotacao
    br      END_PUSHBUTTON
    
    CHECK_KEY2:
    /* Verificar KEY2 (bit 2) */
    andi    r10, r9, 0b0100      /* máscara para KEY2 */
    beq     r10, r0, END_PUSHBUTTON
    # call     _toggle_pausa_rotacao
    
    END_PUSHBUTTON:

    /* START EPILOGO */
    addi    sp, sp, 4
    ldw     ra, 0(sp)
    /* END EPILOGO */

    br END_HANDLER

END_HANDLER:
    /* START - EPILOGO */
    ldw     ra, 0(sp)
    addi    sp, sp, 4
    ldw     r10, 0(sp)
    addi    sp, sp, 4
    ldw     r9, 0(sp)
    addi    sp, sp, 4
    ldw     r8, 0(sp)
    /* END - EPILOGO */
    eret

EXT_IRQ0:
    /* Verificar se rotação está ativa */
    beq     r23, r0, SKIP_ROTACAO
    /* START PROLOGO */
    stw     ra, 0(sp)
    subi    sp, sp, 4
    /* END PROLOGO */
    movia   r8, TIMER_STATUS_REG
    stwio   r0, 0(r8)                       /* limpa bit de timeout */
    # call    _atualizar_rotacao_display
    /* START EPILOGO */
    addi    sp, sp, 4
    ldw     ra, 0(sp)
    /* END EPILOGO */
    ret

    SKIP_ROTACAO:

    /* TRATAMENTO DA ANIMACAO */
    movia   r8, TIMER_STATUS_REG
    stwio   r0, 0(r8)                       /* limpa bit de timeout */
    movia   r8, DATA_LEDS_R                 /* pega o endereco do DATA REG dos LEDS R */ 
    ldwio   r9, 0(r8)                       /* pega o estado dos leds */

    /* VERIFICA SW0 (SWITCH b0) */
    movia   r10, SWITCHES_REG       /* pega o estado dos switches */
    ldwio   r10, 0(r10)
    beq     r10, r0, SWITCH_OFF     /* se o estado == 0 -> nao ligado */

    SWITCH_ON:
        /* entra aqui se o switch esta ligado */
        movia   r10, 0b0001
        beq     r9, r10, REINICIAR_SEQUENCIA    /* se b0 == 1 -> reinicia sequencia */
        srli    r9, r9, 1       /* shift right de 1 bit */
        stwio   r9, 0(r8)           /* escreve o novo estado dos leds */
        ret

    SWITCH_OFF:
        movia   r10, LEFTMOST_LED_R_ON          /* pega o estado dos leds R quando o led mais à esq está ligado */ 
        beq     r9, r10, REINICIAR_SEQUENCIA    /* se o ultimo led esta ligado, devemos reiniciar a sequencia  */
        slli    r9, r9, 1           /* shift left de 1 bit */
        stwio   r9, 0(r8)           /* escreve o novo estado dos leds */
        ret

    REINICIAR_SEQUENCIA:
        movia   r10, SWITCHES_REG               
        ldwio   r10, 0(r10)                     /* pega o estado dos switches */
        beq     r10, r0, RESTART_SWITCH_OFF     /* se o estado == 0 -> nao ligado */

        RESTART_SWITCH_ON:
            movia   r9, LEFTMOST_LED_R_ON   /* liga o LED b17 */
            stwio   r9, 0(r8)               /* escreve o novo estado dos leds */
            ret

        RESTART_SWITCH_OFF:
            addi    r9, r0, 0b0001      /* liga o LED b0 */
            stwio   r9, 0(r8)           /* escreve o novo estado dos leds */
            ret

.global _start
_start:
    /* HABILITAR INTERRUPCOES */
    /* HABILITAR INTERRUPCOES NO PROCESSADOR */
    addi    r16, r0, 1       /* define constante = 1 (0001) */
    wrctl   status, r16      /* habilita interrupcoes no processador */

    /* HABILITAR INTERRUPCOES NO IENABLE */
    movia   r16, 0b0011      /* habilita INTERVAL TIMER e PUSHBTN (IRQs #1 e #2) */
    wrctl   ienable, r16

    /* HABILITAR KEY2 EM PUSHBTN */
    movia   r16, PUSHBTN
    movi    r17, 0b0010       /* bit referente a KEY1 */
    stwio   r17, 8(r16)        /* habilita interrupcoes no key1 no pushbutton */

    movia sp, INIT_STACK
    movia r14, COMANDO                       /* pega o endereco do inicial do comando e armazena em 14 */

    movia r4, ASK_COMMAND_STRING
    call  write_string

    movia   r16, UART_DATA_REG
    POLLING_LEITURA:
        movia  r20, 0x0A     	            /* codigo ASCII do LF (ENTER) */

        ldwio  r17, 0(r16)                    /* copia o valor em DATA_REG para r8 */
        andi   r18, r17, 0x8000              /* aplica a mascara e pega o resultado */
        beq    r18, r0, POLLING_LEITURA     /* se o resultado for igual a zero, 
                                            nao ha nada para ler, voltar */
        andi   r19, r17, 0xff                /* guarda o dado de leitura */
        stw    r19, 0(r14)                  /* coloca o dado no stack */
        addi   r14, r14, 4                  /* avanca o stack em 01 word */
        stwio  r19, 0(r16)                   /* echo: reenvia o caractere para o terminal */
        beq    r19, r20, REDIRECTION        /* se o dado for igual a ENTER (0A) ir para REDIRECTION */
        br     POLLING_LEITURA

    REDIRECTION:    /* 20 / 21*/
        movia   r4, COMANDO     /* aponta para o endereco do codigo do comando */
        ldw     r16, 0(r4)       /* pega o primeiro caractere do comando */
        ldw     r17, 4(r4)       /* pega o segundo caractere do comando */

        addi    r18, r0, 0x30   /* numero 0 em ASCII CODE */
        addi    r19, r0, 0x31   /* numero 1 em ASCII CODE */
        addi    r20, r0, 0x32   /* numero 2 em ASCII CODE */

        /* Verificar comando 00 ou 01 (LED) */
        beq     r16, r18, CHECK_LED_COMMAND  /* se primeiro char == 0 */
        
        /* Verificar comando 10 (triangular) */
        beq     r16, r19, CHECK_TRIANGULAR   /* se primeiro char == 1 */
        
        /* Verificar comando 20 (rotacao) */
        beq     r16, r20, CHECK_ROTATION     /* se primeiro char == 2 */
        
        br _start

    CHECK_LED_COMMAND:
        beq     r17, r18, TRATAR_LED         /* se segundo char == 0 -> comando 00 */
        beq     r17, r19, TRATAR_LED         /* se segundo char == 1 -> comando 01 */
        br _start

    CHECK_TRIANGULAR:
        beq     r17, r18, TRATAR_TRIANGULAR  /* se segundo char == 0 -> comando 10 */
        br _start

    CHECK_ROTATION:
        beq     r17, r18, TRATAR_ROTACAO     /* se segundo char == 0 -> comando 20 */
        beq     r17, r19, CANCELAR_ROTACAO   /* se segundo char == 1 -> comando 21 */
        br _start

        br _start

    END:
        br END

TRATAR_LED:
    /* Ler terceiro caractere (posição do LED xx) */
    movia   r4, COMANDO
    addi    r4, r4, 4
    
    /* Ler quarto caractere (0=apagar, 1=acender) */
    movia   r5, COMANDO
    addi    r5, r5, 12
    
    /* Chamar função externa */
    call LEDS
    br   _start

TRATAR_TRIANGULAR:
    /* Chamar função externa que lê switches, calcula e mostra no display */
    call TRIANGULAR
    br   _start

TRATAR_ROTACAO:
    /* Ativar flag de rotação */
    addi    r23, r0, 1          /* r23 = flag de rotação ativa */
    
    /* Configurar direção inicial (direita) */
    addi    r22, r0, 1          /* r22 = direção (1=direita, 0=esquerda) */
    
    /* Chamar função externa */
    # call _iniciar_rotacao_display
    br   _start

CANCELAR_ROTACAO:
    /* Desativar flag de rotação */
    addi    r23, r0, 0          /* r23 = flag de rotação inativa */
    
    /* Chamar função externa */
    #call _parar_rotacao_display
    br   _start


write_string:
    /* 
    argumentos:
        r4 : endereco inicial de leitura (primeiro caractere)
    */
    movia   r18, UART_CONTROL_REG
    movia   r20, UART_DATA_REG
    POLLING_ESCRITA:
        ldwio  r16, 0(r18)                   /* copia o valor de CONTROL_REG */
        andhi  r17, r21, 0xFFFF              /* aplica a mascara para verificar WSPACE */
        bne    r17, r0, POLLING_ESCRITA      /* se n houver espaco no buffer, volte */

        ldb    r19, 0(r4)                    /* carrega chars */
        beq    r19, r0, RET_STR              /* se achou o zero entao acabou a string */
        stwio  r19, 0(r20)                   /* escreve o dado em DATA de DATA_REG */
        addi   r4, r4, 1

        br POLLING_ESCRITA
    
    RET_STR:
        ret

.org 0x10000
.global COMANDO
COMANDO:
    .skip 6*4

.global ASK_COMMAND_STRING
ASK_COMMAND_STRING:
    .asciz "Entre com o comando: \n"

.global COD_7SEG
COD_7SEG:
    .byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
