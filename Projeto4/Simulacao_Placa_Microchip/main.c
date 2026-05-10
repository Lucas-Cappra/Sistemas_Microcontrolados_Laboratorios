#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include "lcd.c"
#include <avr/interrupt.h>


// Variáveis das intensidades das cores
volatile uint8_t RED = 1;
volatile uint8_t GREEN = 1;
volatile uint8_t BLUE = 1;



uint8_t STEP = 8;

typedef enum {
    NO_SEL = 0,
    SEL_R,
    SEL_G,
    SEL_B
} sel_t;


volatile sel_t sel = NO_SEL;


// Enumeração dos Estados
typedef enum {
    init,   // 0
    wait,   // 1
    red,    // 2
    green,  // 3
    blue   // 4
} Estado_t;


// Variável de Estado Inicial
volatile Estado_t estado = init;


// ISR para interrupção no PORTC
ISR(PCINT1_vect) {
    // 1. Debounce: Espera o sinal estabilizar
    _delay_ms(40); 

    // 2. Só age se o botão AINDA estiver pressionado (evita disparar ao soltar)
    if (!(PINC & (1 << PC1))) {
        inc_valor(estado);
        while(PINC & (1 << PC1)); // Opcional: trava aqui enquanto o botão estiver apertado
    }

    if (!(PINC & (1 << PC2))) {
        dec_valor(estado);
        while(PINC & (1 << PC2));
    }

    if (!(PINC & (1 << PC3))) {



        if (estado >= blue) { // Corrigindo a lógica de giro
            estado = wait;
            sel = NO_SEL;
            
        } else {
            estado++;
            sel = (sel + 1) % 4;
        }

                
        
        while(PINC & (1 << PC3));
    }
}

// Função de Incrementar Valor
void inc_valor(Estado_t estado_atual){

  if (estado_atual == red){
    RED = RED + STEP;
  }

  else if (estado_atual == blue){
    BLUE = BLUE + STEP;
  }


  else if (estado_atual == green){
    GREEN = GREEN + STEP;
  }

}


// Função de Decrementar Valor
void dec_valor(Estado_t estado_atual){

  if (estado_atual == red){
    RED = RED - STEP;
  }

  else if (estado_atual == blue){
    BLUE = BLUE - STEP;
  }


  else if (estado_atual == green){
    GREEN = GREEN - STEP;
  }
}


// Função de Máquina de Estados 
void FSM(Estado_t estado_atual){

  switch (estado_atual)
{

  case init:
    estado = wait;
  break;

  case wait:
  break;

  case red:
  OCR2A = RED;
  lcd_set_values(RED, GREEN, BLUE);
  break;

  case green:
  OCR1B = GREEN;
  lcd_set_values(RED, GREEN, BLUE);
  break;

  case blue:
  OCR1A = BLUE;
  lcd_set_values(RED, GREEN, BLUE);
  break;

  default:
  init;

}
}





int main ( void )
{

    // Setup
    // Pinos do PWM como saída: PB3 (OC0A), PB2 (OC0B) e PB1 (OC2B)
    DDRB |= (1 << DDB3) | (1 << DDB2) | (1 << DDB1);

    DDRD |= (1 << DDD3) | (1 << DDD2) | (1 << DDD1);

    // Pinos PC1, PC2, PC3 como entrada (Botões)
    DDRC &= ~((1 << DDC0) | (1 << DDC1) | (1 << DDC2) | (1 << DDC3));


    // --- 2. INTERRUPÇÕES DE PIN CHANGE (PCINT) ---
    PCICR |= (1 << PCIE1);    // Habilita o grupo Port C
    PCMSK1 |= (1 << PCINT9) | (1 << PCINT10) | (1 << PCINT11); // Pinos PC1, PC2 e PC3


    // --- 3. CONFIGURAÇÃO DOS TIMERS (PWM) ---

    // --- TIMER 1 (Pinos 9 e 10) ---
    // COM1A1 = PB1, COM1B1 = PB2, COM2A1 = PB3
    // WGM10 e WGM12 configuram o modo "Fast PWM 8-bit"
    TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM10);
    TCCR1B = (1 << WGM12) | (1 << CS11); // Prescaler 8

    // --- TIMER 2 (Pino 11) ---
    // WGM21 e WGM20 configuram o modo "Fast PWM"
    TCCR2A = (1 << COM2A1) | (1 << WGM21) | (1 << WGM20);
    TCCR2B = (1 << CS21); // Prescaler 8


    // --- 4. VALORES INICIAIS (Duty Cycle) ---
    OCR1A = BLUE; // Blue
    OCR1B = GREEN; // Green
    OCR2A = RED; // Red

    sei(); // Habilitador de Interrupções



    // LCD Configuration
    lcd_init();

    lcd_xy(0,0);
    lcd_str("RED GREEN BLUE");

    lcd_xy(0,1);
    lcd_str(" 000 000 000");

    lcd_set_values(RED, GREEN, BLUE);
    lcd_update_cursor(sel);


    while (1)
    {   

        FSM(estado);
        lcd_update_cursor(sel);
        // Delay
        _delay_ms(10); 
    }
}