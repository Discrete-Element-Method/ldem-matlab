function dados = gerar_transicao_dupla(n_total, velocidade1, velocidade2, expoente)
    % GERAR_TRANSICAO_DUPLA - Gera números com transição uniforme → potencial → uniforme
    %
    % Entradas:
    %   n_total     - número total de elementos
    %   velocidade1 - velocidade da primeira transição (uniforme → potencial)
    %                 valores típicos: 1 a 10 (maior = mais abrupta)
    %   velocidade2 - velocidade da segunda transição (potencial → uniforme)
    %   expoente    - expoente da distribuição potencial (alfa > 0)
    %
    % Saída:
    %   dados       - vetor (1 x n_total) com os números gerados

    % Validações
    if nargin < 4
        error('São necessários 4 argumentos: n_total, velocidade1, velocidade2, expoente');
    end
    if velocidade1 <= 0 || velocidade2 <= 0
        error('As velocidades devem ser positivas');
    end
    if expoente <= 0
        error('Expoente deve ser positivo');
    end

    % Pontos de transição fixos (frações normalizadas de 0 a 1)
    p1 = 0.01;   % fim da primeira zona uniforme
    p2 = 0.01;   % fim da transição uniforme → potencial
    p3 = 1.0;   % fim da zona potencial pura
    p4 = 1.0;   % fim da transição potencial → uniforme

    % Pré‑calcular a distribuição potencial (intervalo [0.01, 1])
    x_min = 0.01;
    x_max = 1.0;
    if abs(expoente - 1) < 1e-6
        % Expoente = 1 → distribuição logarítmica
        log_ratio = log(x_max / x_min);
        gerar_potencial = @() x_min * exp(rand() * log_ratio);
    else
        c1 = x_min^(1 - expoente);
        c2 = x_max^(1 - expoente);
        gerar_potencial = @() (rand() * (c2 - c1) + c1)^(1/(1 - expoente));
    end

    % Gerar cada elemento
    dados = zeros(1, n_total);
    for i = 1:n_total
        t = (i - 1) / (n_total - 1);   % posição normalizada (0 → 1)

        % Determinar o peso da componente potencial (0 = uniforme, 1 = potencial)
        if t <= p1
            peso_pot = 0;
        elseif t <= p2
            % Transição uniforme → potencial (sigmóide crescente)
            t_norm = (t - p1) / (p2 - p1);   % mapeia [p1, p2] → [0, 1]
            peso_pot = 1 / (1 + exp(-velocidade1 * (t_norm - 0.5) * 8));
        elseif t <= p3
            % Zona potencial pura
            peso_pot = 1;
        elseif t <= p4
            % Transição potencial → uniforme (sigmóide decrescente)
            t_norm = (t - p3) / (p4 - p3);   % mapeia [p3, p4] → [0, 1]
            peso_pot = 1 / (1 + exp(velocidade2 * (t_norm - 0.5) * 8));
        else
            peso_pot = 0;
        end

        % Amostrar conforme o peso
        if rand() < peso_pot
            dados(i) = gerar_potencial();
        else
            dados(i) = rand();   % uniforme em [0,1]
        end
    end
end