#include <avr/io.h>





void setup_adc(){

	// setup_AD_Converter:
	// Canal A3 (MUX1 e MUX0), Referência AVcc (REFS0), Ajuste à Esquerda (ADLAR)
	ADMUX |= (1 << REFS0);

	// Habilita ADC (ADEN) e Prescaler 128 (ADPS0,1,2)
	ADCSRA |= (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);


}



void ler_adc(uint8_t pino){

	

	ADMUX &= 0xF0;
	ADMUX |= pino;

	// Inicia a conversão
	ADCSRA |= (1<<ADSC);

	// wait_adc:
	while (ADCSRA & (1 << ADSC)){};

	return ADC;
	
}