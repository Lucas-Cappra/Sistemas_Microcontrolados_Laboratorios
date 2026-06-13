% Frequência de Amostragem
F_s = 10000;
T_s = 1/F_s;

% Número de pontos da LUT
N = 256; 

% Fase de 0 a 2*pi
fase = linspace(0, 2*pi-0.001, N); 

% Cria a senoide centrada em 127.5, variando de 0 a 255
senoide = 127.5 + 127.5 * sin(fase);

senoide  = ceil(senoide);

% senoide = 5*senoide/max(senoide);


f_c = 100; % Frequência da portadora em Hz

inc_32 = uint32((f_c * 2^32) / F_s);


% Simulando o acumulador
acumulador = uint32(0);
limite_32 = uint32(2^32);


% Mensagem digital a ser modulada
msg = 'Ola';

msg_bin = dec2bin(msg, 8);
msg_bin

msg_t = msg_bin'; 
m_t = msg_t(:)';


M = length(m_t);

t = (0:M-1)*T_s;


F_b = 80;
T_b = 1/F_b;

P = F_s/F_b;

m_ASK = zeros(M*P, 1);
t_ask = (0: M*P-1)*T_s;

cont = 1;
% Modulação ASK
for i = 1:M*P
    
    if cont > P
        cont = 1;
    end
    
    % 1. O acumulador avança (simulando o estouro natural do uint32)
    acumulador = mod(acumulador + inc_32, limite_32);
    
    % Agora, como o acumulador sempre é < 2^32, o bitshift funcionará perfeitamente
    indice = bitshift(acumulador, -24) + 1;
    i
    cont
    m_ASK(i) = senoide(indice)*m_t(cont);
    if mod(i, 24) == 0
        cont = cont + 1;
    end
    
end

m_ASK = m_ASK/256;

% Plotar
figure;
plot(t_ask, m_ASK, 'LineWidth', 4); hold on;
% plot(t, m_t, 'LineWidth', 2, 'Color', 'black');
title(['Sinal Modulado AM - Freq: ' num2str(f_c) 'Hz']);
grid on;
