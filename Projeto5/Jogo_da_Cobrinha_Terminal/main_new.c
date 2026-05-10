#include <stdio.h>
#include <stdlib.h> 
#include <windows.h> 
#include <conio.h>
#include <ctype.h> // Para a função tolower()



typedef enum {
    UP,
    DOWN,
    LEFT,
    RIGHT
} Direcao;


typedef struct {
    int x[8]; // Máximo de pontos na matriz
    int y[8];
    int tamanho;
    Direcao direcao; // Up, Down, Left, Right
    float velocidade;
} Snake;


Snake cobra;


void Iniciar_cobra(Snake *s) {
    s->tamanho = 1;
    s->x[0] = 4; // Centro da matriz 8x8
    s->y[0] = 4;
    s->direcao = DOWN; // Supondo 0 como DIREITA
    s->velocidade = 0.5;
}



void Mover_cobra(Snake *s) {


    for (int j = s->tamanho - 1; j > 0; j--) {
    s->x[j] = s->x[j-1];
    s->y[j] = s->y[j-1];
    }

    if (s->direcao == RIGHT){
        s->y[0]++;
    }
    if (s->direcao == LEFT) s->y[0]--;
    if (s->direcao == UP) s->x[0]--;
    if (s->direcao == DOWN) s->x[0]++;
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



void controlar_direcao(Snake *s) {
    char ultima_tecla = 0;
    
    // Esvazia o buffer do teclado e pega só a última tecla
    while (kbhit()) {
        ultima_tecla = tolower(getch());
    }

    if (ultima_tecla != 0) {
        switch (ultima_tecla) {
            case 'w': if (s->direcao != DOWN) s->direcao = UP; break;
            case 's': if (s->direcao != UP) s->direcao = DOWN; break;
            case 'a': if (s->direcao != RIGHT) s->direcao = LEFT; break;
            case 'd': if (s->direcao != LEFT) s->direcao = RIGHT; break;
        }
    }
}


char linhas = 8;
char colunas = 8;

    // Matriz de dados (0 = vazio, 1 = parte da cobra)
    // Inicializei com alguns 1s para você ver o efeito
volatile char matriz[8][8] = {
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0}
};



char null_matrix[8][8] = {
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0}
};


void atualizar_matriz(volatile char matriz[8][8], Snake *s) {
    // 1. Zera tudo primeiro
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) matriz[i][j] = 0;
    }
    // 2. Acende apenas os pontos onde a cobra está
    for (int i = 0; i < s->tamanho; i++) {
    // Verifica se a posição está dentro dos limites antes de acender
        matriz[s->x[i]][s->y[i]] = 1;
    }   
}


void imprimir_matriz(volatile char matriz[8][8]){

    printf("--- Matriz de LEDs ---\n\n");

    printf("\n--------------------------------\n");
    
    for (int i = 0; i < linhas; i++) {
        for (int j = 0; j < colunas; j++) {
            if (matriz[i][j] == 1) {
                printf("x "); // LED Aceso
            } else {
                printf("- "); // LED Apagado (ponto ajuda a ver a grade)
            }
        }
        printf("\n"); // Pula para a próxima linha da matriz
    }

    printf("\n--------------------------------\n");
}



void animacao_game_over(volatile char matriz[8][8]){

    printf("--- Matriz de LEDs ---\n\n");

    printf("\n--------------------------------\n");
    for (int l = 0; l<8; l++){
        for (int i = 0; i < linhas; i++) {
            for (int j = 0; j < colunas; j++) {
                if (l == j) {
                    printf("o "); // LED Aceso
                } else {
                    printf("- "); // LED Apagado (ponto ajuda a ver a grade)
                }
            }
            printf("\n"); // Pula para a próxima linha da matriz
        }
        Sleep(30);

    printf("\n--------------------------------\n");
    imprimir_matriz(matriz);
}

}


char saiu_dos_limites(Snake *s){
    return 1;
    return 0;
}


void verifica_limites(Snake *s, int count_minutes){

    if (s->x[0]<0 || s->x[0]>7 || s->y[0]<0 || s->y[0]>7)  {
        animacao_game_over(matriz); 

        Iniciar_cobra(s);

            // 3. Reseta as variáveis de controle de tempo/minutos
        count_minutes = 0;
    }
}


int main() {
    // Definindo o tamanho da matriz (8x8 como no seu projeto)

    char count_minutes = 0;
    Iniciar_cobra(&cobra);
    
    
    while(1){
        system("cls"); // Limpa o terminal
        controlar_direcao(&cobra);
        Mover_cobra(&cobra);
        verifica_limites(&cobra, count_minutes);
        atualizar_matriz(matriz, &cobra);
        imprimir_matriz(matriz);
        Sleep(500);
        //aumentar_cobra(&cobra);
        count_minutes++;
        if (count_minutes == 3){
           aumentar_cobra(&cobra);
           count_minutes = 0;
        }



    }

    return 0;
}