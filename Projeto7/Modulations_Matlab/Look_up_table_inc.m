% Frequência de Amostragem
F_s = 10000;
T_s = 1/F_s;

% Número de pontos da LUT
N = 256; 

% Fase de 0 a 2*pi
fase = linspace(0, 2*pi-0.001, N); 

% Cria a senoide centrada em 127.5, variando de 0 a 255
senoide = 127.5 + 127.5 * sin(fase);

senoide  = round(senoide);

% Conversão D/A pra saída
senoide = 5*senoide/max(senoide);


freq_desejada = 10; % Frequência da portadora em Hz

% deve completar (F_s) ciclos.
% Fórmula: Inc = (f_desejada * 2^32) / F_s
inc_32 = uint32((freq_desejada * 2^32) / F_s);

num_amostras = 1000; %
acumulador = uint32(0);
saida_seno = zeros(1, num_amostras);

for i = 1:num_amostras
    % 1. O acumulador avança (simulando o estouro natural do uint32)
    acumulador = acumulador + inc_32; 
    
    % 2. 8 bits mais significativos 
    indice = bitshift(acumulador, -24) + 1; 
    
    % 3. Consulta a LUT
    saida_seno(i) = senoide(indice);
end

% Plotagem dos gra´ficos
figure;
plot(saida_seno, 'LineWidth', 2);
title(['Sinal Gerado - Freq: ' num2str(freq_desejada) 'Hz']);
grid on;
