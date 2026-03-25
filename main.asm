.include "m328pdef.inc"
.org 0x0000           ; A proxima instruncao em 0x0000

rjmp main


convert_BCD:

  dividir:
    CLR R4 //limpa R4
    CLR R5 //limpa R5
    CLR R6 //limpa R6
    MOV R16, R20 //preserva R0
    

  div_centena:
    CPI R16, 0x64
    BRLO div_dezena ;Desvia se R7<R1
    SUBI R16, 0x64
    INC R4
    rjmp div_centena
    
    
  div_dezena:
    CPI R16, 0x0A
    BRLO div_unidade
    SUBI R16, 0x0A
    INC R5
    rjmp div_dezena ;Desvia se R7<R1

  div_unidade:
    CPI R16, 0x01
    BRLO div_sair
    SUBI R16, 0x01
    INC R6
    rjmp div_unidade ;Desvia se R7<R1
  //div_unidade:

    
  div_sair:
    //MOV R6, R16
    RET //retorna
    //R4, R5, R6 retorna os valores de Dezena, Centena e Unidade respectivamente.


exibir_pov:


    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior
    
    cp r4, r16
    breq centena_zero
    cbi   PORTB, 2

    centena_zero:

    mov r16, r4         ; Pega o valor 0-9 da Centena
    lsl r16
    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 2 


    ; Dezena
    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior

    mov r17, r5
    or r17, r4
    cp r17, r16
    breq dezena_zero
    cbi   PORTB, 1  

    dezena_zero:

    mov r16, r5         ; Pega o valor 0-9 da Dezena
    lsl r16
    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 1    


    ; Unidade
    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior

    cbi   PORTB, 0    
    lsl r16

    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 0      
    
    ret



delay_mili:
   clr     r21         
   ldi     r22, 10
   ldi     r23, 2 


delay_loop_mili:
    dec     r22         
    brne    delay_loop_mili  
    dec     r21         
    brne    delay_loop_mili  
    dec     r23         
    brne    delay_loop_mili  
    ret



inc_pointer:
    adiw r26, 1             ; Incrementa o ponteiro X (r27:r26)

    ldi r18, low(fim_lista) ; Carrega o byte baixo do endereço de fim
    ldi r19, high(fim_lista) ; Carrega o byte alto do endereço de fim

    cp  r26, r18            ; Compara a parte baixa
    cpc r27, r19            ; Compara a parte alta com o Carry do anterior
    
    ; IF
    brne fim_inc            ; Se NÃO for igual ao fim, sai da função
    
    ; --- ELSE (Reset para o início da lista, Exibição Rotativa) ---
    ldi r26, low(lista)     
    ldi r27, high(lista)     

fim_inc:
    ret


.cseg
lista:
    .db 10, 16, 59, 81, 90, 100, 140, 220, 230, 240
fim_lista:


main:
    
    ; Definindo PORTD como saída
    ldi r16, 0x1E
    out DDRD, r16 ; 0001 1110

    sbi DDRB, 0 ; PB0 (Pino 8) Saída
    sbi DDRB, 1 ; PB0 (Pino 8) Saída
    sbi DDRB, 2 ; PB0 (Pino 8) Saída

   ; Elemento Inicial da Lista L(0)
    ldi r30, low(lista)
    ldi r31, high(lista)
    
    ; Registrador X para transferência entre FLASH e RAM
    mov r26, r30
    mov r27, r31

MAIN_LOOP:
    ; Copia o endereço atual do X para o Z para poder usar o LPM
    mov r30, r26
    mov r31, r27

    ; Busca o valor atual da Lista(L(0), L(1), ...)
    lpm r20, Z          

    ; Converte o numero em r20 para BCD
    rcall convert_BCD   
    
    ; Loop longo(~1 s)
    ldi r25, 14
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação rápida
    dec r25
    brne loop_pov

    
    ; Incrementa o ponteiro da lista
    rcall inc_pointer


    rjmp MAIN_LOOP
rjmp main




.cseg


convert_BCD:


  dividir:
    CLR R4 //limpa R4
    CLR R5 //limpa R5
    CLR R6 //limpa R6
    MOV R16, R20 //preserva R0
    

  div_centena:
    CPI R16, 0x64
    BRLO div_dezena //Desvia se R7<R1
    SUBI R16, 0x64
    INC R4
    rjmp div_centena
    
    
  div_dezena:
    CPI R16, 0x0A
    BRLO div_unidade
    SUBI R16, 0x0A
    INC R5
    rjmp div_dezena //Desvia se R7<R1

  div_unidade:
    CPI R16, 0x01
    BRLO div_sair
    SUBI R16, 0x01
    INC R6
    rjmp div_unidade //Desvia se R7<R1
  //div_unidade:

    
  div_sair:
    //MOV R6, R16
    RET //retorna
    //R4, R5, R6 retorna os valores de Dezena, Centena e Unidade respectivamente.


exibir_pov:


    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior
    
    cp r4, r16
    breq centena_zero
    cbi   PORTB, 2

    centena_zero:

    mov r16, r4         ; Pega o valor 0-9 da Centena
    lsl r16
    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 2 


    ; Dezena
    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior

    mov r17, r5
    or r17, r4
    cp r17, r16
    breq dezena_zero
    cbi   PORTB, 1  

    dezena_zero:

    mov r16, r5         ; Pega o valor 0-9 da Dezena
    lsl r16
    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 1    


    ; Unidade
    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior

    cbi   PORTB, 0    
    lsl r16

    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 0      
    
    ret



delay_mili:
   clr     r21         
   ldi     r22, 10
   ldi     r23, 2 


delay_loop_mili:
    dec     r22         
    brne    delay_loop_mili  
    dec     r21         
    brne    delay_loop_mili  
    dec     r23         
    brne    delay_loop_mili  
    ret



inc_pointer:
    adiw r26, 1             ; Incrementa o ponteiro X (r27:r26)

    ldi r18, low(fim_lista*2) ; Carrega o byte baixo do endereço de fim
    ldi r19, high(fim_lista*2) ; Carrega o byte alto do endereço de fim

    cp  r26, r18            ; Compara a parte baixa
    cpc r27, r19            ; Compara a parte alta com o Carry do anterior
    
    ; IF
    brne fim_inc            ; Se NÃO for igual ao fim, sai da função
    
    ; --- ELSE (Reset para o início da lista, Exibição Rotativa) ---
    ldi r26, low(lista*2)     
    ldi r27, high(lista*2)     

fim_inc:
    ret


//.section .progmem
lista:
    .db 10, 160, 170, 180, 190, 200, 210, 220, 230, 240
fim_lista:


main:
    
    ; Definindo PORTD como saída
    ldi r16, 0x1E
    out DDRD, r16 ; 1111 1110

    sbi DDRB, 0 ; PB0 (Pino 8) Saída
    sbi DDRB, 1 ; PB0 (Pino 8) Saída
    sbi DDRB, 2 ; PB0 (Pino 8) Saída

   ; Elemento Inicial da Lista L(0)
    ldi r30, low(lista*2)
    ldi r31, high(lista*2)
    
    ; Registrador X para transferência entre FLASH e RAM
    mov r26, r30
    mov r27, r31

MAIN_LOOP:
    ; Copia o endereço atual do X para o Z para poder usar o LPM
    mov r30, r26
    mov r31, r27

    ; Busca o valor atual da Lista(L(0), L(1), ...)
    lpm r20, Z          

    ; Converte o numero em r20 para BCD
    rcall convert_BCD   
    

    ; Loop longo(~1 s)
    ldi r25, 14
loop_pov:
    rcall exibir_pov    ;  Exibe CDU, usando multiplexação rápida
    dec r25
    brne loop_pov

    
    ; Incrementa o ponteiro da lista
    rcall inc_pointer


    rjmp MAIN_LOOP
