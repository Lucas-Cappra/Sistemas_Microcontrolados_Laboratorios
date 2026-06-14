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


% Mensagem digital a ser modulada
msg = 'Ola';

msg_bin = dec2bin(msg, 8) - '0';

msg_t = msg_bin'; 
m_t = msg_t(:)';


M = length(m_t);

t = (0:M-1)*T_s;

%%
F_b = 80;
T_b = 1/F_b;

P = F_s/F_b;

m_ASK = zeros(M*P, 1);
t_ask = (0: M*P-1)*T_s;

m = zeros(M*P, 1);

cont = 1;
% Modulação ASK

inc_32 = uint32((f_c * 2^32) / F_s);


% Simulando o acumulador
acumulador = uint32(0);
limite_32 = uint32(2^32);



for i = 1:M*P
    
    acumulador = mod(acumulador + inc_32, limite_32);
    
    indice = bitshift(acumulador, -24) + 1;

    
    m_ASK(i) = senoide(indice)*m_t(cont);
    m(i) = m_t(cont);
    
    if mod(i, P) == 0
        cont = cont + 1;
        acumulador = 0;
    end
    
end

m_ASK = m_ASK/256;

% Plotar
figure;
plot(t_ask, m_ASK, 'LineWidth', 3, 'color', 'm'); hold on;
plot(t_ask, m, 'LineWidth', 2, 'Color', 'black');
title(['Modulação ASK com T_b = ' num2str(T_b*1000) ' ms'])
legend('Sinal ASK', 'Sinal Digital');
grid on;







%% FSK

% Modulação FSK

% Frequencia da Portadora 1
f_c_1 = 80;
f_c_2 = 240;


m_FSK = zeros(M*P, 1);

% Simulando o acumulador
acumulador = uint32(0);
limite_32 = uint32(2^32);

inc_1 = uint32((f_c_1 * 2^32) / F_s);
inc_2 = uint32((f_c_2 * 2^32) / F_s);

inc_32 = mux(inc_1, inc_2, m_t(1));

cont = 1;

for i = 1:M*P
    
   
    inc_32 = mux(inc_2, inc_1, m_t(cont));
    
    acumulador = mod(acumulador + inc_32, limite_32);
    
    indice = bitshift(acumulador, -24) + 1;
    
    m_FSK(i) = senoide(indice);
    
    if mod(i, P) == 0
        cont = cont + 1;
        acumulador = 0;
    end
    
    
end

m_FSK = m_FSK/256;

% Plotar
figure;
plot(t_ask, m_FSK, 'LineWidth', 3, 'color', 'cyan'); hold on;
plot(t_ask, m, 'LineWidth', 2, 'Color', 'black');
title(['Modulação FSK com T_b = ' num2str(T_b*1000) ' ms'])
legend('Sinal FSK', 'Sinal Digital');
grid on;


function Y = mux(A, B, sel)
    if sel == 1
        Y = A;
    else
        Y = B;
    end
end
