clear; clc; close all;

% Parâmetros
Fs = 2000;          % Frequência de amostragem (10 kHz)
t_fim = 5;              % Tamanho da janela temporal
T_s = 1/Fs;
% Tempo de -50 ms a 50 ms
% t = 0:Ts:t_fim;

% Mensagens
f_1 = 1;

% w = sin(2*pi * f_1 * t);

tempo_decorrido = 0;

t = [tempo_decorrido];
w = [sin(2*pi * f_1 * tempo_decorrido)];

% Plot dos Gráficos no Tempo

% Plot do espectro de magnitude
figure('Name', 'Osciloscópio em Tempo Real', 'NumberTitle', 'off');
hPlot = plot(NaN, NaN, 'b', 'LineWidth', 3.5); % Cria um plot vazio estável
title('Sinal Sendo Amostrado em Tempo Real');
xlabel('Tempo (s)');
ylabel('Amplitude (V)');
grid on;
xlim([0 5]);            % Mostra uma janela deslizante de 5 segundos na tela
ylim([-1.1 1.1]);       % Limites de amplitude do sinal composto




while tempo_decorrido < t_fim
        
    tempo_decorrido = tempo_decorrido + T_s;
    t(end+1) = tempo_decorrido;
    w(end+1) = sin(2 * pi * f_1 * tempo_decorrido);
    set(hPlot, 'XData', t, 'YData', w);
    title('Sinal Senoidal');
    xlabel('t (s)');
    % if tempo_decorrido > 0.5
    %         xlim([tempo_decorrido - 0.5, tempo_decorrido]);
    % end
    drawnow;
    grid on;

end

