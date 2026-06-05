#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>






void setup_adc(){

	// Setup AD Converter:
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


int16_t Filtro[17] = {
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



const uint8_t M = 17;

int16_t x[17];

uint8_t position_k;




int32_t convolution(int16_t Filter[], int16_t Signal[], uint8_t k){
	
	int32_t conv = 0;
	for (uint8_t i = 0; i <M ; i++){
		int8_t n = k - i;
		if (n>17) n = n - 17;
		if (n < 0) n = n + 17;
		conv += (int32_t)Filter[i]*Signal[n];
		
	}
	
	return conv;
}



volatile int32_t y_k = 0;


volatile uint8_t flag_amostragem = 0;

ISR(TIMER1_COMPA_vect) {
	flag_amostragem = 1;
}



int main(void) {
	
	
	setup_adc();
	
	
	// Setup do D/A
	DDRB |= 0b00111111;
	DDRC |= 0b00110000;
	
	
	cli();
	
	// Setup do Timer
	TCCR1A = 0; // Zera o registrador de controle A
	TCCR1B = 0; // Zera o registrador de controle B
	TCNT1  = 0; // Zera o contador do Timer

	// Define o valor de comparação para estourar a cada 5ms (1250 passos - 1)
	OCR1A = 125;
	
	// Ativa o modo CTC (WGM12 = 1)
	TCCR1B |= (1 << WGM12);

	// Configura o Prescaler para 1024 (CS12 = 1 e CS10 = 1)
	TCCR1B |= (0 << CS12) | (1 << CS11) | (1 << CS10);

	// Ativa a interrupção por comparação do Timer 1
	TIMSK1 |= (1 << OCIE1A);

	sei(); // Reativa as interrupções globais

	
	
	while(1) {
		
		
		if (flag_amostragem == 1){
			
			x[position_k] = ler_adc(0);
			position_k++; // Avança o ponteiro do círculo para a PRÓXIMA amostragem

			y_k = convolution(Filtro, x, position_k);
	        
			if (position_k > M - 1) {
				position_k = 0;
			}
			
			y_k = y_k>>15;
			y_k =  (y_k>>2) - 1;
			PORTC = ((y_k & 0x03) << 4);
			PORTB = ((y_k >> 2) & 0x3F);
			
			// Leitura terminou
			flag_amostragem = 0;
		}
		

		
	}
}

