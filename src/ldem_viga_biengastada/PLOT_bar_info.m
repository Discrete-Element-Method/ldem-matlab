clear all
close all
clc

[Time,strain,ss,er,force,ep]=textread('Lei_Barra.txt','%f %f %f %f %f %f');
[Time2,Elas, Diss]=textread('Energia_Barra.txt','%f %f %f');

figure(1)
plot(Time2,Elas,' r.-', Time2,Diss,' b.-')
title(' ','FontName','Times New Roman Negrito','FontSize',18)
xlabel('Time [s]','FontName','Times New Roman','FontSize',18,'Rotation',0)
ylabel('Energy [Nm]','FontName','Times New Roman','FontSize',18,'Rotation',90)
legend(' Energy')
grid on



figure(2)
plot(Time,strain,' r.-' )
title(' ','FontName','Times New Roman Negrito','FontSize',18)
xlabel('Time [s]','FontName','Times New Roman','FontSize',18,'Rotation',0)
ylabel('strain','FontName','Times New Roman','FontSize',18,'Rotation',90)
legend('')
grid on

figure(3)
plot(Time,force,' r.-')
title(' ','FontName','Times New Roman Negrito','FontSize',18)
xlabel('Time [s]','FontName','Times New Roman','FontSize',18,'Rotation',0)
ylabel('force [N]','FontName','Times New Roman','FontSize',18,'Rotation',90)
legend('')
grid on

figure(4)
plot(strain,force,' r.-')
title(' ','FontName','Times New Roman Negrito','FontSize',18)
xlabel('strain','FontName','Times New Roman','FontSize',18,'Rotation',0)
ylabel('Force[N]','FontName','Times New Roman','FontSize',18,'Rotation',90)
legend('')
grid on

% =========================================================================
% CÓDIGO PARA A TRANSFORMADA DE FOURIER (FFT) DA ENERGIA ELÁSTICA
% Cole no final do seu script PLOT_bar_info.m
% =========================================================================

% 1. Definir o sinal 
% (Verifique se no seu código o tempo se chama 'Time' ou 'Time2' 
% e a energia elástica se chama 'Elas')
t_fft = Time2; 
sinal_fft = Elas; 

% Remove a média da energia (o patamar onde ela estabiliza). 
% Isso é essencial para não gerar um pico gigante e inútil em 0 Hz.
sinal_sem_media = sinal_fft - mean(sinal_fft);

% 2. Parâmetros da Amostragem
dt = t_fft(2) - t_fft(1);        % Passo de tempo de gravação do arquivo
Fs = 1 / dt;                     % Frequência de amostragem
L = length(sinal_sem_media);     % Tamanho da amostra

% 3. Cálculo da Transformada de Fourier
Y = fft(sinal_sem_media);

% 4. Construção do Espectro Unilateral (apenas frequências positivas)
P2 = abs(Y / L);                 % Magnitude do espectro bilateral
P1 = P2(1:floor(L/2)+1);         % Corta a parte negativa
P1(2:end-1) = 2 * P1(2:end-1);   % Dobra a amplitude da parte positiva compensando o corte

% Eixo das frequências
f = Fs * (0:floor(L/2)) / L; 

% 5. Plotagem do Espectro
figure(5) 
plot(f, P1, 'm', 'LineWidth', 1.5);
title('Transformada de Fourier (FFT) da Energia Elástica', 'FontWeight', 'bold', 'FontSize', 14);
xlabel('Frequência [Hz]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
grid on;

% Dá um zoom inicial nas frequências mais baixas (ajuste esse valor se precisar ver mais longe)
xlim([0 15000]);