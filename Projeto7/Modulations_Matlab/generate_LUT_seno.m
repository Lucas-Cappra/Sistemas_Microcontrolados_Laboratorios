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

t = (0:N-1)*T_s;
% Agora você tem exatamente 256 valores de 0 a 255
figure()
plot(t, senoide,'color', 'red','linewidth',4 );
xlabel('t(s)');
ylabel('Amplitude');
grid on


fprintf('const uint8_t senoide_lut[256] PROGMEM = {\n');
for i = 1:N
    % Imprime o número
    fprintf('%d', senoide(i));
    
    % Imprime vírgula se não for o último elemento
    if i < N
        fprintf(', ');
    end
    
    % Quebra linha a cada 16 elementos para ficar organizado no código .c
    if mod(i, 16) == 0
        fprintf('\n');
    end
end
fprintf('\n};\n');