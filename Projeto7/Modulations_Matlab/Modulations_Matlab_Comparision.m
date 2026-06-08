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

% senoide = 5*senoide/max(senoide);


freq_desejada = 100; % Frequência da portadora em Hz

% O "incremento" é um valor que, somado N_lut vezes em 1 segundo, 
% deve completar (F_s) ciclos.
% Fórmula: Inc = (f_desejada * 2^32) / F_s
inc_32 = uint32((freq_desejada * 2^32) / F_s);

% Simulando o acumulador
M = 2000; % Vamos simular 1000 instantes de tempo
acumulador = uint32(0);
saida_seno = zeros(1, M);

limite_32 = uint32(2^32);

t = (0:M-1)*T_s;
% Mensagem a ser modulada AM
f_m = 5;
m_t = 1*sin(2*pi*5*t);
m_AM = zeros(M, 1);



for i = 1:M
    % 1. O acumulador avança (simulando o estouro natural do uint32)
    acumulador = mod(acumulador + inc_32, limite_32);
    
    % Agora, como o acumulador sempre é < 2^32, o bitshift funcionará perfeitamente
    indice = bitshift(acumulador, -24) + 1;
    
    m_AM(i) = senoide(indice)*m_t(i);
end

% Plotar
figure;
plot(t, m_AM, 'LineWidth', 2);
title(['Sinal Modulado AM - Freq: ' num2str(freq_desejada) 'Hz']);
grid on;


m_FM = zeros(M, 1);
k_f = 100;


for i = 1:M
    % 1. O acumulador avança (simulando o estouro natural do uint32)
    acumulador = mod(acumulador + inc_32 + k_f*sum(m_t(1:i)), limite_32);
    
    % Agora, como o acumulador sempre é < 2^32, o bitshift funcionará perfeitamente
    indice = bitshift(acumulador, -24) + 1;
    
    m_FM(i) = senoide(indice);
end

% Plotar
figure;
plot(t, m_FM, 'LineWidth', 2);
title('Sinal Modulado FM ');
grid on;
