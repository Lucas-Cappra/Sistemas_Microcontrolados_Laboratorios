% Parâmetros
Fs = 2000;          % Frequência de amostragem (10 kHz)
t_fim = 2;              % Tamanho da janela temporal
Ts = 1/Fs;
% Tempo de -50 ms a 50 ms
t = 0:Ts:t_fim;

% Mensagens
f_1 = 10;
f_2 = 500;

w = sin(2*pi * f_1 * t);

n = sin(2*pi * f_2 * t);

x = w + n;

%Filtro passa-faixa

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


N = 1024;
f = (-N/2:N/2-1) * (Fs / N); % Frequências
H_f = abs(fftshift(fft(h, N)));

Fontesize = 15;

% Plot do espectro de magnitude
figure;
subplot(2, 1, 1);
plot(f, 20*log10(abs(H_f)), 'color', 'blue','linewidth',3);
title('Espectro de Magnitude do Filtro Projetado');
xlabel('f (Hz)');
ylabel('|H(f)|');
ax = gca;
ax.FontSize = Fontesize;
grid on;

subplot(2, 1, 2);
plot(f, (angle(H_f)), 'color', 'm','linewidth',3);
title('Espectro de Fase do Filtro Projetado');
xlabel('f (Hz)');
ylabel('\phi(H(f))');
ax = gca;
ax.FontSize = Fontesize;
grid on;
%%

%Sinal final modulado sem multiplicador
y = filter(h,1,x);



% Plot dos Gráficos no Tempo

% Plot do espectro de magnitude
figure;
subplot(2, 1, 1);
plot(t, x, 'red');
title('Sinal com Ruído Senoidal');
xlabel('t (s)');
% ylabel('|W(f)|');
grid on;

subplot(2,1,2);
plot(t, y, 'color', 'green', 'linewidth', 4); hold on
plot(t, w, 'color', 'black', 'linewidth', 2);
legend('Sinal Filtrado', 'Sinal Original');
title('Sinal Filtrado');
xlabel('t (s)');
% ylabel('|X(f)|');
grid on;


% Transformada de Fourier
N = length(t);
f = (-N/2:N/2-1) * (Fs / N); % Frequências
spectrum_w = abs(fftshift(fft(x)));
spectrum_y = abs(fftshift(fft(y))); % Espectro de magnitude

% Plot do espectro de magnitude
figure;
subplot(2, 1, 1);
plot(f, spectrum_w,'red');
title('Espectro de Magnitude do Sinal com Ruído');
xlabel('Frequência (Hz)');
ylabel('|W(f)|');
grid on;

subplot(2,1,2);
plot(f, spectrum_y,'k');
title('Espectro de Magnitude do Sinal Filtrado');
xlabel('Frequência (Hz)');
ylabel('|X(f)|');
grid on;

%%

for i = 1:16  
    disp(h(i));
end
