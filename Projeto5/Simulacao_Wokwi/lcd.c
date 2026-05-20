/*
 * LCD.c
 *
 */ 
#include <avr/io.h>
#include <util/delay.h>
#include "LCD.h"


// Função para enviar um nibble (4 bits) para o LCD
void lcd_send_nibble(uint8_t nibble) {
	// Define os pinos D4-D7 (bits 0-3 do nibble)
	if (nibble & 0x01) PORTD |= (1 << LCD_D4); else PORTD &= ~(1 << LCD_D4);
	if (nibble & 0x02) PORTD |= (1 << LCD_D5); else PORTD &= ~(1 << LCD_D5);
	if (nibble & 0x04) PORTD |= (1 << LCD_D6); else PORTD &= ~(1 << LCD_D6);
	if (nibble & 0x08) PORTD |= (1 << LCD_D7); else PORTD &= ~(1 << LCD_D7);
	
	// Pulso no EN
	EN_HIGH();
	_delay_us(1);
	EN_LOW();
	_delay_us(100);
}

// Função para enviar um comando ou dado (8 bits)
void lcd_send_byte(uint8_t byte, uint8_t is_data) {
	if (is_data) RS_HIGH(); else RS_LOW();
	
	// Envia os 4 bits mais significativos (MSB)
	lcd_send_nibble(byte >> 4);
	// Envia os 4 bits menos significativos (LSB)
	lcd_send_nibble(byte & 0x0F);
}

// Inicialização do LCD
void lcd_init() {
	// Configura os pinos como saída
	DDRD |= (1 << LCD_RS) | (1 << LCD_EN) | (1 << LCD_D4) | (1 << LCD_D5) | (1 << LCD_D6)| (1 << LCD_D7);
	
	
	// Sequência de inicialização (modo 4 bits)
	_delay_ms(50);
	lcd_send_nibble(0x03);
	_delay_ms(5);
	lcd_send_nibble(0x03);
	_delay_us(100);
	lcd_send_nibble(0x03);
	lcd_send_nibble(0x02); // Modo 4 bits
	
	// Configuração do LCD
	lcd_send_byte(0x28, 0); // Modo 4 bits, 2 linhas, fonte 5x8
	lcd_send_byte(0x0C, 0); // Display ligado, cursor off
	lcd_send_byte(0x06, 0); // Incrementa cursor, sem shift
	lcd_send_byte(0x01, 0); // Limpa display
	_delay_ms(2);
}

// Escreve uma string no LCD
void lcd_print(const char *str) {
	while (*str) {
		lcd_send_byte(*str++, 1);
	}
}

//------------------------------------------------------------------------------------
// Conversão de um número em seus dígitos ASCII (em ordem correta) + terminação '\0'
//-----------------------------------------------------------------------------------
void ident_num(unsigned int valor, unsigned char *disp, unsigned char tam_vetor) {
    unsigned char n;
    unsigned char i = 0;
    unsigned char digitos[5]; // Armazena dígitos temporários (valor máximo de 16 bits: 65535)

    // Extrai dígitos (ordem invertida)
    do {
        digitos[i] = (valor % 10) + '0'; // Converte para ASCII
        valor /= 10;
        i++;
    } while (valor != 0 && i < 5);

    // Preenche o vetor de saída com zeros à esquerda (ex: "005" para 5, tam_vetor=3)
    for (n = 0; n < tam_vetor - 1; n++) {
        if (n < tam_vetor - 1 - i) {
            disp[n] = '0'; // Zero à esquerda
        } else {
            disp[n] = digitos[tam_vetor - 2 - n]; // Dígitos na ordem correta
        }
    }
    disp[tam_vetor - 1] = '\0'; // Terminador de string
}

void lcd_exibir_coordenadas(uint8_t x[], uint8_t y[]) {

    // Vai para início da linha 1
    lcd_send_byte(0x80, 0);

    lcd_print("X:");

    for (uint8_t i = 0; i < 7; i++) {

        lcd_send_byte(' ', 1);
        lcd_send_byte(x[i] + '0', 1);
    }

    // Vai para linha 2
    lcd_send_byte(0xC0, 0);

    lcd_print("Y:");

    for (uint8_t i = 0; i < 7; i++) {

        lcd_send_byte(' ', 1);
        lcd_send_byte(y[i] + '0', 1);
    }
}