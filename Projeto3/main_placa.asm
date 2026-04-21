.include "m328pdef.inc"

.def TRIG 4
.def ECHO 5 

.cseg
.org 0x0000           ; A proxima instruncao em 0x0000

rjmp main

.org 0x0008

rjmp ISR_BOTOES    ; Vetor de PCINT0 (Pinos A0-A5)





ISR_BOTOES:
    push r16
    in r16, SREG
    push r16

    S2:
    ; Vai pro Estado de Salvar na Memória 
    sbic PINC, 2        ; Se for 1 (soltou), pula para o fim
    rjmp S3
    cpi r24, 1
    brne S3

    ldi r24, 3
    
    ; Vai pro Estado de Exibir
    S3:
    sbic PINC, 3        ; Se for 1 (soltou), pula para o fim
    rjmp S1
    cpi r24, 1
    brne S1

    ldi r24, 4

    ; Vai pro Estado de Medir uma Nova Distância
    S1:
    sbic PINC, 1        ; Se for 1 (soltou), pula para o fim
    rjmp sair_isr
  
    ldi r24, 2


sair_isr:
    pop r16
    out SREG, r16
    pop r16
    reti


maquina_de_estados:

    cpi r24, 0
    breq init
    
    cpi r24, 1
    breq wait

    cpi r24, 2
    breq measure

    cpi r24, 3
    breq store

    cpi r24, 4
    breq show

    ldi r24, 1

    rjmp fim_maquina


    ; Estado Inicial(Reset)
    init:
    ldi r20, 0x00
    ldi r21, 0x00

    ldi r24, 1


    rjmp fim_maquina


    ; Estado de Contagem
    wait:
    

    rjmp fim_maquina


    measure:
    rcall trigger_pulse
    rcall measure_echo
    rcall convert_cm 

    mov r20, r30
    mov r21, r31

    ldi r24, 1
    
    rjmp fim_maquina


    ; Estado de Seleção do Valor Mínimo
    store:
    rcall SALVAR

    ldi r24, 1
    rjmp fim_maquina

    ; Estado de Seleção do Valor Máximo
    show:
    rcall LER

    ldi r24, 1

    rjmp fim_maquina


    ; Fim
    fim_maquina:
    ret


//LER 16 bits (r21:r20)


LER:

EE_WAIT3:
    sbic EECR, EEPE
    rjmp EE_WAIT3

    ; lê LSB
    ldi r16, 0x00
    out EEARL, r16
    sbi EECR, EERE
    in r20, EEDR

    ; lê MSB
    ldi r16, 0x01
    out EEARL, r16
    sbi EECR, EERE
    in r21, EEDR

    ret
//SALVAR 


SALVAR:

EE_WAIT1:
    sbic EECR, EEPE
    rjmp EE_WAIT1

    ; salva LSB
    ldi r16, 0x00
    out EEARL, r16
    out EEDR, r20

    sbi EECR, EEMPE
    sbi EECR, EEPE

EE_WAIT2:
    sbic EECR, EEPE
    rjmp EE_WAIT2

    ; salva MSB
    ldi r16, 0x01
    out EEARL, r16
    out EEDR, r21

    sbi EECR, EEMPE
    sbi EECR, EEPE

    ret


measure_echo:

;----------------------------------------
; Espera ECHO subir
;----------------------------------------
wait_high:
    SBIS PINC, ECHO
    RJMP wait_high

    ; Zera Timer1
    LDI R16, 0
    STS TCNT1H, R16
    STS TCNT1L, R16

;----------------------------------------
; Espera ECHO descer
;----------------------------------------
wait_low:
    SBIS PINC, ECHO
    RJMP read_timer
    RJMP wait_low

;----------------------------------------
; Lê valor do Timer1
;----------------------------------------
read_timer:

    ; IMPORTANTE: ler LOW primeiro
    LDS R20, TCNT1L
    LDS R21, TCNT1H

    RET


trigger_pulse:

    SBI PORTC, TRIG
    RCALL delay_10us
    CBI PORTC, TRIG

    RET


convert_cm:

    CLR R30          ; resultado
    CLR R31
    CLR R1
    CLR R28

div_loop:
    ; se valor < 116 → terminou
    LDI R23, 116
    CP R20, R23
    CPC R21, R1      ; R1 = 0 sempre

    BRLO div_end

    ; subtrai 116
    SUBI R20, 116
    SBCI R21, 0

    ADIW R30, 1
    adc R21, R28
    RJMP div_loop

div_end:
    RET




delay_10us:

    LDI R18, 40
d1:
    NOP
    DEC R18
    BRNE d1

    RET



  convert_BCD:

    push r17
    push r16

    CLR R4        ; centenas
    CLR R5        ; dezenas
    CLR R6        ; unidades

    MOV R16, R20  ; LOW byte
    MOV R17, R21  ; HIGH byte

;========================================================
; CENTENAS (subtrai 100 = 0x0064)
;========================================================

div_centena:
    CPI R17, 0
    BRNE sub_100          ; se high > 0, pode subtrair

    CPI R16, 100
    BRLO div_dezena       ; se <100, vai para dezenas

sub_100:
    SUBI R16, 100         ; subtrai low
    SBCI R17, 0           ; subtrai carry do high
    INC R4
    RJMP div_centena

;========================================================
; DEZENAS (subtrai 10 = 0x000A)
;========================================================

div_dezena:
    CPI R17, 0
    BRNE sub_10           ; se high > 0, continua

    CPI R16, 10
    BRLO div_unidade

sub_10:
    SUBI R16, 10
    SBCI R17, 0
    INC R5
    RJMP div_dezena

;========================================================
; UNIDADES (subtrai 1)
;========================================================

div_unidade:
    CPI R17, 0
    BRNE sub_1

    CPI R16, 1
    BRLO div_sair

sub_1:
    SUBI R16, 1
    SBCI R17, 0
    INC R6
    RJMP div_unidade

div_sair:
    pop r16
    pop r17
    RET


exibir_pov:


	ldi r16, 0
	mov r16, r4

    rcall invert_bit
    swap r16
	out PORTD, r16

	cp r4, r16

    breq centena_zero
    sbi   PORTB, 0
    centena_zero:

	cbi PORTD, 3
	cbi PORTD, 2
	rcall delay_mili



	mov r16, r5
	mov r17, r5
	or r17, r4

	rcall invert_bit
    swap r16

	out PORTD, r16
	cpi r17, 0
    breq dezena_zero
    sbi   PORTD, 3  

    dezena_zero:
	cbi PORTD, 2
	cbi PORTB, 0
	rcall delay_mili


	mov r16, r6
	rcall invert_bit
    swap r16
    out PORTD, r16
    sbi PORTD, 2
	cbi PORTD, 3
	cbi PORTB, 0

	rcall delay_mili
   
    
    ret



delay_mili:
   clr     r21         
   ldi     r22, 0
   ldi     r23, 1


delay_loop_mili:
    dec     r22         
    brne    delay_loop_mili  
    dec     r21         
    brne    delay_loop_mili  
    dec     r23         
    brne    delay_loop_mili  
    ret


invert_bit:
    cpi r16, 1
    brne value_2
    ldi r16, 8
    rjmp fim

    value_2: 
    cpi r16, 2
    brne value_3
    ldi r16, 4
    rjmp fim

    value_3: 
    cpi r16, 3
    brne value_4
    ldi r16, 0x0C
    rjmp fim

    value_4:
    cpi r16, 4
    brne value_5
    ldi r16, 2
    rjmp fim

    value_5:
    cpi r16, 5
    brne value_6
    ldi r16, 0x0A
    rjmp fim

    value_6:
    cpi r16, 6
    brne value_7
    rjmp fim

    value_7:
    cpi r16, 7
    brne value_8
    ldi r16, 0x0E
    rjmp fim

    value_8:
    cpi r16, 8
    brne value_9
    ldi r16, 1
    rjmp fim

    value_9:
    cpi r16, 9
    rjmp fim

    fim:
    ret




exibir:

    ; Delay (~1 s)
    ldi r25, 30
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação rápida
    dec r25
    cpi r25, 0
    brne loop_pov

    ret






main:


    setup_display:
    ldi r16, 0xFC
    out DDRD, r16; 1111 1100(4 Pinos pro 7448 e 2 Pros transistores de Dezena e Unidade)

    sbi DDRB, 0 ; PB0 (Pino 8) Saída pro Transistor de Centena
	

    Setup_Sensor(A4, A5):
    sbi DDRC, TRIG
    cbi DDRC, ECHO

    cbi PORTC, ECHO



    SETUP_BOTOES:  ;A1, A2, A3
    cbi DDRC, 1
	  cbi DDRC, 2
	  cbi DDRC, 3

    sbi PORTC, 1       ; Ativa Pull-up no A1
    sbi PORTC, 2       ; Ativa Pull-up no A2
	  sbi PORTC, 3       ; Ativa Pull-up no A3


    ldi r16, (1 << PCIE1)
    sts PCICR, r16     ; Grupo Port C
    ldi r16, (1 << PCINT9) | (1<< PCINT10) | (1<< PCINT11) ;(Pinos 9 até o 11 do Micro)
    sts PCMSK1, r16    ; (Máscara Correspondente pro A1,A2 e A3)
  

    sei

    init_state:
    clr r24
    

MAIN_LOOP:
	
	; Atualiza o Estado do Sistema
    rcall maquina_de_estados

    ; Converte o numero em r20 e r21 para BCD
    rcall convert_BCD

	; Exibe de acordo com o efeito POV
    rcall exibir
    
continua:

    rjmp MAIN_LOOP
