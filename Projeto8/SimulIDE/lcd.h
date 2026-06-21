#ifndef LCD_H_
#define LCD_H_

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <stdint.h>

// ======================================================
// DEFINIÇÃO DAS PORTAS
// ======================================================

#define LCD_PORT PORTD
#define LCD_DDR  DDRD

// ======================================================
// PINOS DO LCD
// ======================================================

#define LCD_RS   PD2
#define LCD_EN   PD3

#define LCD_D4   PD4
#define LCD_D5   PD5
#define LCD_D6   PD6
#define LCD_D7   PD7

// ======================================================
// MACROS DE CONTROLE
// ======================================================

#define RS_CMD()   (LCD_PORT &= ~(1 << LCD_RS))
#define RS_DATA()  (LCD_PORT |=  (1 << LCD_RS))

#define EN_HIGH()  (LCD_PORT |=  (1 << LCD_EN))
#define EN_LOW()   (LCD_PORT &= ~(1 << LCD_EN))

// ======================================================
// FUNÇÕES LCD
// ======================================================

void lcd_init(void);

void lcd_cmd(uint8_t c);
void lcd_data(uint8_t c);

void lcd_str(const char *s);

void lcd_xy(uint8_t x, uint8_t y);
void lcd_clear(void);

#endif /* LCD_H_ */