#define F_CPU 16000000UL
#include <avr/interrupt.h>
#include <avr/io.h>
#include <util/delay.h>
#include <stdlib.h>
#include "lcd.c"
#include "lcd.h"



// Variáveis Globais
const uint32_t F_s = 10000;
uint16_t i = 0;


typedef struct {
	uint32_t ponteiro_fase;
	uint32_t f;
	uint32_t inc;
} signal;



volatile signal sinal = {0, 0, 0};

// =====================================================
// LUT da senoide
// =====================================================
const uint8_t senoide[256] = {128, 131, 134, 137, 140, 143, 146, 149, 152, 156, 159, 162, 165, 168, 171, 174,
	176, 179, 182, 185, 188, 191, 193, 196, 199, 201, 204, 206, 209, 211, 213, 216,
	218, 220, 222, 224, 226, 228, 230, 232, 234, 235, 237, 239, 240, 242, 243, 244,
	246, 247, 248, 249, 250, 251, 251, 252, 253, 253, 254, 254, 254, 255, 255, 255,
	255, 255, 255, 255, 254, 254, 253, 253, 252, 252, 251, 250, 249, 248, 247, 246,
	245, 244, 242, 241, 239, 238, 236, 235, 233, 231, 229, 227, 225, 223, 221, 219,
	217, 215, 212, 210, 207, 205, 202, 200, 197, 195, 192, 189, 186, 184, 181, 178,
	175, 172, 169, 166, 163, 160, 157, 154, 151, 148, 145, 142, 139, 135, 132, 129,
	126, 123, 120, 117, 113, 110, 107, 104, 101, 98, 95, 92, 89, 86, 83, 80,
	77, 74, 71, 69, 66, 63, 60, 58, 55, 53, 50, 48, 45, 43, 41, 38,
	36, 34, 32, 30, 28, 26, 24, 22, 20, 19, 17, 16, 14, 13, 11, 10,
	9, 8, 7, 6, 5, 4, 3, 3, 2, 2, 1, 1, 0, 0, 0, 0,
	0, 0, 0, 1, 1, 1, 2, 2, 3, 4, 4, 5, 6, 7, 8, 9,
	11, 12, 13, 15, 16, 18, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37,
	39, 42, 44, 46, 49, 51, 54, 56, 59, 62, 64, 67, 70, 73, 76, 78,
81, 84, 87, 90, 93, 96, 99, 102, 105, 109, 112, 115, 118, 121, 124, 127};



// =====================================================
// BOTÕES
// =====================================================

#define BTN_M     PC0
#define BTN_UP    PC1
#define BTN_DOWN  PC2
#define BTN_A     PC3

// =====================================================
// TIPOS DE ONDA
// =====================================================

typedef enum
{
	QUADRADA = 0,
	TRIANGULAR,
	RAMPA,
	SENOIDE

} WaveType;

// =====================================================
// PARÂMETROS
// =====================================================

typedef enum
{
	SEL_ONDA = 0,
	SEL_DUTY,
	SEL_FREQ,
	SEL_VPP,
	SEL_OFFSET

} Parametro;

// =====================================================
// VARIÁVEIS
// =====================================================

volatile WaveType tipo_onda = SENOIDE;

volatile uint8_t duty = 50;

volatile uint16_t frequencia = 100;

// valor armazenado x10
volatile uint8_t vpp = 20;      // 2.0V
volatile uint8_t offset = 25;   // 2.5V

volatile uint8_t saida = 0;

volatile Parametro parametro = SEL_ONDA;

volatile uint8_t update_display = 1;

// =====================================================
// BOTÕES
// =====================================================

void buttons_init(void)
{
	
	DDRC &= ~(
	(1<<BTN_M)    |
	(1<<BTN_UP)   |
	(1<<BTN_DOWN) |
	(1<<BTN_A)
	);

	PCICR |= (1 << PCIE1);
	PCMSK1 |= (1 << PCINT8) | (1 << PCINT9) | (1 << PCINT10) | (1 << PCINT11);
	sei();
}

// =====================================================
// LCD
// =====================================================

void lcd_task(void)
{
	char buffer[10];

	if(!update_display)
	return;

	update_display = 0;

	lcd_clear();

	// =============================
	// LINHA 1
	// =============================

	lcd_xy(0,0);

	switch(tipo_onda)
	{
		case QUADRADA:
		lcd_str("QUA");
		break;

		case TRIANGULAR:
		lcd_str("TRI");
		break;

		case RAMPA:
		lcd_str("RAM");
		break;

		case SENOIDE:
		lcd_str("SEN");
		break;
	}

	if(tipo_onda == QUADRADA ||
	tipo_onda == TRIANGULAR)
	{
		lcd_xy(6,0);

		itoa(duty, buffer, 10);

		lcd_str(buffer);
		lcd_str("%");
	}

	lcd_xy(12,0);

	if(saida)
	lcd_str("ON ");
	else
	lcd_str("OFF");

	// =============================
	// LINHA 2
	// =============================

	lcd_xy(0,1);

	itoa(frequencia, buffer, 10);

	lcd_str(buffer);

	lcd_xy(6,1);

	buffer[0] = (vpp / 10) + '0';
	buffer[1] = '.';
	buffer[2] = (vpp % 10) + '0';
	buffer[3] = '\0';

	lcd_str(buffer);

	lcd_xy(12,1);

	buffer[0] = (offset / 10) + '0';
	buffer[1] = '.';
	buffer[2] = (offset % 10) + '0';
	buffer[3] = '\0';

	lcd_str(buffer);

	// =============================
	// INDICADOR DE EDIÇÃO
	// =============================

	switch(parametro)
	{
		case SEL_ONDA:
		lcd_xy(3,0);
		lcd_data('*');
		break;

		case SEL_DUTY:
		lcd_xy(9,0);
		lcd_data('*');
		break;

		case SEL_FREQ:
		lcd_xy(3,1);
		lcd_data('*');
		break;

		case SEL_VPP:
		lcd_xy(9,1);
		lcd_data('*');
		break;

		case SEL_OFFSET:
		lcd_xy(15,1);
		lcd_data('*');
		break;
	}
}

// =====================================================
// LEITURA DOS BOTÕES
// =====================================================

ISR(PCINT1_vect)
{
	// =========================
	// M
	// =========================

	if(!(PINC & (1<<BTN_M)))
	{
		_delay_ms(50);

		if(!(PINC & (1<<BTN_M)))
		{
			parametro++;

			if(parametro > SEL_OFFSET)
			parametro = SEL_ONDA;

			update_display = 1;

			while(!(PINC & (1<<BTN_M)));
		}
	}

	// =========================
	// A
	// =========================

	if(!(PINC & (1<<BTN_A)))
	{
		_delay_ms(50);

		if(!(PINC & (1<<BTN_A)))
		{
			saida = !saida;

			update_display = 1;

			while(!(PINC & (1<<BTN_A)));
		}
	}

	// =========================
	// UP
	// =========================

	if(!(PINC & (1<<BTN_UP)))
	{
		_delay_ms(50);

		if(!(PINC & (1<<BTN_UP)))
		{
			switch(parametro)
			{
				case SEL_ONDA:

				if(tipo_onda < SENOIDE)
				tipo_onda++;
				break;

				case SEL_DUTY:

				if(duty < 99)
				duty++;
				break;

				case SEL_FREQ:

				if(frequencia < 100)
				frequencia++;
				break;

				case SEL_VPP:

				if(vpp < 50)
				vpp++;
				break;

				case SEL_OFFSET:

				if(offset < 50)
				offset++;
				break;
			}

			update_display = 1;

			while(!(PINC & (1<<BTN_UP)));
		}
	}

	// =========================
	// DOWN
	// =========================

	if(!(PINC & (1<<BTN_DOWN)))
	{
		_delay_ms(50);

		if(!(PINC & (1<<BTN_DOWN)))
		{
			switch(parametro)
			{
				case SEL_ONDA:

				if(tipo_onda > QUADRADA)
				tipo_onda--;
				break;

				case SEL_DUTY:

				if(duty > 1)
				duty--;
				break;

				case SEL_FREQ:

				if(frequencia > 1)
				frequencia--;
				break;

				case SEL_VPP:

				if(vpp > 0)
				vpp--;
				break;

				case SEL_OFFSET:

				if(offset > 0)
				offset--;
				break;
			}

			update_display = 1;

			while(!(PINC & (1<<BTN_DOWN)));
		}
	}
}



static inline void dac_write(uint8_t val) {
	// Escreve na saída do DAC
	PORTC = (val & 0x03) << 4;
	PORTB =  val >> 2;
}


// Task do gerador de sinais

void task_gerador(volatile uint16_t frequencia, volatile signal *sinal){

	uint8_t saida_DAC;

	uint16_t N = F_s/frequencia;
	
	int8_t pm = 0;
	
	if (tipo_onda == SENOIDE){
		sinal->inc = (uint32_t)(((uint64_t)frequencia << 32) / F_s);
		sinal->ponteiro_fase = sinal->ponteiro_fase + sinal->inc;
		uint8_t indice = (uint8_t)(sinal->ponteiro_fase >> 24);
		
		saida_DAC = (vpp*senoide[indice])/50;
	}

	else if (tipo_onda == RAMPA){
		//sinal->inc = (uint32_t)(((uint64_t)frequencia << 32) / F_s);
		//sinal->inc = (sinal->inc >> 24);
		sinal->inc = (256*frequencia*50)/(F_s);
		sinal->ponteiro_fase = sinal->ponteiro_fase + sinal->inc;
		saida_DAC = (sinal->ponteiro_fase*vpp)/50;
	}
	
	else if ( tipo_onda == QUADRADA){
		
		uint16_t M = (duty*N)/100;
		//uint16_t M = N/3;
		if(i >= N-1){
		 	i = 0;
		}
		
		saida_DAC = (i<M) ? 256*vpp/50 : 0;
		i++;
	}
	
	else if ( tipo_onda == TRIANGULAR){
		
		uint16_t M = N/2;
		sinal->inc = (uint32_t)(((uint64_t)frequencia << 32) / F_s);
		sinal->inc = (sinal->inc >> 24);
		pm = (i >= M) ? -1 : 1;
		sinal->ponteiro_fase = sinal->ponteiro_fase + pm*sinal->inc;
		if(i >= N-1){
			 i = 0;
			 sinal->ponteiro_fase = 0;
		}
		saida_DAC = sinal->ponteiro_fase;
		i++;
		
	}


	dac_write(saida_DAC);

}


// Funções de Setup

void setup_timer(void) {
	// Inicializa os Registradores de Timer
	TCCR1A = 0;
	TCCR1B = 0;
	TCNT1  = 0;
	
	// Valor de contagem do timer 1A para estourar em exatos 10kHz
	OCR1A  = 25;

	// Registradores de timer e prescaler
	TCCR1B |= (1 << WGM12);
	TCCR1B |= (0 << CS12) | (1 << CS11) | (1 << CS10);
	TIMSK1 |= (1 << OCIE1A);
}

volatile uint8_t flag_amostragem = 0;

ISR(TIMER1_COMPA_vect) {
	flag_amostragem = 1;
}



void setup_dac(void) {
	// Seta os pinos do DAC
	DDRB |= 0b00111111;
	DDRC |= 0b00110000;
}



// =====================================================
// MAIN
// =====================================================

int main(void)
{
	
	
	setup_timer();

	setup_dac();

	lcd_init();

	buttons_init();

	lcd_clear();

	lcd_xy(2,0);
	lcd_str("ATIVIDADE 8");

	lcd_xy(5,1);
	lcd_str("MGS");

	_delay_ms(2000);

	update_display = 1;

	while(1)
	{

		lcd_task();

		if (flag_amostragem == 1){
			task_gerador(frequencia, &sinal);
		}

	}

}