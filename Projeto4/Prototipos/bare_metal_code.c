#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>;


// Variáveis das intensidades das cores
volatile uint8_t RED = 1;
volatile uint8_t GREEN = 1;
volatile uint8_t BLUE = 1;

uint8_t STEP = 20;


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
    if (PINC & (1 << PC1)) {
        inc_valor(estado);
        while(PINC & (1 << PC1)); // Opcional: trava aqui enquanto o botão estiver apertado
    }

    if (PINC & (1 << PC2)) {
        dec_valor(estado);
        while(PINC & (1 << PC2));
    }

    if (PINC & (1 << PC3)) {
        if (estado >= blue) { // Corrigindo a lógica de giro
            estado = wait;
        } else {
            estado++;
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
  PORTD = 0x00 | (1 << PD3) | (0 << PD2) | (1 << PD1);
  break;

  case red:
  OCR1A = RED;
  PORTD =  0x00 | (1 << PD3) | (0 << PD2) | (0 << PD1); 
  break;

  case green:
  OCR1B = GREEN;
  PORTD = 0x00 | (0 << PD3) | (1 << PD2) | (0 << PD1);
  break;

  case blue:
  OCR2A = BLUE;
  PORTD = 0x00 | (0 << PD3) | (0 << PD2) | (1 << PD1);
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
    DDRC &= ~((1 << DDC1) | (1 << DDC2) | (1 << DDC3));


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
    OCR1A = BLUE; // Red
    OCR1B = GREEN; // Green
    OCR2A = RED; // Blue

    sei(); // Habilitador de Interrupções


    while (1)
    {   

        FSM(estado);
        OCR1A = BLUE; 
        OCR1B = GREEN;
        OCR2A = RED;

        // Delay
        _delay_ms(10); 
    }
}
