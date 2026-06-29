#define F_CPU 16000000UL
#include <avr/interrupt.h>
#include <avr/io.h>
#include <stdlib.h>

#include "FreeRTOS.h"
#include "task.h"

#include "lcd.h"


void vApplicationIdleHook( void ) {
}


// Vari�veis Globais
const uint32_t F_s = 10000;
uint16_t i = 0;


typedef struct {
	uint32_t ponteiro_fase;
	uint32_t f;
	uint32_t inc;
} signal;

// Objeto Sinal que guarda as propriedades importantes
volatile signal sinal = {0, 0, 0};

// LUT da senoide
const uint8_t senoide[256] = {
	128, 131, 134, 137, 140, 143, 146, 149, 152, 156, 159, 162, 165, 168, 171, 174,
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
	81, 84, 87, 90, 93, 96, 99, 102, 105, 109, 112, 115, 118, 121, 124, 127
};

// Mapeamento dos Bot�es
#define BTN_M     PC0
#define BTN_UP    PC1
#define BTN_DOWN  PC2
#define BTN_A     PC3

typedef enum { QUADRADA = 0, TRIANGULAR, RAMPA, SENOIDE } WaveType;
typedef enum { SEL_ONDA = 0, SEL_DUTY, SEL_FREQ, SEL_VPP, SEL_OFFSET } Parametro;



// Vari�veis Globais de Controle do Sinal
volatile WaveType tipo_onda = SENOIDE;
volatile uint8_t duty = 50;
volatile uint16_t frequencia = 50;
volatile uint8_t vpp = 20;
volatile uint8_t offset = 25;
volatile uint8_t saida = 1;
volatile Parametro parametro = SEL_ONDA;
volatile uint8_t update_display = 1;

// Constantes do tempo de retrigger dos bot�es UP/DOWN
#define PERIODO_LOOP_MS         30    // per�odo do loop principal da task (vTaskDelay no fim)
#define LIMIAR_ACELERA_MS       5000  // tempo pressionado para come�ar a acelerar
#define INTERVALO_REPEAT_LENTO  500   // ms entre repeti��es antes de acelerar
#define INTERVALO_REPEAT_RAPIDO 100   // ms entre repeti��es depois de acelerar


// Declara��o das Tasks
void vTaskLCD(void *pvParameters);
void vTaskButtons(void *pvParameters);



// Fun��es de Setup
void buttons_init(void) {
	// Configura��o dos Bot�es
	DDRC &= ~((1<<BTN_M) | (1<<BTN_UP) | (1<<BTN_DOWN) | (1<<BTN_A));
	PORTC |= (1<<BTN_M) | (1<<BTN_UP) | (1<<BTN_DOWN) | (1<<BTN_A);
}

static inline void dac_write(uint8_t val) {
	PORTC = (PORTC & 0xCF) | ((val & 0x03) << 4);
	PORTB = val >> 2;
}

// Fu���o Geradora dos Sinais
void processar_gerador(void) {
	if (!saida) {
		dac_write(0);
		return;
	}

	uint8_t saida_DAC = 0;
	uint16_t N = F_s / frequencia;
	uint16_t M = (duty * N) / 100;
	int8_t pm = 0;
	
	
	if (tipo_onda == SENOIDE) {
		
		sinal.ponteiro_fase += sinal.inc;
		uint8_t indice = (uint8_t)(sinal.ponteiro_fase >> 24);
		saida_DAC = (vpp * senoide[indice]) / 50;
	}
	else if (tipo_onda == RAMPA) {
		sinal.ponteiro_fase += sinal.inc;
		uint8_t amp_rampa = (uint8_t)(sinal.ponteiro_fase >> 24);
		saida_DAC = ((uint16_t)amp_rampa* vpp) / 50;
	}
	else if (tipo_onda == QUADRADA) {
		if (i >= N - 1) i = 0;
		saida_DAC = (i < M) ? (256 * vpp / 50) : 0;
		i++;
	}
	else if (tipo_onda == TRIANGULAR) {
		
		uint16_t amp_triangular = (uint8_t)(sinal.inc >> 24);
		if (i >= N - 1) {
			i = 0;
			sinal.ponteiro_fase = 0;
		}
		pm = (i >= M) ? -1 : 1;
		sinal.ponteiro_fase += pm * amp_triangular;

		saida_DAC = sinal.ponteiro_fase;
		i++;
	}

	dac_write(saida_DAC+(256*offset)/50);
}

// O Timer estoura estritamente a 10kHz e gera o sinal imediatamente
ISR(TIMER2_COMPA_vect) {
	processar_gerador();
}

// Substitua a fun��o setup_timer por esta
void setup_timer(void) {
	// Zera os registradores de controle do Timer 2
	TCCR2A = 0;
	TCCR2B = 0;
	TCNT2  = 0;
	
	// Configura o valor de compara��o para estourar a exatos 10kHz
	OCR2A  = 24;

	// Ativa o modo CTC (Clear Timer on Compare Match) no Timer 2
	TCCR2A |= (1 << WGM21);
	
	// Configura o Prescaler para 64 (CS22 = 0, CS21 = 0, CS20 = 0)
	TCCR2B |= (1 << CS22) | (0 << CS21) | (0 << CS20);
	
	// Ativa a interrup��o por compara��o do canal A
	TIMSK2 |= (1 << OCIE2A);
}

void setup_dac(void) {
	DDRB |= 0b00111111;
	DDRC |= 0b00110000;
}

// =====================================================
// MAIN
// =====================================================
int main(void) {
	setup_dac();
	buttons_init();
	lcd_init();
	
	sinal.inc = (uint32_t)(((uint64_t)frequencia << 32) / F_s);
	
	lcd_clear();
	lcd_xy(2, 0);
	lcd_str("ATIVIDADE 8");
	lcd_xy(5, 1);
	lcd_str("MGS");
	
	setup_timer();
	sei(); // Liga interrup��es globais

	// Cria��o das Tasks
	xTaskCreate(vTaskLCD, "LCD", 120, NULL, 2, NULL);
	xTaskCreate(vTaskButtons, "BTNS", 100, NULL, 3, NULL);

	// Inicia o Escalonador do FreeRTOS
	vTaskStartScheduler();

	while(1);
}

// =====================================================
// TASKS
// =====================================================

void vTaskLCD(void *pvParameters) {
	char buffer[10];
	
	// Aguarda os 2 segundos
	vTaskDelay(pdMS_TO_TICKS(2000));

	for(;;) {
		if (update_display) {
			update_display = 0;
			lcd_clear();

			// --- LINHA 1 ---
			lcd_xy(0, 0);
			switch(tipo_onda) {
				case QUADRADA:   lcd_str("QUA"); break;
				case TRIANGULAR: lcd_str("TRI"); break;
				case RAMPA:      lcd_str("RAM"); break;
				case SENOIDE:    lcd_str("SEN"); break;
			}

			if(tipo_onda == QUADRADA || tipo_onda == TRIANGULAR) {
				lcd_xy(6, 0);
				itoa(duty, buffer, 10);
				lcd_str(buffer);
				lcd_str("%");
			}

			lcd_xy(12, 0);
			lcd_str(saida ? "ON " : "OFF");

			// --- LINHA 2 ---
			lcd_xy(0, 1);
			itoa(frequencia, buffer, 10);
			lcd_str(buffer);

			lcd_xy(6, 1);
			buffer[0] = (vpp / 10) + '0'; buffer[1] = '.'; buffer[2] = (vpp % 10) + '0'; buffer[3] = '\0';
			lcd_str(buffer);

			lcd_xy(12, 1);
			buffer[0] = (offset / 10) + '0'; buffer[1] = '.'; buffer[2] = (offset % 10) + '0'; buffer[3] = '\0';
			lcd_str(buffer);

			// --- INDICADOR DE EDI��O ---
			switch(parametro) {
				case SEL_ONDA:   lcd_xy(3, 0);  lcd_data('*'); break;
				case SEL_DUTY:   lcd_xy(9, 0);  lcd_data('*'); break;
				case SEL_FREQ:   lcd_xy(3, 1);  lcd_data('*'); break;
				case SEL_VPP:    lcd_xy(9, 1);  lcd_data('*'); break;
				case SEL_OFFSET: lcd_xy(15, 1); lcd_data('*'); break;
			}
		}
		// Executa a cada 100ms para poupar CPU
		vTaskDelay(pdMS_TO_TICKS(100));
	}
}

void vTaskButtons(void *pvParameters) {
	uint8_t ultimo_estado_M = 1, ultimo_estado_A = 1;

	uint16_t tempo_pressionado_UP = 0;
	uint16_t tempo_desde_repeat_UP = 0;

	// --- Estado de auto-repeat do bot�o DOWN (mesma l�gica, espelhada) ---
	uint16_t tempo_pressionado_DOWN = 0;
	uint16_t tempo_desde_repeat_DOWN = 0;
	
	sinal.inc = (uint32_t)(((uint64_t)frequencia << 32) / F_s);

	for(;;) {
		// --- Bot�o M ---
		if (!(PINC & (1 << BTN_M)) && ultimo_estado_M) {
			parametro++;
			if (parametro > SEL_OFFSET) parametro = SEL_ONDA;
			update_display = 1;
			ultimo_estado_M = 0;
			} else if (PINC & (1 << BTN_M)) {
			ultimo_estado_M = 1;
		}

		// --- Bot�o A ---
		if (!(PINC & (1 << BTN_A)) && ultimo_estado_A) {
			saida = !saida;
			update_display = 1;
			ultimo_estado_A = 0;
			} else if (PINC & (1 << BTN_A)) {
			ultimo_estado_A = 1;
		}

		// --- Bot�o UP
		if (!(PINC & (1 << BTN_UP))) {
			// Bot�o pressionado neste instante.
			tempo_pressionado_UP += PERIODO_LOOP_MS;
			tempo_desde_repeat_UP += PERIODO_LOOP_MS;


			uint16_t intervalo_atual_UP = (tempo_pressionado_UP >= LIMIAR_ACELERA_MS)
			? INTERVALO_REPEAT_RAPIDO
			: INTERVALO_REPEAT_LENTO;

			if (tempo_desde_repeat_UP >= intervalo_atual_UP) {
				switch(parametro) {
					case SEL_ONDA:   if(tipo_onda < SENOIDE) tipo_onda++; break;
					case SEL_DUTY:   if(duty < 99) duty++; break;
					case SEL_FREQ:   if(frequencia < 100) frequencia++; break;
					case SEL_VPP:    if(vpp < 50) vpp++; break;
					case SEL_OFFSET: if(offset < 50) offset++; break;
				}
				update_display = 1;
				tempo_desde_repeat_UP = 0; // s� zera o contador de intervalo,
				// tempo_pressionado_UP continua contando
			}
			} else {
			// Bot�o solto: reseta todo o estado de auto-repeat
			tempo_pressionado_UP = 0;
			tempo_desde_repeat_UP = 0;
		}

		// --- Bot�o DOWN
		if (!(PINC & (1 << BTN_DOWN))) {
			tempo_pressionado_DOWN += PERIODO_LOOP_MS;
			tempo_desde_repeat_DOWN += PERIODO_LOOP_MS;

			uint16_t intervalo_atual_DOWN = (tempo_pressionado_DOWN >= LIMIAR_ACELERA_MS)
			? INTERVALO_REPEAT_RAPIDO
			: INTERVALO_REPEAT_LENTO;

			if (tempo_desde_repeat_DOWN >= intervalo_atual_DOWN) {
				switch(parametro) {
					case SEL_ONDA:   if(tipo_onda > QUADRADA) tipo_onda--; break;
					case SEL_DUTY:   if(duty > 1) duty--; break;
					case SEL_FREQ:   if(frequencia > 1) frequencia--; break;
					case SEL_VPP:    if(vpp > 0) vpp--; break;
					case SEL_OFFSET: if(offset > 0) offset--; break;
				}
				update_display = 1;
				tempo_desde_repeat_DOWN = 0;
			}
			} else {
			tempo_pressionado_DOWN = 0;
			tempo_desde_repeat_DOWN = 0;
		}

		// Pulling dos bot�es a cada 30ms
		vTaskDelay(pdMS_TO_TICKS(PERIODO_LOOP_MS));
	}
}
