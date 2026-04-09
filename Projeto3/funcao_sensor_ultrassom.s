.include "m328pdef.inc"

;========================================
; DEFINIÇÕES
;========================================
.equ TRIG = 1      ; PB1 (saída)
.equ ECHO = 0      ; PB0 (entrada)

;========================================
.cseg
.org 0x0000
rjmp main

;========================================
main:

    ; TRIG como saída
    SBI DDRB, TRIG

    ; ECHO como entrada
    CBI DDRB, ECHO

    ; TRIG inicia em 0
    CBI PORTB, TRIG

    ;=============================
    ; CONFIGURA TIMER1 (importante para o uso com o sensor ultrassônico pois usa 16bits, melhor resolução)
    ; Prescaler = 8 (0.5us por tick)
    ;=============================
    LDI R16, 0x00
    STS TCCR1A, R16

    LDI R16, (1<<CS11)
    STS TCCR1B, R16

loop:

    RCALL trigger_pulse
    RCALL measure_echo

    ; Resultado final:
    ; R21:R20 = tempo medido (ticks)

    RJMP loop

;========================================
; GERA PULSO DE 10us NO TRIG
;========================================
trigger_pulse:

    SBI PORTB, TRIG
    RCALL delay_10us
    CBI PORTB, TRIG

    RET

;========================================
; MEDE ECHO COM TIMER1 (REAL)
;========================================
measure_echo:

;----------------------------------------
; Espera ECHO subir
;----------------------------------------
wait_high:
    SBIS PINB, ECHO
    RJMP wait_high

    ; Zera Timer1
    LDI R16, 0
    STS TCNT1H, R16
    STS TCNT1L, R16

;----------------------------------------
; Espera ECHO descer
;----------------------------------------
wait_low:
    SBIC PINB, ECHO
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

;========================================
; DELAY ~10us (para TRIG)
;========================================
delay_10us:

    LDI R18, 40
d1:
    NOP
    DEC R18
    BRNE d1

    RET