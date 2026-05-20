#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>

// Definição dos pinos
#define LOAD  PB2
#define DIN   PB3
#define CLK   PB5

typedef unsigned char byte;

// SPI enviar um byte por SPI
void spi_send(uint8_t data) {
	// Pega os dados a serem transmitidos e coloca no reg dados SPI
	SPDR = data;
	// AND do reg status com SPIF para ver conclusão
	while (!(SPSR & (1 << SPIF)));
	//SPSR, registrador status SPI ->SPIF transmissao concluida
}

// Enviar dado para MAX7219
void max7219_send(uint8_t address, uint8_t data) {
	// pino do load em 0 para iniciar
	PORTB &= ~(1 << LOAD );
	// Escolhe o registrador que sera alterado
	spi_send(address);
	// coloca o dado no registrador  anterior
	spi_send(data);
	// determinar que o load foi concluido
	PORTB |= (1 << LOAD) ;
}

// Inicializar SPI e MAX7219
void max7219_init(void) {
	DDRB |= (1 << DIN) | (1 << CLK) | (1 << LOAD );
	// registrador de controle == codigo do prof
	SPCR = (1 << SPE) | (1 << MSTR) | (1 << SPR0);  // SPI habilitado, mestre, clk/16

	// Configuração padrão do MAX7219  == codigo do prof
	max7219_send(0x09, 0x00);  // Sem decodificação
	max7219_send(0x0A, 0x0F);  // Brilho máximo
	max7219_send(0x0B, 0x07);  // Todos os dígitos (linhas) ativos
	max7219_send(0x0C, 0x01);  // Normal operation
	max7219_send(0x0F, 0x00);  // Teste desligado
}

// Limpar a matriz
void max7219_clear(void) {
	for (uint8_t i = 1; i <= 8; i++) {
		max7219_send(i, 0x00);
	}
}




void exibirCobra( uint8_t x[], uint8_t y[], byte matriz[]){
	// Zera tudo
	for (int i =0; i<8 ;i++){
		matriz[i]= 0;
	}
	// seta de acordo com as pos de x e y
	for (int i =0; i<8;i++){
		// ou com mascara pos x
		matriz[y[i]-1] |= (1<< x[i]-1); // menos 1 para poder exibir a largura inteira
	}

	max7219_send(0x01, matriz[0]);
	max7219_send(0x02, matriz[1]);
	max7219_send(0x03, matriz[2]);
	max7219_send(0x04, matriz[3]);
	max7219_send(0x05, matriz[4]);
	max7219_send(0x06, matriz[5]);
	max7219_send(0x07, matriz[6]);
	max7219_send(0x08, matriz[7]);
}







