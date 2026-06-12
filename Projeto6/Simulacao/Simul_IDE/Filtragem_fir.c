#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include <stdlib.h>
#include "lcd.h"
#include "lcd.c"


// =====================================================
// DEFINICOES
// =====================================================

#define BTN_MODE  PC1
#define BTN_UP    PC2
#define BTN_DOWN  PC3

#define FIR_ORDER 17

// =====================================================
// VARIAVEIS
// =====================================================

volatile uint8_t coeff_index = 0;

volatile uint8_t update_display = 1;

// =====================================================
// COEFICIENTES FIR
// =====================================================

volatile int16_t Filtro[FIR_ORDER] =
{
	-248,     // c0
	665,     // c1
	940,     // c2
	-190,     // c3
	-2027,     // c4
	-1580,     // c5
	3123,     // c6
	9688,     // c7
	12808,     // c8
	9688,     // c9
	3123,     // c10
	-1580,     // c11
	-2027,     // c12
	-190,     // c13
	940,     // c14
	665,     // c15
	-248      // c16
};


// =====================================================
// AD CONVERTER
// =====================================================

void setup_adc(){

	// Setup AD Converter:
	DDRC &= ~(1 << DDC0);

	// Referência AVcc (REFS0), Ajuste à Esquerda (ADLAR)
	ADMUX |= (1 << REFS0);

	// Habilita ADC (ADEN) e Prescaler 128 (ADPS0,1,2)
	ADCSRA |= (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);

}




uint16_t ler_adc(uint8_t pino){

	

	ADMUX &= 0xF0;
	ADMUX |= pino;

	// Inicia a conversão
	ADCSRA |= (1<<ADSC);

	// wait_adc:
	while (ADCSRA & (1 << ADSC)){};

	return ADC;
	
}



void setup_DA(){

	// Setup do D/A
	DDRB |= 0b00111111;
	DDRC |= 0b00110000;

}



// =====================================================
// TIMER CONFIGURATION
// =====================================================


void setup_timer(){

	// Setup do Timer
	TCCR1A = 0; // Zera o registrador de controle A
	TCCR1B = 0; // Zera o registrador de controle B
	TCNT1  = 0; // Zera o contador do Timer

	// Define o valor de comparação para estourar a cada 5ms (1250 passos - 1)
	OCR1A = 125;

	// Ativa o modo CTC (WGM12 = 1)
	TCCR1B |= (1 << WGM12);

	// Configura o Prescaler para 64 (CS11 = 1 e CS10 = 1)
	TCCR1B |= (1 << CS11) | (1 << CS10);

	// Ativa a interrupção por comparação do Timer 1
	TIMSK1 |= (1 << OCIE1A);


}




int16_t x[FIR_ORDER];

uint8_t position_k;


int32_t convolution(volatile int16_t Filter[], int16_t Signal[], uint8_t k){
	
	int32_t conv = 0;
	for (uint8_t i = 0; i <FIR_ORDER ; i++){
		int8_t n = k - i;
		if (n>17) n = n - FIR_ORDER;
		if (n < 0) n = n + FIR_ORDER;
		conv += (int32_t)Filter[i]*Signal[n];
		
	}
	
	return conv;
}



volatile int32_t y_k = 0;



volatile uint8_t flag_amostragem = 0;

ISR(TIMER1_COMPA_vect) {
	flag_amostragem = 1;
}


// =====================================================
// BUTTONS INIT
// =====================================================

void buttons_init(void) {
	DDRC &= ~((1 << DDC1) | (1 << DDC2) | (1 << DDC3));
	//PORTC |= (1 << PORTC1) | (1 << PORTC2) | (1 << PORTC3);
	PCICR |= (1 << PCIE1);
	PCMSK1 |= (1 << PCINT9) | (1 << PCINT10) | (1 << PCINT11);
}

// =====================================================
// BUTTON TASK
// =====================================================

ISR(PCINT1_vect)
{
	// =========================================
	// MODE -> TROCA COEFICIENTE
	// =========================================

	if(!(PINC & (1 << BTN_MODE)))
	{
		_delay_ms(1);

		if(!(PINC & (1 << BTN_MODE)))
		{
			coeff_index++;

			if(coeff_index >= FIR_ORDER)
			{
				coeff_index = 0;
			}

			update_display = 1;

			while(!(PINC & (1 << BTN_MODE)));
		}
	}

	// =========================================
	// UP -> INCREMENTA COEFICIENTE
	// =========================================

	if(!(PINC & (1 << BTN_UP)))
	{
		_delay_ms(1);

		if(!(PINC & (1 << BTN_UP)))
		{
			Filtro[coeff_index]++;

			update_display = 1;

			while(!(PINC & (1 << BTN_UP)));
		}
	}

	// =========================================
	// DOWN -> DECREMENTA COEFICIENTE
	// =========================================

	if(!(PINC & (1 << BTN_DOWN)))
	{
		_delay_ms(1);

		if(!(PINC & (1 << BTN_DOWN)))
		{
			Filtro[coeff_index]--;

			update_display = 1;

			while(!(PINC & (1 << BTN_DOWN)));
		}
	}
}

// =====================================================
// LCD TASK
// =====================================================
void lcd_task(void)
{
	char buffer[10];

	if(update_display)
	{
		update_display = 0;

		lcd_clear();

		// Primeira linha
		lcd_xy(0,0);
		lcd_str("Coeficiente");

		// Segunda linha
		lcd_xy(0,1);

		lcd_str("C");

		itoa(coeff_index, buffer, 10);
		lcd_str(buffer);

		lcd_str(": ");

		itoa(Filtro[coeff_index], buffer, 10);
		lcd_str(buffer);
	}
}

// =====================================================
// MAIN
// =====================================================

int main(void)
{


	setup_adc();

	setup_DA();

	setup_timer();


	int16_t x[FIR_ORDER] = {0};

	lcd_init();

	buttons_init();

	lcd_clear();

	lcd_xy(3,0);
	lcd_str("ELE-3717");

	lcd_xy(3,1);
	lcd_str("FILTRO FIR");

	
	sei();
	update_display = 1;


	uint8_t position_k = 0;
	// =====================================
	// LOOP PRINCIPAL
	// =====================================

	while(1)
	{

		lcd_task();
		
		if (flag_amostragem == 1){
	
			
			x[position_k] = ler_adc(0);
			position_k++; // Avança o ponteiro do círculo para a proxima amostra

			// Realiza a filtragem por convolução
			y_k = convolution(Filtro, x, position_k);
	
			// Lógica do ponteiro circular
			if (position_k > FIR_ORDER - 1) {
				position_k = 0;
			}
			
	
	
			// Deslocamento de 15 bits pra direita/Divisao por 2^15, pra compensar o filtro int
			y_k = y_k>>15;
	
			// Divisão por 4 pra se encaixar na faixa de 0 a 255
			y_k =  (y_k>>2) - 1;
	
		
	
			// Coloca o y_k diretamente na saída do conversor DA R-2R
			PORTC = ((y_k & 0x03) << 4);
			PORTB = ((y_k >> 2) & 0x3F);
	
			// Leitura terminou
			flag_amostragem = 0;
		}

	}
}
