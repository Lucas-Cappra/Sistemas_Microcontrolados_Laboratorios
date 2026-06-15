#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include "lcd.h"
#include "lcd.c"

#define BTN_A   PC1
#define BTN_INC PC2
#define BTN_DEC PC3


const uint8_t senoide[256] = {128, 131, 134, 137, 140, 143, 146, 149, 152, 156, 159, 162, 165, 168, 171, 174,
176, 179, 182, 185, 188, 191, 193, 196, 199, 201, 204, 206, 209, 211, 213, 216,
218, 220, 222, 224, 226, 228, 230, 232, 234, 235, 237, 239, 240, 242, 243, 244,
246, 247, 248, 249, 250, 251, 251, 252, 253, 253, 254, 254, 254, 255, 255, 255,
255, 255, 255, 255, 254, 254, 253, 253, 252, 252, 251, 250, 249, 248, 247, 246,
245, 244, 242, 241, 239, 238, 236, 235, 233, 231, 229, 227, 225, 223, 221, 219,
217, 215, 212, 210, 207, 205, 202, 200, 197, 195, 192, 189, 186, 184, 181, 178,
175, 172, 169, 166, 163, 160, 157, 154, 151, 148, 145, 142, 139, 135, 132, 129,
126, 123, 120, 117, 113, 110, 107, 104, 101, 98, 95, 92, 89, 86, 83, 80,
77, 74, 71, 69, 66, 63, 60, 58, 55, 53, 50, 48, 45, 43, 41, 38,
36, 34, 32, 30, 28, 26, 24, 22, 20, 19, 17, 16, 14, 13, 11, 10,
9, 8, 7, 6, 5, 4, 3, 3, 2, 2, 1, 1, 0, 0, 0, 0,
0, 0, 0, 1, 1, 1, 2, 2, 3, 4, 4, 5, 6, 7, 8, 9,
11, 12, 13, 15, 16, 18, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37,
39, 42, 44, 46, 49, 51, 54, 56, 59, 62, 64, 67, 70, 73, 76, 78,
81, 84, 87, 90, 93, 96, 99, 102, 105, 109, 112, 115, 118, 121, 124, 127};


typedef struct {
    uint32_t ponteiro_fase;
    uint32_t f_c;
    uint32_t inc;
} Modulador_AM;

typedef struct {
    uint32_t ponteiro_fase;
    uint32_t f_c;
    uint32_t inc;
    uint32_t k_f;
} Modulador_FM;

typedef struct {
    uint32_t ponteiro_fase;
    uint64_t f_c;
    uint8_t  contador;
    uint32_t inc;
    uint32_t F_b;
} Modulador_ASK;

typedef struct {
    uint32_t ponteiro_fase;
    uint64_t f_c;
    uint32_t contador;
    uint32_t inc;
    uint32_t F_b;
} Modulador_FSK;

typedef enum { MOD_AM, MOD_FM, MOD_ASK, MOD_FSK } ModType;
typedef enum { MENU_NORMAL, AJUSTE_MOD, AJUSTE_FREQ } MenuState;


volatile Modulador_AM  am_mod;
volatile Modulador_FM  fm_mod;
volatile Modulador_ASK ask_mod;
volatile Modulador_FSK fsk_mod;

volatile ModType   mod_atual     = MOD_AM;
volatile MenuState estado_menu   = MENU_NORMAL;
volatile uint16_t  freq_portadora = 100;
volatile uint8_t   flag_btn_a    = 0;
volatile uint8_t   flag_btn_inc  = 0;
volatile uint8_t   flag_btn_dec  = 0;


void AM_Setup(volatile Modulador_AM *mod, uint32_t f_c, uint32_t F_s) {
    mod->f_c           = f_c;
    mod->ponteiro_fase = 0;
    mod->inc           = (uint32_t)(((uint64_t)f_c << 32) / F_s);
}

void FM_Setup(volatile Modulador_FM *mod, uint32_t f_c, uint32_t k_f) {
    mod->f_c           = f_c;
    mod->k_f           = k_f;
    mod->ponteiro_fase = 0;
    mod->inc           = 0;
}

void ASK_Setup(volatile Modulador_ASK *mod, uint64_t f_c, uint32_t F_b) {
    mod->f_c           = f_c;
    mod->F_b           = F_b;
    mod->ponteiro_fase = 0;
    mod->contador      = 0;
    mod->inc           = 0;
}

void FSK_Setup(volatile Modulador_FSK *mod, uint64_t f_c, uint32_t F_b) {
    mod->f_c           = f_c;
    mod->F_b           = F_b;
    mod->ponteiro_fase = 0;
    mod->contador      = 0;
    mod->inc           = 0;
}

void aplicar_freq(uint32_t F_s) {
    AM_Setup  (&am_mod,  freq_portadora,      F_s);
    FM_Setup  (&fm_mod,  freq_portadora, 90);
    ASK_Setup (&ask_mod, freq_portadora, 80);
    FSK_Setup (&fsk_mod, freq_portadora, 100);
}


uint8_t AM_Modulation(volatile Modulador_AM *mod, uint8_t m_k, const uint32_t F_s) {
    mod->ponteiro_fase += mod->inc;
    uint8_t indice = (uint8_t)(mod->ponteiro_fase >> 24);

    int16_t m_centered = (int16_t)m_k - 128;          // -128 a +127 (sinal centrado)
    int16_t portadora  = (int16_t)senoide[indice] - 128; // -128 a +127 (portadora centrada)

    int16_t y = ((m_centered * portadora) >> 8) + 128; // produto + offset DC

    return (uint8_t)y;
}

uint8_t FM_Modulation(volatile Modulador_FM *mod, uint8_t m_k, const uint32_t F_s) {
    mod->inc = (uint32_t)(((mod->f_c + m_k * mod->k_f/100) << 24) / F_s);
    mod->ponteiro_fase += mod->inc;
    uint8_t indice = (uint8_t)(mod->ponteiro_fase >> 16);
    return (uint8_t)senoide[indice];
}

uint8_t ASK_Modulation(volatile Modulador_ASK *mod, uint8_t m_k, const uint32_t F_s, uint16_t i) {
    uint32_t M = F_s / mod->F_b;
    mod->inc = (uint32_t)((mod->f_c << 32) / F_s);
    if (i % M == 0) {
        mod->contador++;
        mod->ponteiro_fase = 0;
    }
    mod->ponteiro_fase += mod->inc;
    uint8_t indice = (uint8_t)(mod->ponteiro_fase >> 24);
    return (uint8_t)(((uint16_t)m_k * senoide[indice]) >> 8);
}

uint8_t FSK_Modulation(volatile Modulador_FSK *mod, uint8_t m_k, const uint32_t F_s, uint16_t i) {
    uint32_t M = F_s / mod->F_b;
    if (i % M == 0) {
        if (m_k == 0) {
            mod->inc = (uint32_t)((uint64_t)(mod->f_c << 32) / F_s);
        } else {
            mod->inc = (uint32_t)((uint64_t)(mod->f_c*6 << 32) / F_s);
        }
        mod->contador++;
        mod->ponteiro_fase = 0;
    }
    mod->ponteiro_fase += mod->inc;
    uint8_t indice = (uint8_t)(mod->ponteiro_fase >> 24);
    return (uint8_t)senoide[indice];
}


void setup_adc(void) {
    ADMUX  = (1 << REFS0) | (1 << ADLAR);
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint8_t ler_adc(uint8_t pino) {
    ADMUX  = (ADMUX & 0xF0) | pino;
    ADCSRA |= (1 << ADSC);
    while (ADCSRA & (1 << ADSC)) {}
    return ADCH;
}

void setup_timer(void) {
	// Inicializa os Registradores de Timer
    TCCR1A = 0;
    TCCR1B = 0;
    TCNT1  = 0;
	
	// Valor de contagem do timer 1A para estourar em exatos 10kHz
    OCR1A  = 25;

	// Registradores de timer e prescaler
    TCCR1B |= (1 << WGM12);
    TCCR1B |= (0 << CS12) | (1 << CS11) | (1 << CS10);
    TIMSK1 |= (1 << OCIE1A);
}

void setup_dac(void) {
	// Seta os pinos do DAC
    DDRB |= 0b00111111;
    DDRC |= 0b00110000;
}

static inline void dac_write(uint8_t val) {
	// Escreve na saída do DAC
    PORTC = (val & 0x03) << 4;
    PORTB =  val >> 2;
}


void btn_init(void) {
	// Inicializa os botões com interrupções
    DDRC  &= ~((1 << BTN_A) | (1 << BTN_INC) | (1 << BTN_DEC));
    PORTC |=  ((1 << BTN_A) | (1 << BTN_INC) | (1 << BTN_DEC));

    // PCINT para PORTC: habilita PCIE1 e os pinos PC1, PC2, PC3
    PCICR  |= (1 << PCIE1);
    PCMSK1 |= (1 << BTN_A) | (1 << BTN_INC) | (1 << BTN_DEC);
}


volatile uint8_t flag_amostragem = 0;

ISR(TIMER1_COMPA_vect) {
    flag_amostragem = 1;
}

// PCINT1 dispara em qualquer borda (subida e descida)
// Filtra apenas a borda de descida (botão pressionado = nível baixo)
ISR(PCINT1_vect) {
    if (!(PINC & (1 << BTN_A)))   flag_btn_a   = 1;
    if (!(PINC & (1 << BTN_INC))) flag_btn_inc = 1;
    if (!(PINC & (1 << BTN_DEC))) flag_btn_dec = 1;
}


// Definição das Constantes Importantes do Projeto
const uint32_t F_s = 10000;
volatile uint8_t y_k = 0;
uint8_t  m_k = 0;

// Contador Global Circular
uint16_t i   = 0;


// Função de atualizar o display
void atualizar_display(void) {
    char linha1[17];
    char linha2[17];

    lcd_clear();

    const char *mod_nomes[] = {"AM ", "FM ", "ASK", "FSK"};
    const char *unidade = (mod_atual == MOD_AM || mod_atual == MOD_FM) ? "Hz" : "bs";
    uint16_t indicador = (mod_atual == MOD_AM || mod_atual == MOD_FM) ? freq_portadora : (freq_portadora / 10);
	
    char prefixo_mod  = (estado_menu == AJUSTE_MOD)  ? '>' : ' ';
    char prefixo_freq = (estado_menu == AJUSTE_FREQ) ? '>' : ' ';

    snprintf(linha1, sizeof(linha1), "Mod:%c%s T:%c%d%s",
             prefixo_mod, mod_nomes[mod_atual], prefixo_freq, indicador, unidade);
    lcd_xy(0, 0);
    lcd_str(linha1);

    if (mod_atual == MOD_AM || mod_atual == MOD_FM) {
        snprintf(linha2, sizeof(linha2), "Msg: %d", m_k);
    } else {
        uint8_t b = m_k;
        snprintf(linha2, sizeof(linha2), "Msg: %d%d.%d%d.%d%d.%d%d",
                 (b >> 7) & 1, (b >> 6) & 1, (b >> 5) & 1, (b >> 4) & 1,
                 (b >> 3) & 1, (b >> 2) & 1, (b >> 1) & 1,  b       & 1);
    }
    lcd_xy(0, 1);
    lcd_str(linha2);
}


// Função que verifica se os botões foram apertados de acordo com as flgas
void processar_botoes(void) {
    if (flag_btn_a) {
        flag_btn_a = 0;
        _delay_ms(20);
        if (!(PINC & (1 << BTN_A))) {
            if      (estado_menu == MENU_NORMAL) estado_menu = AJUSTE_MOD;
            else if (estado_menu == AJUSTE_MOD)  estado_menu = AJUSTE_FREQ;
            else                                 estado_menu = MENU_NORMAL;
            atualizar_display();
        }
    }

    if (flag_btn_inc) {
        flag_btn_inc = 0;
        _delay_ms(20);
        if (!(PINC & (1 << BTN_INC))) {
            if (estado_menu == AJUSTE_MOD) {
                mod_atual = (mod_atual + 1) % 4;
                aplicar_freq(F_s);
            } else if (estado_menu == AJUSTE_FREQ) {
                if (freq_portadora < 999) {
                    freq_portadora += 10;
                    aplicar_freq(F_s);
                }
            }
            atualizar_display();
        }
    }

    if (flag_btn_dec) {
        flag_btn_dec = 0;
        _delay_ms(20);
        if (!(PINC & (1 << BTN_DEC))) {
            if (estado_menu == AJUSTE_MOD) {
                mod_atual = (mod_atual == MOD_AM) ? MOD_FSK : (mod_atual - 1);
                aplicar_freq(F_s);
            } else if (estado_menu == AJUSTE_FREQ) {
                if (freq_portadora > 100) {
                    freq_portadora -= 10;
                    aplicar_freq(F_s);
                }
            }
            atualizar_display();
        }
    }
}


int main(void) {

    lcd_init();
    setup_adc();
    setup_dac();
    btn_init();
    setup_timer();

    aplicar_freq(F_s);
    atualizar_display();

    sei();

    while (1) {

        if (flag_amostragem == 1) {

            switch (mod_atual) {
                case MOD_AM:
                case MOD_FM:
                    m_k = ler_adc(0);
                    break;
                case MOD_ASK:
                    if (i % (F_s / ask_mod.F_b) == 0)
                        m_k = ler_adc(0);
                    break;
                case MOD_FSK:
                    if (i % (F_s / fsk_mod.F_b) == 0)
                        m_k = ler_adc(0);
                    break;
            }

            switch (mod_atual) {
                case MOD_AM:  y_k = AM_Modulation (&am_mod,  m_k, F_s);    break;
                case MOD_FM:  y_k = FM_Modulation (&fm_mod,  m_k, F_s);    break;
                case MOD_ASK: y_k = ASK_Modulation(&ask_mod, m_k, F_s, i); break;
                case MOD_FSK: y_k = FSK_Modulation(&fsk_mod, m_k, F_s, i); break;
            }

            dac_write(y_k);

            flag_amostragem = 0;
            i++;
        }

        processar_botoes();
    }
}
