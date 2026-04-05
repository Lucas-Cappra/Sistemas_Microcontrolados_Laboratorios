.include "m328pdef.inc"

; =========================
; RESET
; =========================
.cseg
.org 0x0000
rjmp main

; =========================
; MAIN
; =========================
main:

; Inicializa Stack
ldi r16, HIGH(RAMEND)
out SPH, r16
ldi r16, LOW(RAMEND)
out SPL, r16

; =========================
; CONFIGURA ADC
; =========================
ldi r16, (1<<REFS0)        ; AVcc como referência
sts ADMUX, r16

ldi r16, (1<<ADEN) | (1<<ADPS2) | (1<<ADPS1) ; habilita ADC, prescaler 64
sts ADCSRA, r16

loop:

; Inicia conversão
lds r16, ADCSRA
ori r16, (1<<ADSC)
sts ADCSRA, r16

; Aguarda fim
wait_adc:
lds r16, ADCSRA
sbrc r16, ADSC
rjmp wait_adc

; Lê resultado (10 bits)
lds R20, ADCL
lds R21, ADCH

; =========================
; CHAMA CONVERSÃO
; =========================
rcall converte

; Resultado:
; R25:R24 = valor entre 0–999

rjmp loop

; =========================
; FUNÇÃO DE CONVERSÃO
; y ? (x * 1000) >> 10
; =========================
converte:

; constante 1000
ldi R22, LOW(1000)
ldi R23, HIGH(1000)

; limpa acumulador 32 bits
clr R16
clr R17
clr R18
clr R19

; =========================
; multiplicação 16x16
; =========================

mul R20, R22
movw R16, R0

mul R21, R22
add R17, R0
adc R18, R1

mul R20, R23
add R17, R0
adc R18, R1

mul R21, R23
add R18, R0
adc R19, R1

clr R1

; =========================
; shift >>10
; =========================
ldi R22, 10

shift_loop:
lsr R19
ror R18
ror R17
ror R16
dec R22
brne shift_loop

; =========================
; resultado final
; =========================
mov R24, R16
mov R25, R17

ret