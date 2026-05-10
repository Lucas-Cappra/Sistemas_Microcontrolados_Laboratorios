#ifndef LCD_H
#define LCD_H

#include <avr/io.h>
#include <util/delay.h>

// ================= configurações =================

// dados → PD4 a PD7
#define LCD_PORT PORTD
#define LCD_DDR  DDRD

// controle
#define RS PD2
#define EN PD3

// macros de controle
#define RS_DATA() (PORTD |=  (1<<RS))
#define RS_CMD()  (PORTD &= ~(1<<RS))

#define EN_HIGH() (PORTD |=  (1<<EN))
#define EN_LOW()  (PORTD &= ~(1<<EN))

#define EN_PULSE()  \
EN_HIGH();      \
_delay_us(1);   \
EN_LOW();       \
_delay_us(50);

// ================= baixo nivel =================

void lcd_cmd(uint8_t c);
void lcd_data(uint8_t c);
void lcd_init(void);
void lcd_str(const char *s);
void lcd_xy(uint8_t x, uint8_t y);

// alto nível
void lcd_print_3d(uint8_t val);
void lcd_set_values(uint8_t r, uint8_t g, uint8_t b);
void lcd_update_cursor(uint8_t sel);

#endif