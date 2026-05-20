#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include "LCD.h"
#include "cobra.h"
#include "adc.h"


typedef unsigned char byte;

// =============================
// Protótipos MAX7219
// =============================


void max7219_init(void);
void max7219_clear(void);
void exibirCobra(uint8_t x[], uint8_t y[], byte matriz[]);


uint8_t linhas = 8;
uint8_t colunas = 8;


// =============================
// MAIN
// =============================



void animacao_game_over(){

	unsigned char dado = 255;

	for (uint8_t l = 0; l<8; l++){
		max7219_clear();
		max7219_send(l + 1, dado); // i+1 porque os registradores do MAX vão de 0x01 a 0x08
		_delay_ms(40);
		

	}

}



void setup_hardware(){
	// Setup
	// Pinos PC1, PC2, PC3 como entrada (Botões)
	DDRD &= ~((1 << DDD7) | (1 << DDD6) | (1 << DDD5) | (1 << DDD4) | (1 << DDD3) | (1 << DDD2));
	DDRB &= ~( (1 << DDB5) | (1 << DDB3) | (1 << DDB2) );

}

int main() {
	// Definindo o tamanho da matriz (8x8 como no seu projeto)

	setup_hardware();
	setup_adc();


	Snake cobra;

	byte matriz[8];

	lcd_init();

	max7219_init();
	max7219_clear();


	uint8_t count_minutes = 0;
	Iniciar_cobra(&cobra);
	
	
	while(1){
		
		controlar_direcao(&cobra);
		Mover_cobra(&cobra);

		lcd_exibir_coordenadas(cobra.x, cobra.y);
		exibirCobra(cobra.x, cobra.y, matriz);

		uint8_t time_frame = cobra.velocidade;
		_delay_ms(500);

		count_minutes++;
		if (count_minutes == 20 && cobra.tamanho<8){
			cobra.velocidade = cobra.velocidade - 50;
			aumentar_cobra(&cobra);
			count_minutes = 0;
		}

		verifica_limites(&cobra, &count_minutes);

	}

	return 0;
}