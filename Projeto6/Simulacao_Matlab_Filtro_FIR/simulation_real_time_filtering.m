clear; clc; close all;
% Parâmetros
Fs = 2000;          % Frequência de amostragem (10 kHz)
t_fim = 30;              % Tamanho da janela temporal
T_s = 1/Fs;
% Tempo de -50 ms a 50 ms
% t = 0:Ts:t_fim;


% Mensagens
f_1 = 10;
f_2 = 500;
tempo_decorrido = 0;


t = [tempo_decorrido];

w1 = [sin(2*pi * f_1 * tempo_decorrido)];
w2 = [sin(2*pi * f_2 * tempo_decorrido)];


x = [sin(2*pi * f_1 * tempo_decorrido) + sin(2*pi * f_2 * tempo_decorrido)];


size(x)
% Filtragem

%Frequencias em Hz do projeto do filtro

Fn = Fs/2;

delta_f = 200;

fs = (f_2 - 10);
fp = (fs - delta_f);


%Normalização das frequências do projeto para a função firpm
fs_n = fs/Fn;
fp_n = fp/Fn;


f = [0 fp_n fs_n 1];
a = [1 1 0 0];

M = 16;
h = firpm (M, f, a);








% Plot dos Gráficos no Tempo
% Plot do espectro de magnitude
figure('Name', 'Osciloscópio em Tempo Real', 'NumberTitle', 'off');
subplot(2,1,1);
hPlot1 = plot(NaN, NaN, 'b', 'LineWidth', 3.5); 
title('Sinal Sendo Amostrado em Tempo Real');
xlabel('Tempo (s)');
ylabel('Amplitude (V)');
grid on;
% xlim([0 5]);            % Mostra uma janela deslizante de 5 segundos na tela
ylim([-1.1 1.1]);       % Limites de amplitude do sinal composto


subplot(2,1,2);
hPlot2 = plot(NaN, NaN, 'r', 'LineWidth', 2.0);
title('Sinal Sendo Amostrado em Tempo Real');
xlabel('Tempo (s)');
ylabel('Amplitude (V)');
grid on;
% xlim([0 5]);            % Mostra uma janela deslizante de 5 segundos na tela
ylim([-1.1 1.1]);       % Limites de amplitude do sinal composto



while tempo_decorrido < t_fim
        
    tempo_decorrido = tempo_decorrido + T_s;

    t(end+1) = tempo_decorrido;

    w1 = sin(2 * pi * f_1 * tempo_decorrido);
    w2 = sin(2 * pi * f_2 * tempo_decorrido);
    x(end+1) = w1 + w2;
    

    %Sinal final modulado sem multiplicador
    y = filter(h, 1, x);

    set(hPlot1, 'XData', t, 'YData', x);
    set(hPlot2, 'XData', t, 'YData', y);
    
    if tempo_decorrido > 0.2
             xlim([tempo_decorrido - 0.2, tempo_decorrido]);
    end

    title('Sinal Senoidal');

    xlabel('t (s)');


    drawnow;

    grid on;
end
