

#ifndef LCD_H
#define LCD_H

#include <avr/io.h>
#include <util/delay.h>

// Pinos do LCD
#define LCD_RS     PD2
#define LCD_EN     PD3
#define LCD_D4     PD4
#define LCD_D5     PD5
#define LCD_D6     PD6
#define LCD_D7     PD7

// Macros de controle
#define RS_HIGH()  PORTD |= (1 << LCD_RS)
#define RS_LOW()   PORTD &= ~(1 << LCD_RS)
#define EN_HIGH()  PORTD |= (1 << LCD_EN)
#define EN_LOW()   PORTD &= ~(1 << LCD_EN)

// Funções públicas
void lcd_send_nibble(uint8_t nibble);
void lcd_send_byte(uint8_t byte, uint8_t is_data) ;
void lcd_init();
void lcd_print(const char *str) ;
void ident_num(unsigned int valor, unsigned char *disp, unsigned char tam_vetor);

#endif

