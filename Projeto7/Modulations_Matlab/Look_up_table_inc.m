% Frequência de Amostragem
F_s = 10000;
T_s = 1/F_s;

% Número de pontos da LUT
N = 256; 

% Fase de 0 a 2*pi
fase = linspace(0, 2*pi-0.001, N); 

% Cria a senoide centrada em 127.5, variando de 0 a 255
senoide = 127.5 + 127.5 * sin(fase);

% Arredonda para valores inteiros
% senoide = uint8(senoide);
senoide  = round(senoide);

% Frequencia
f = 120;

% Conversão para amostras de fase
ponteiro_fase = round(f*N/F_s);

% senoide = 5*senoide/max(senoide);

senoide = senoide(1:ponteiro_fase:end);

N_new = length(senoide);
t = (0:N_new-1)*T_s;


% Agora você tem exatamente 256 valores de 0 a 255
figure()
plot(t, senoide,'color', 'red','linewidth',4 );
xlabel('t(s)');
ylabel('Amplitude');
grid on
