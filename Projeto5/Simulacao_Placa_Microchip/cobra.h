#ifndef COBRA_H
#define COBRA_H

#include <avr/io.h>


extern uint8_t linhas;
extern uint8_t colunas;


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


void Iniciar_cobra(Snake *s);

void Mover_cobra(Snake *s);

void aumentar_cobra(Snake *s);

void controlar_direcao(Snake *s);

void verifica_limites(Snake *s, uint8_t *count_minutes);


#endif