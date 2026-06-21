#include "LCD.h"

// ======================================================
// BAIXO NÍVEL
// ======================================================

static void lcd_nibble(uint8_t nibble)
{
	if(nibble & 0x01)
	LCD_PORT |= (1 << LCD_D4);
	else
	LCD_PORT &= ~(1 << LCD_D4);

	if(nibble & 0x02)
	LCD_PORT |= (1 << LCD_D5);
	else
	LCD_PORT &= ~(1 << LCD_D5);

	if(nibble & 0x04)
	LCD_PORT |= (1 << LCD_D6);
	else
	LCD_PORT &= ~(1 << LCD_D6);

	if(nibble & 0x08)
	LCD_PORT |= (1 << LCD_D7);
	else
	LCD_PORT &= ~(1 << LCD_D7);

	EN_HIGH();
	_delay_us(1);
	EN_LOW();
	_delay_us(100);
}

static void lcd_byte(uint8_t byte, uint8_t is_data)
{
	if(is_data)
	RS_DATA();
	else
	RS_CMD();

	// Envia MSB
	lcd_nibble(byte >> 4);

	// Envia LSB
	lcd_nibble(byte & 0x0F);
}

// ======================================================
// FUNÇÕES PÚBLICAS
// ======================================================

void lcd_cmd(uint8_t cmd)
{
	lcd_byte(cmd, 0);

	if(cmd == 0x01 || cmd == 0x02)
	_delay_ms(2);
}

void lcd_data(uint8_t data)
{
	lcd_byte(data, 1);
}

void lcd_init(void)
{
	// Configura todos os pinos do LCD como saída
	LCD_DDR |=
	(1 << LCD_RS) |
	(1 << LCD_EN) |
	(1 << LCD_D4) |
	(1 << LCD_D5) |
	(1 << LCD_D6) |
	(1 << LCD_D7);

	_delay_ms(50);

	RS_CMD();

	// Sequência de inicialização HD44780
	lcd_nibble(0x03);
	_delay_ms(5);

	lcd_nibble(0x03);
	_delay_us(150);

	lcd_nibble(0x03);
	lcd_nibble(0x02);

	lcd_cmd(0x28);   // 4 bits, 2 linhas, fonte 5x8
	lcd_cmd(0x0C);   // display ON, cursor OFF
	lcd_cmd(0x06);   // cursor incrementa
	lcd_cmd(0x01);   // limpa display

	_delay_ms(2);
}

void lcd_str(const char *s)
{
	while(*s)
	{
		lcd_data(*s++);
	}
}

void lcd_xy(uint8_t x, uint8_t y)
{
	lcd_cmd(0x80 | (y ? 0x40 : 0x00) | x);
}

void lcd_clear(void)
{
	lcd_cmd(0x01);
}