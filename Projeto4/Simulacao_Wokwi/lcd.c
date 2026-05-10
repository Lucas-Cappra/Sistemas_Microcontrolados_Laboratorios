#include "lcd.h"

// ================= parte de baixo nivel =================
static inline void lcd_nibble(uint8_t n){
    LCD_PORT = (LCD_PORT & 0x0F) | (n & 0xF0);
    EN_PULSE();
}

static void lcd_byte(uint8_t c, uint8_t rs){
    if(rs) RS_DATA(); else RS_CMD();
    lcd_nibble(c);
    lcd_nibble(c<<4);
}

void lcd_cmd(uint8_t c){
    lcd_byte(c,0);
    if(c < 4) _delay_ms(2);
}

void lcd_data(uint8_t c){
    lcd_byte(c,1);
}

void lcd_init(void){
    LCD_DDR |= 0b11111100;

    _delay_ms(45);

    RS_CMD();

    lcd_nibble(0x30); _delay_ms(5);
    lcd_nibble(0x30); _delay_us(150);
    lcd_nibble(0x30);
    lcd_nibble(0x20);

    lcd_cmd(0x28);
    lcd_cmd(0x0C);
    lcd_cmd(0x06);
    lcd_cmd(0x01);
}

void lcd_str(const char *s){
    while(*s) lcd_data(*s++);
}

void lcd_xy(uint8_t x, uint8_t y){
    lcd_cmd(0x80 | (y ? 0x40 : 0x00) | x);
}

// ================= alto nivel (tela) =================

// imprime 3 dígitos
void lcd_print_3d(uint8_t val)
{
    lcd_data((val/100) + '0');
    lcd_data(((val/10)%10) + '0');
    lcd_data((val%10) + '0');
}

// escreve R G B nas posições fixas
void lcd_set_values(uint8_t r, uint8_t g, uint8_t b)
{
    lcd_xy(1,1); lcd_print_3d(r);
    lcd_xy(5,1); lcd_print_3d(g);
    lcd_xy(9,1); lcd_print_3d(b);
}

// cursor com *
void lcd_update_cursor(uint8_t sel)
{
    // limpa
    lcd_xy(0,1); lcd_data(' ');
    lcd_xy(4,1); lcd_data(' ');
    lcd_xy(8,1); lcd_data(' ');

    // escreve *
    if(sel == 1){
       lcd_xy(0,1);
       lcd_data('*');
    }
    else if(sel == 2){ 
      lcd_xy(4,1);
      lcd_data('*');
    }
    else if(sel == 3){
      lcd_xy(8,1);
      lcd_data('*');
    }

}
