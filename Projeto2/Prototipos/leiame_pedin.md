Sobre o codigo do arquivo conversor_adc_bcd.asm

## 🔧 Funções

- `init_adc`: Inicializa o ADC (referência AVcc e prescaler).
- `read_adc`: Realiza a leitura do potenciômetro (0–1023).
- `map_adc`: Converte o valor do ADC para a faixa 0–999.
- `convert_BCD`: Converte o valor para centenas, dezenas e unidades.
- `exibir_pov`: Controla a exibição nos displays (multiplexação).
- `invert_bit`: Ajusta os bits para o padrão do hardware.
- `delay_mili`: Gera atraso para temporização.
