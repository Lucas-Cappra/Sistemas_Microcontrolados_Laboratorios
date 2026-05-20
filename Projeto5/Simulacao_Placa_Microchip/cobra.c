#include <stdlib.h>
#include <util/delay.h>


typedef enum {
	UP,
	DOWN,
	LEFT,
	RIGHT
} Direcao;


typedef struct {
	uint8_t x[8]; // Máximo de pontos na matriz
	uint8_t y[8];
	uint8_t tamanho;
	Direcao direcao; // Up, Down, Left, Right
	uint16_t velocidade;
} Snake;



void Iniciar_cobra(Snake *s) {
	s->tamanho = 1;
	s->x[0] = 4; // Centro da matriz 8x8
	s->y[0] = 4;
	s->direcao = DOWN; // Supondo 0 como DIREITA
	s->velocidade = 500;

	// Preenche o resto do corpo com valores impossíveis
	for(int i = 1; i < 8; i++) {
		s->x[i] = 0;
		s->y[i] = 0;
	}
	
}



void Mover_cobra(Snake *s) {


	for (uint8_t j = s->tamanho - 1; j > 0; j--) {
		s->x[j] = s->x[j-1];
		s->y[j] = s->y[j-1];
	}

	if (s->direcao == RIGHT) s->y[0]++;
	if (s->direcao == LEFT) s->y[0]--;
	if (s->direcao == UP) s->x[0]--;
	if (s->direcao == DOWN) s->x[0]++;
}


void controlar_direcao(Snake *s) {

	uint16_t V_A4 = ler_adc(4);
	uint16_t V_A5 = ler_adc(5);
	

	if ( (V_A4 > 300 & V_A4 < 700) & (V_A5<300)) s->direcao =  RIGHT;
	if ((V_A5 > 300 & V_A5 < 700) & (V_A4<300)) s->direcao =  DOWN;

	if ((V_A5 > 300 & V_A5 < 700) & (V_A4>800)) s->direcao =  UP;
	if ((V_A4 > 300 & V_A4 < 700) & (V_A5>800)) s->direcao =  LEFT;



}


void aumentar_cobra(Snake *s) {
	if (s->tamanho < 8){

		s->tamanho++;
		if (s->direcao == RIGHT) s->y[s->tamanho-1] = s->y[s->tamanho-2]; s->x[s->tamanho-1] = s->x[s->tamanho-2]-1;
		if (s->direcao == LEFT)  s->y[s->tamanho-1] = s->y[s->tamanho-2]; s->x[s->tamanho-1] = s->x[s->tamanho-2]+1;
		if (s->direcao == UP)  s->y[s->tamanho-1] = s->y[s->tamanho-2]+1; s->x[s->tamanho-1] = s->x[s->tamanho-2];
		if (s->direcao == DOWN)  s->y[s->tamanho-1] = s->y[s->tamanho-2]-1; s->x[s->tamanho-1] = s->x[s->tamanho-2];

	}
}



void verifica_limites(Snake *s, uint8_t *count_minutes){

	uint8_t saiu = s->x[0]<0 || s->x[0]>7 || s->y[0]<0 || s->y[0]>7;
	uint8_t sobreposicao = 0;

	for (uint8_t l = 1; l<=s->tamanho; l++){
		if (s->x[l] == s->x[0] && s->y[l] == s->y[0]){
			sobreposicao = 1;
			break;
		}
	}

	if (saiu || sobreposicao)  {
		animacao_game_over();

		Iniciar_cobra(s);

		// 3. Reseta as variáveis de controle de tempo/minutos
		count_minutes = 0;
	}
	sobreposicao = 0;
}


