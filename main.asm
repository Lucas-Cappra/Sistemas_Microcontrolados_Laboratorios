
rjmp main




DELAY_1_SEG:
    ; Reseta o contador
    ldi r17, 0
    sts TCNT1H, r17      // Usa STS porque o Timer1 está longe na memória
    sts TCNT1L, r17

    ; Carrega o pre-scaler (1024)	
    ; CS12 representa a posição 2, e CS10 a posição 0.
    ; O deslocamento de bits é feito 2 e 0 vezes para a ESQUERDA.
    ldi r17, (1<<CS12) | (1<<CS10) 
    sts TCCR1B, r17

WAIT_TIMER:
    ; Lê o registrador de flags do timer
    in r17, TIFR1

    rcall exibir_pov

    ; Compara se o valor em r16 estourou (TOV1 = 1) e pula pra proxima linha
    sbrs r17, TOV1

    ; Volta pra flag WAIT_TIMER
    rjmp WAIT_TIMER

    ; Se estourou, pula pra essa linha e desligamos o timer
    ldi r17, 0
    sts TCCR1B, r17

    ; Limpa a flag de estouro
    ldi r17, (1<<TOV1)
    out TIFR1, r17
    
    ; Retorna para o loop principal
    ret



fim_funcao:

    ret


convert_BCD:

    inicio:

	  //LDI ZL, r24
    MOV R0, R16 //copia R16 para R0

    RCALL dividir


  dividir:
    CLR R4 //limpa R4
    CLR R5 //limpa R5
    CLR R6 //limpa R6
    MOV R16, R0 //preserva R0

  div_centena:
    SUBI R16, 0x64
    INC R4
    CPI R16,0x64
    BRGE div_centena
    BRLO div_dezena //Desvia se R7<R1
    
  div_dezena:
    SUBI R16, 0x0A
    INC R5
    CPI R16, 0x0A
    BRGE div_dezena
    BRLO div_unidade //Desvia se R7<R1

  div_unidade:
    SUBI R16, 0x01
    INC R6
    CPI R16, 0x0A
    BRGE div_unidade
    BRLO div_sair //Desvia se R7<R1

  div_sair:
    MOV R8, R7
    RET //retorna
    //R4, R5, R6 retorna os valores de Dezena, Centena e Unidade respectivamente.




inc_pointer:
    adiw ZL, 2 // Incrementa o ponteiro Z
    
    // Verifica se passou do 10º elemento (lista + 10)
    // Se sua lista for .dw (2 bytes cada), mude para + 20
    cpi ZL, low((lista<<1) + 10)
    ldi r17, high((lista<<1) + 10)
    cpc ZH, r17
    brne fim_inc
    
    // Reset para o início se chegar ao fim
    ldi ZH, high(lista<<1)
    ldi ZL, low(lista<<1)
fim_inc:
    ret



exibir_pov:
    
    ; Centena 
    sbi   PORTB, 0
    ldi   r19, 1
    
    ; Carregar valor da Dezena nas Portas D
    SWAP   r5
    out PORTD, r5 

    rcall delay  
    cbi   PORTB, 0 


    ; Dezena
    sbi   PORTD, 3  
    ldi   r19, 1
    
    SWAP   r4
    out PORTD, r4 


    rcall delay
    cbi   PORTD, 3     


    ; Unidade
    sbi   PORTD, 2     
    ldi   r19, 1
    SWAP   r6
    out PORTD, r6 


    rcall delay
    cbi   PORTD, 2      
    
    ret


delay:
   clr     r17         
   clr     r18 


delay_loop:
   dec     r18         
   brne    delay_loop  
   dec     r17         
   brne    delay_loop  
   dec     r19         
   brne    delay_loop  
   ret


lista:
    .dw 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 ; Seus 10 valores


main:

    ; Pinos 7, 6, 5, 4, 3 E 2 para como saídas
    ldi r16,  (1<<DDD7) | (1<<DDD6) | (1<<DDD5) | (1<<DDD4) | (1<<DDD3) | (1<<DDD2) 
    out DDRD, r16

    sbi DDRB, 0 ; PB0 (Pino 8) Saída

    ldi ZH, high(lista<<1)
    ldi ZL, low(lista<<1)




MAIN_LOOP:

    lpm r16, Z           // Pega o valor atual da lista
    rcall convert_BCD    // Prepara R4, R5, R6

    rcall DELAY_1_SEG
    rcall inc_pointer

    rjmp MAIN_LOOP       ; Loop infinito



    