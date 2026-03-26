#define __SFR_OFFSET 0   // Ajuste obrigatório no GCC para os comandos OUT e IN funcionarem
#include <avr/io.h>      // Biblioteca padrão do GCC com os registradores do ATmega328

.global main             ; Diz ao compilador onde o programa começa

rjmp main





convert_BCD:


  dividir:
    CLR R4 //limpa R4
    CLR R5 //limpa R5
    CLR R6 //limpa R6
    MOV R16, R20 //preserva R0
    

  div_centena:
    CPI R16, 0x64
    BRLO div_dezena //Desvia se R16<R100
    SUBI R16, 0x64
    INC R4
    rjmp div_centena
    
    
  div_dezena:
    CPI R16, 0x0A
    BRLO div_unidade //Desvia se R16<10
    SUBI R16, 0x0A
    INC R5
    rjmp div_dezena 

  div_unidade:
    CPI R16, 0x01
    BRLO div_sair //Desvia se R16<1
    SUBI R16, 0x01
    INC R6
    rjmp div_unidade 

    
  div_sair:
    //MOV R6, R16
    RET //retorna
    //R4, R5, R6 retorna os valores de Dezena, Centena e Unidade respectivamente.


exibir_pov:


    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior
    
    ; Comparação para ascender a centena apenas se L(i) > 100
    cp r4, r16
    breq centena_zero
    cbi   PORTB, 2

    centena_zero:
    mov r16, r4         // Pega o valor 0-9 da Centena
    rcall decodificar
    lsl r16

    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 2 


    ; Dezena
    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior

    ; Comparação para ascender a dezena apenas se L(i) > 10

    mov r17, r5
    or r17, r4
    cp r17, r16
    breq dezena_zero
    cbi   PORTB, 1  

    dezena_zero:
    mov r16, r5         // Pega o valor 0-9 da Dezena
    rcall decodificar
    lsl r16

    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 1    


    ; Unidade
    ldi   r16, 0         ; Limpa r16 antes de carregar
    out   PORTD, r16     ; Limpa o rastro do digito anterior

    cbi   PORTB, 0    
    mov r16, r6         // Pega o valor 0-9 da Unidade
    rcall decodificar
    lsl r16

    out PORTD, r16
    rcall delay_mili
    sbi   PORTB, 0      
    
    ret



delay_mili:
  ; Emula um for Triplo com objetivo de fazer um delay
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



decodificar:
    push ZL
    push ZH
    push r17

    ; 1. Carrega a parte alta e baixa do endereço inicial da Tabela 7SEG
    ldi ZL, lo8(tabela_7seg)
    ldi ZH, hi8(tabela_7seg)

    ; 2. SOMA o dígito (0-9) diretamente para obter o numero correspondente
    ;  BCD-> abcdfeg
    add ZL, r16
    clr r17
    adc ZH, r17

    ; 3. Coloca em r16 o "desenho" do numero de acordo com a tabela
    lpm r16, Z

    ; 4. Desocupa os Registradores e Retorna
    pop r17
    pop ZH
    pop ZL
    ret



inc_pointer:
    adiw r26, 1             ; Incrementa o ponteiro X (r27:r26)

    ; Verificação Circular
    ldi r18, lo8(fim_lista) ; Carrega o byte baixo do endereço de fim
    ldi r19, hi8(fim_lista) ; Carrega o byte alto do endereço de fim

    cp  r26, r18            ; Compara a parte baixa
    cpc r27, r19            ; Compara a parte alta com o Carry do anterior
    
    ; IF
    brne fim_inc            ; Se NÃO for igual ao fim, sai da função
    
    ; --- ELSE (Reset para o início da lista, Exibição Rotativa) ---
    ldi r26, lo8(lista)     
    ldi r27, hi8(lista)     

fim_inc:
    ret



.align 2
tabela_7seg:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x00

//        gfe dcba 
// 3F -> 0011 1111 -> 0 0000 0000
// 06 -> 0000 0110 -> 1 0000 0001
// 5B -> 0101 1011 -> 2 0000 0010
// 4F -> 0100 1111  -> 3 0000 0011 
// 66 -> 0110 0110  -> 4 0000 0100

.section .progmem.data

lista:
    .byte 5, 6, 50, 90, 150, 200, 210, 220, 230, 240
fim_lista:

main:
    
    ; Definindo PORTD como saída
    ldi r16, 0xFE
    out DDRD, r16 ; 1111 1110

    sbi DDRB, 0 ; PB0 (Pino 8) Saída
    sbi DDRB, 1 ; PB0 (Pino 8) Saída
    sbi DDRB, 2 ; PB0 (Pino 8) Saída

   ; Elemento Inicial da Lista L(0)
    ldi r30, lo8(lista)
    ldi r31, hi8(lista)
    
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
