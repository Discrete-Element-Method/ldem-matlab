clear all
clc

% Configurações
    n_total = 5000;      % Número total de elementos
    velocidade1 = 10;       % Velocidade de transição entrada potencial(1-10)
    velocidade2 = 10;       % Velocidade de transição saida potencial (1-10)
    expoente = 1;       % Expoente da lei de potência
     
    dados =gerar_transicao_dupla2(n_total, velocidade1, velocidade2, expoente);
    %dados = gerar_transicao_uniforme_potencial(n_total, velocidade, expoente);
    %unif = rand(n_total /2,1); 
    %dados=[dados';unif]'; n_total=size(dados,2);
    % Criar janela com subplots para visualização
    figure('Position', [100, 100, 1200, 800]);
    
    % Subplot 1: Histograma completo
    %subplot(2, 3, [1, 4]);
    subplot(2,1,1);
    histogram(dados, 100, 'Normalization', 'pdf', 'FaceColor', [0.3, 0.6, 0.9]);
    xlabel('Value');
    ylabel('Density');
    title(sprintf('Uniform + Power law distribution + Uniform  (N =%d)', n_total));
    grid on;
    
    % Subplot 4: Evolução temporal dos valores
    %subplot(2, 3, [5, 6]);
    subplot(2,1,2);
    plot(1:n_total, dados', '.', 'MarkerSize', 2);
    xlabel('N');
    ylabel('Value');
    title('Evolução Temporal dos Valores');
    grid on;
    
    % Adicionar linha de tendência móvel
    window_size = 500;
    media_movel = movmean(dados', window_size);
    hold on;
    plot(1:n_total, media_movel, 'r-', 'LineWidth', 2);
    legend('Data', sprintf('Moving average (W=%d)', window_size), 'Location', 'best');
    hold off;
    
    % Estatísticas descritivas
    fprintf('\n--- Estatísticas ---\n');
    fprintf('Média: %.4f\n', mean(dados));
    fprintf('Mediana: %.4f\n', median(dados));
    fprintf('Desvio padrão: %.4f\n', std(dados));
    fprintf('Mínimo: %.4f\n', min(dados));
    fprintf('Máximo: %.4f\n', max(dados));
    
    % Análise da transição
    % fprintf('\n--- Análise da Transição ---\n');
    
    % % Dividir em 5 segmentos
    % segmentos = 5;
    % for k = 1:segmentos
    %     idx_inicio = round((k-1)*n_total/segmentos) + 1;
    %     idx_fim = round(k*n_total/segmentos);
    %     segmento = dados(idx_inicio:idx_fim);
    % 
    %     % Calcular média e mediana
    %     fprintf('Segmento %d (%.0f%%-%.0f%%): Média=%.4f, Mediana=%.4f, Coef.Variação=%.4f\n', ...
    %         k, (k-1)*100/segmentos, k*100/segmentos, ...
    %         mean(segmento), median(segmento), std(segmento)/mean(segmento));
    % end
%end
%%%%%%%%%%%%%%%% NATURAL TIME
Q=dados';
% 1. Configuração Inicial e Medida de Energia
% O artigo sugere que a medida adequada é Qk = A^1.5, onde A é a amplitude [4, 5].
%Q = Amp.^1.5; 
Lin = length(Q);

% Definição de PI_c (ruído uniforme) - calculada uma única vez
fi = 0:0.025:0.5;
ww = 2 * pi * fi;
pi_c = 18./(5*ww.^2) - 6*cos(ww)./(5*ww.^2) - 12*sin(ww)./(5*ww.^3);
pi_c(1) = 1; % Limite quando w -> 0

% Pré-alocação de variáveis para velocidade
kapa1 = zeros(Lin, 1);
Snt = zeros(Lin, 1);
Srev = zeros(Lin, 1);
D = zeros(Lin, 1);

% Loop principal (Evolução dos eventos)
% Nota: Calculamos os parâmetros para cada janela de tamanho k
for k = 1:Lin
    % 1. Recorte e Normalização da janela atual
    Q_k = Q(1:k);
    An = sum(Q_k);
    pk = Q_k / An; % Energias normalizadas P_k [4]
    
    % 2. Vetor de Tempo Natural chi_k [4]
    xk = (1:k)' / k; 
    
    % 3. Cálculo Vetorizado de Kappa1 (Variância)
    k1 = sum(pk .* (xk.^2));
    k2 = sum(pk .* xk);
    kapa1(k) = k1 - k2^2;
    
    % 4. Cálculo Vetorizado das Entropias (S e S_inv) [1, 3]
    % Usando logaritmo natural 'log' conforme recomendado [2]
    Snt(k) = sum(pk .* xk .* log(xk)) - k2 * log(k2);
    
    % Para S_inv, invertemos a ordem das energias P_k -> P_{N-k+1}
    pk_rev = flipud(pk); 
    k2_rev = sum(pk_rev .* xk);
    Srev(k) = sum(pk_rev .* xk .* log(xk)) - k2_rev * log(k2_rev);
    
    % 5. Cálculo Vetorizado de PI(phi) e Distância D
    % Criamos uma matriz para evitar o loop 'b'
    % xk: (k x 1), ww: (1 x n_fi) -> exp_arg: (k x n_fi)
    exp_arg = complex(0, 1) * (xk * ww);
    Pi_phi = abs(pk' * exp(exp_arg)).^2; % Produto matricial calcula todos os fi de uma vez
    
    D(k) = mean(abs(Pi_phi - pi_c));
    
    % Convertional time
    %ct(k)=tpico(k);
    % Natural time
    nt(k)=k;

    % Feedback de progresso (opcional)
    % if mod(k, 1000) == 0, disp(['Progresso: ', num26(k/Lin*100), '%']); end
end
%
figure()
% nt=ct;
plot(nt,kapa1,'r')
hold on
plot(nt,Snt,'b')
plot(nt,Srev,'m')
plot(nt,D,'g')
grid on

plot([0 k],[0.07 0.07],'r--')
plot([0 k],[0.096 0.096],'b--')
plot([0 k],[0.02 0.02],'g--')
% ylim([0 0.3])
legend('\kappa_1','S','S_r_e_v','D','0.07','0.096','0.02')
xlabel('N','FontName','Times New Roman','FontSize',18,'Rotation',0)
ylabel('\kappa_1, S, S_r_e_v, D','FontName','Times New Roman','FontSize',18,'Rotation',90)

%% ENTROPIAS SHENNON AND HKL

%Q=dados';
Lin = length(Q);

% 2. Pré-alocação de variáveis para desempenho
Hs = zeros(Lin, 1);
Hkl = zeros(Lin, 1);

% 3. Cálculo Evolutivo (Abordagem de Janela Crescente)
% Conforme o artigo, a janela de detecção inicia no primeiro evento e 
% cresce a cada novo hit para capturar o comportamento histórico [3, 6].
for K = 2:Lin
    % Energias da janela atual (do evento 1 até K)
    current_Q = Q(1:K);
    An = sum(current_Q); % Soma total da área/energia da janela [6, 7]
    
    % Vetor de probabilidade pK (distribuição de massa de ocorrência) [2]
    % pK(k) é o k-ésimo elemento do vetor de probabilidade [2]
    pk = current_Q / An;
    
    % --- Entropia de Shannon (Hs) ---
    % Calculada para o hit K usando o logaritmo natural (ln) conforme orientação [2, 5]
    % Hs(K) = -sum( pK * ln(pK) ) [2, 6]
    Hs(K) = -sum(pk .* log(pk + eps));
    
    % --- Entropia de Kullback-Leibler (Hkl) ---
    % Expressa a probabilidade do evento atual condicionada pelo anterior [8]
    % HKL(K) = -sum_{k=2}^{K} pK(k) * ln( pK(k) / pK(k-1) ) [6]
    pk_atual = pk(2:end);
    pk_anterior = pk(1:end-1);
    Hkl(K) = -sum(pk_atual .* log((pk_atual + eps) ./ (pk_anterior + eps)));
end

% 4. Valores Cumulativos (Sigma Hs e Sigma Hkl)
% O artigo também avalia a sensibilidade dos valores acumulados ao dano [1, 8].
sum_Hs = cumsum(Hs);
sum_Hkl = cumsum(Hkl);

% 5. Visualização dos Resultados
figure;
%subplot(2,1,1);
plot(Hs); 
ylabel('\itH_s','FontName','Times New Roman','FontSize',18,'Rotation',90)
%set(gca, 'XTickLabel', []);      % Remove os rótulos do eixo x grid on;
grid on
yyaxis right
ax = gca;
ax.YColor = 'k';  % define a cor do eixo Y direito como preto
hold on
%subplot(2,1,2);
plot(Hkl); grid on;
ylabel('\itH_{KL}','FontName','Times New Roman','FontSize',18,'Rotation',90)
legend('\itH_s','itH_{KL}')

%% TSALLIS ENTROPY
win=50;                   %initial data size 
k=1;
Amp=dados';
tpico=1:1:size(dados,2) ; tpico=tpico';
for jj=win+1:1:size(dados,2) 
%Interval=[tpico(jj-win) tpico(jj)]; % SLIDING WINDOWN
Interval=[1 jj]; %
Mi=0.05; % division on the Amplitude distribution
[Datavalue, A_fit, lmbda_fit, q_fit, resultados_fit,p2]=EA_Calc_q(Amp,tpico,Interval,Mi,'NHist');
A(k)=A_fit;
lmbda(k)=lmbda_fit; 
q(k)=q_fit; 
R(k)=resultados_fit.R_squared; 
TPico(k)=jj;
p22(k)=p2;
k=k+1;
end
%%
figure;
plot(TPico,q,'r')
ylabel('q','FontName','Times New Roman','FontSize',20,'Rotation',90)
yyaxis right
hold on
plot(TPico,1./lmbda,'b')
legend('q','lambda')
xlabel('N','FontName','Times New Roman','FontSize',20,'Rotation',0)
ylabel('lambda','FontName','Times New Roman','FontSize',20,'Rotation',90)

%
figure;
scatter(1./lmbda, q, 8, TPico, 'o'); % 50 = tamanho dos marcadores
colorbar;
xlabel('1/\it\lambda', 'FontSize', 12);
ylabel('\itq', 'FontSize', 12);
grid on
box on
ylabel(colorbar, 'Time [s]');


