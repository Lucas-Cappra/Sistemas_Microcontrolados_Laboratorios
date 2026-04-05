.include "m328pdef.inc"

.cseg
.org 0x0000

rjmp main

;========================================================
; ================== SEU CONVERSOR BCD para 16 bits =================== 
;========================================================

convert_BCD:

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
    RET
;========================================================
; ================== ADC ===================
;========================================================

init_adc:
    ldi r16, (1<<REFS0)             ; AVcc
    sts ADMUX, r16

    ldi r16, (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
    sts ADCSRA, r16                 ; enable + prescaler 128
    ret

read_adc:
    lds r16, ADCSRA
    ori r16, (1<<ADSC)
    sts ADCSRA, r16                 ; conversao


wait_adc:
    lds r16, ADCSRA
    sbrs r16, ADSC
    rjmp wait_adc

    lds r17, ADCL
    lds r18, ADCH
    ret

;========================================================
; ========= MAPEAMENTO 0–1023 x 0–999 ====================
; Saída final em R20 
;========================================================

map_adc:

    ; R18:R17 = ADC (10 bits)

    ; aproximação: (ADC * 1000) / 1024

    mov r20, r17
    mov r21, r18

    ; shift left 10 (x1024)
    ldi r16, 10
map_l1:
    lsl r20
    rol r21
    dec r16
    brne map_l1

    ; calcula ADC*24
    mov r22, r17
    mov r23, r18

    ; *8
    lsl r22
    rol r23
    lsl r22
    rol r23
    lsl r22
    rol r23

    mov r24, r22
    mov r25, r23

    ; *16
    lsl r22
    rol r23

    ; soma 8 + 16
    add r22, r24
    adc r23, r25

    ; subtrai
    sub r20, r22
    sbc r21, r23

    ; divide por 1024
    ldi r16, 10
map_l2:
    lsr r21
    ror r20
    dec r16
    brne map_l2

    ; AGORA R20 = valor final (0–999 aproximado)
    ret

;========================================================
; ================== DISPLAY ===================
;========================================================

exibir_pov:

	ldi r19, 0
	mov r16, r4

    rcall invert_bit
    swap r16
	out PORTD, r16

	cp r4, r19
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

;========================================================
; DELAY
;========================================================

delay_mili:
   clr r21         
   ldi r22, 0
   ldi r23, 1

delay_loop_mili:
    dec r22         
    brne delay_loop_mili  
    dec r21         
    brne delay_loop_mili  
    dec r23         
    brne delay_loop_mili  
    ret

;========================================================
; INVERTER BITS (SEU)
;========================================================

invert_bit:
    cpi r16, 1
    brne v2
    ldi r16, 8
    rjmp fim

v2: cpi r16, 2
    brne v3
    ldi r16, 4
    rjmp fim

v3: cpi r16, 3
    brne v4
    ldi r16, 0x0C
    rjmp fim

v4: cpi r16, 4
    brne v5
    ldi r16, 2
    rjmp fim

v5: cpi r16, 5
    brne v6
    ldi r16, 0x0A
    rjmp fim

v6: cpi r16, 6
    brne v7
    rjmp fim

v7: cpi r16, 7
    brne v8
    ldi r16, 0x0E
    rjmp fim

v8: cpi r16, 8
    brne v9
    ldi r16, 1
    rjmp fim

v9: cpi r16, 9
    rjmp fim

fim:
    ret

;========================================================
; ================== MAIN ===================
;========================================================

main:

    ; PORTD saída (segmentos)
    ldi r16, 0xFC
    out DDRD, r16

    ; PORTB seleção display
    sbi DDRB, 0

    rcall init_adc

MAIN_LOOP:

    ; leitura ADC
    rcall read_adc

    ; mapeamento 0–999
    rcall map_adc

    ; valor já está em R20 ? usa seu BCD
    rcall convert_BCD

    ; exibição POV
    ldi r25, 30

loop_pov:
    rcall exibir_pov
    dec r25
    brne loop_pov

    rjmp MAIN_LOOP