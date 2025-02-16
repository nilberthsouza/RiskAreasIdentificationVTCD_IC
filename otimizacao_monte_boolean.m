%% Programa Principal de Localização de Faltas em Redes Radiais
% Utilizando o algoritmo SOS (Simulated Organism Search)
%----------------------------------------------------------------------
clear; clc;

%% Leitura dos dados do caso e das matrizes de distância
caso = 'caso33barras'; % Escolha o caso desejado (ex: 'caso33barras', 'casoStevenson81', etc.)
pu = 2;  % 1 = valores em p.u. ; 2 = não está em p.u.
[rede, barras, nomes, linhas, geradores, trafos] = feval(caso);

% Carregar matrizes de distância pré-calculadas
load("Matriz_Distancias_De.m");  % Distância "de" cada trecho
load("Matriz_Distancias_Para.m");  % Distância "para" cada trecho

%% Definição do curto real (falta real)
barra_de_real   = 21;    % Barra de origem da falta
barra_para_real = 22;    % Barra de destino da falta
porc_dist_real  = 10;   % Posição percentual no trecho, ex: 7.22%
tipo_curto_real = 3;     % Tipos: 1 = trifásico, 2 = fase-terra, 3 = fase-fase-terra, 4 = fase-fase
Z_defeito_real  = 15.0;   % Impedância de curto (em p.u. ou unidades do caso)
barras_medidor  = [1;15;20;24;29;]; % Barras onde há medidores
num_medidores   = length(barras_medidor);

% Parâmetros do curto real a ser simulado
curto_real = [barra_de_real, barra_para_real, porc_dist_real, tipo_curto_real, Z_defeito_real];

% Realiza o cálculo do curto real (utilizando funções definidas no caso)
[V_trif, V_FT, V_FFT, V_FF] = CurtoCircuito(caso, curto_real, pu);

% Preenche os medidores com os tensores do curto real
tensores_med_real = preencheMedidores(barras_medidor, tipo_curto_real, V_trif, V_FT, V_FFT, V_FF);

%% Criação da População Inicial (Conjunto de Anticorpos)
num_anticorpos = 50;  % Número de curtos candidatos na população
populacao = zeros(num_anticorpos, 5);    % Cada linha: [BarDe, BarPara, Zdist, Tipo_curto, Zdefeito]
fobj_array = zeros(num_anticorpos, 1);     % Vetor com valores da função objetivo para cada candidato

% Gera curtos aleatórios (organismos) para a população inicial
for i = 1:num_anticorpos
    % Seleciona aleatoriamente um trecho da rede
    trecho_idx = randi(size(linhas,1));
    bar_de = linhas(trecho_idx, 1);
    bar_para = linhas(trecho_idx, 2);
    
    % Parâmetros aleatórios para posição e tipo do curto
    Z_dist = rand * 100;           % Percentual da distância (0 a 100)
    tipo_curto = randi([1, 4]);      % Tipo de curto (1 a 4)
    
    % Se o curto envolver terra (tipos 2 ou 3), atribui um defeito aleatório
    if tipo_curto == 2 || tipo_curto == 3
        Z_defeito = rand * 20;
    else
        Z_defeito = 0.0;
    end
    
    populacao(i, :) = [bar_de, bar_para, Z_dist, tipo_curto, Z_defeito];
    
    % Avalia a função objetivo (diferença entre medidores reais e calculados)
    [V_trif, V_FT, V_FFT, V_FF] = CurtoCircuito(caso, populacao(i,:), pu);
    tensores_calc = preencheMedidores(barras_medidor, tipo_curto, V_trif, V_FT, V_FFT, V_FF);
    fobj_array(i) = avaliaFO(tensores_med_real, tensores_calc);
end

%% Parâmetros do ciclo SOS
num_ciclos = 50;  % Número de iterações (ciclos do algoritmo)

%% Início dos Ciclos do Algoritmo SOS
for ciclo = 1:num_ciclos
    % Identifica o melhor candidato (solução) atual
    [fobj_best, idx_best] = min(fobj_array);
    melhor_solucao = populacao(idx_best, :);
    
    % Para cada organismo na população, realiza os três processos: Mutualismo, Comensalismo e Parasitismo
    for i = 1:num_anticorpos
        
        %% FASE DE MUTUALISMO
        % Seleciona um parceiro (organismo j) diferente do i
        j = randi(num_anticorpos);
        while j == i
            j = randi(num_anticorpos);
        end
        
        % Cópias dos organismos i e j para atualização
        org_i = populacao(i, :);
        org_j = populacao(j, :);
        
        % Vetor de efeito mútuo (média dos dois organismos)
        vetor_mutual = (org_i + org_j) / 2;
        
        % Fatores bióticos aleatórios (1 ou 2)
        BF1 = randsample([1, 2], 1);
        BF2 = randsample([1, 2], 1);
        
        % --- Atualização da posição das barras (trecho) via distância mútua ---
        % Obter índice do trecho atual de org_i e org_j
        trecho_i_idx = find(linhas(:,1) == org_i(1) & linhas(:,2) == org_i(2), 1);
        trecho_j_idx = find(linhas(:,1) == org_j(1) & linhas(:,2) == org_j(2), 1);
        
        % Determina a distância (metade do caminho) entre os trechos dos organismos
        distancia_media = round(Matriz_Distancias_De(trecho_i_idx, trecho_j_idx) * 0.5);
        
        % Seleciona um trecho mutual aleatório baseado na distância
        trecho_mutual_idx = escolheTrecho(Matriz_Distancias_De, trecho_i_idx, distancia_media);

        if isempty(trecho_mutual_idx)
            % Se não encontrou, mantém os trechos originais
            trecho_mutual_idx = trecho_i_idx;
        end
        
        %%
        trecho_mutual = linhas(trecho_mutual_idx, :);
        % Atualiza o vetor mutual para as barras: utiliza o trecho encontrado
        %vetor_mutual(1:2) = trecho_mutual(1:2);
        vetor_mutual(1) = trecho_mutual(1);
        vetor_mutual(2) = trecho_mutual(2);
        %%

        % --- Cálculo do fator de deslocamento com base na melhor solução ---
        % Localiza o trecho da melhor solução
        trecho_best_idx = find(linhas(:,1) == melhor_solucao(1) & linhas(:,2) == melhor_solucao(2), 1);
        % Distância entre o trecho da melhor solução e o trecho mutual
        distancia_best_mutual = Matriz_Distancias_De(trecho_best_idx, trecho_mutual_idx);
        
        % Calcula os fatores de deslocamento (garantindo valor mínimo 1)
        deslocamento1 = max(1, round(rand * distancia_best_mutual * BF1));
        deslocamento2 = max(1, round(rand * distancia_best_mutual * BF2));
        
        % Atualiza as barras dos organismos i e j com base em deslocamentos
        % Para org_i:
        novo_trecho_i_idx = escolheTrecho(Matriz_Distancias_De, trecho_i_idx, deslocamento1);
        if isempty(novo_trecho_i_idx)
            novo_trecho_i_idx = trecho_i_idx;
        end
        trecho_novo_i = linhas(novo_trecho_i_idx, :);

        
        org_i(1) = trecho_novo_i(1);
        org_i(2) = trecho_novo_i(2);

        
        % Para org_j:
        novo_trecho_j_idx = escolheTrecho(Matriz_Distancias_De, trecho_j_idx, deslocamento2);
        if isempty(novo_trecho_j_idx)
            novo_trecho_j_idx = trecho_j_idx;
        end
        trecho_novo_j = linhas(novo_trecho_j_idx, :);
        org_j(1) = trecho_novo_j(1);
        org_j(2) = trecho_novo_j(2);
        
        % Atualiza os demais parâmetros (Zdist e Zdefeito) com base no vetor mutual e na melhor solução
        org_i(3) = org_i(3) + rand*(melhor_solucao(3) - vetor_mutual(3)) * BF1;
        org_i(3) = clamp(org_i(3), 0, 100);
        org_i(5) = org_i(5) + rand*(melhor_solucao(5) - vetor_mutual(5)) * BF1;
        org_i(5) = clamp(org_i(5), 0, 20);
        
        org_j(3) = org_j(3) + rand*(melhor_solucao(3) - vetor_mutual(3)) * BF2;
        org_j(3) = clamp(org_j(3), 0, 100);
        org_j(5) = org_j(5) + rand*(melhor_solucao(5) - vetor_mutual(5)) * BF2;
        org_j(5) = clamp(org_j(5), 0, 20);
        
        % Avalia os novos candidatos (mutualismo)
        [V_trif, V_FT, V_FFT, V_FF] = CurtoCircuito(caso, org_i, pu);
        tensores_calc_i = preencheMedidores(barras_medidor, org_i(4), V_trif, V_FT, V_FFT, V_FF);
        fobj_i_new = avaliaFO(tensores_med_real, tensores_calc_i);
        
        [V_trif, V_FT, V_FFT, V_FF] = CurtoCircuito(caso, org_j, pu);
        tensores_calc_j = preencheMedidores(barras_medidor, org_j(4), V_trif, V_FT, V_FFT, V_FF);
        fobj_j_new = avaliaFO(tensores_med_real, tensores_calc_j);
        
        % Atualização condicional: só substitui se a nova solução for melhor
        if fobj_i_new < fobj_array(i)
            populacao(i, :) = org_i;
            fobj_array(i) = fobj_i_new;
        end
        if fobj_j_new < fobj_array(j)
            populacao(j, :) = org_j;
            fobj_array(j) = fobj_j_new;
        end
        
        %% FASE DE COMENSALISMO
        % Seleciona outro parceiro j (diferente do i)
        j_comm = randi(num_anticorpos);
        while j_comm == i
            j_comm = randi(num_anticorpos);
        end
        
        org_comm = populacao(i, :);  % Cópia do organismo i para atualização
        org_j_comm = populacao(j_comm, :);
        
        % Determina o trecho de org_comm e org_j_comm
        trecho_comm_idx = find(linhas(:,1) == org_comm(1) & linhas(:,2) == org_comm(2), 1);
        trecho_j_comm_idx = find(linhas(:,1) == org_j_comm(1) & linhas(:,2) == org_j_comm(2), 1);
        
        % Determina deslocamento com base na distância entre o melhor e o parceiro j_comm
        trecho_best_idx = find(linhas(:,1) == melhor_solucao(1) & linhas(:,2) == melhor_solucao(2), 1);
        distancia_best_j = Matriz_Distancias_De(trecho_best_idx, trecho_j_comm_idx);
        deslocamento_comm = round(rand * distancia_best_j);
        
        % Atualiza a posição (barras) de org_comm usando o deslocamento encontrado
        novo_trecho_comm_idx = escolheTrecho(Matriz_Distancias_De, trecho_comm_idx, deslocamento_comm);
        if isempty(novo_trecho_comm_idx)
            novo_trecho_comm_idx = trecho_comm_idx;
        end
        trecho_novo_comm = linhas(novo_trecho_comm_idx, :);
        org_comm(1) = trecho_novo_comm(1);
        org_comm(2) = trecho_novo_comm(2);
        
        % Atualiza os parâmetros (Zdist e Zdefeito) com variação simétrica
        org_comm(3) = org_comm(3) + (2*rand - 1)*(melhor_solucao(3) - org_j_comm(3));
        org_comm(3) = clamp(org_comm(3), 0, 100);
        org_comm(5) = org_comm(5) + (2*rand - 1)*(melhor_solucao(5) - org_j_comm(5));
        org_comm(5) = clamp(org_comm(5), 0, 20);
        
        % Avalia o novo organismo com comensalismo
        [V_trif, V_FT, V_FFT, V_FF] = CurtoCircuito(caso, org_comm, pu);
        tensores_calc_comm = preencheMedidores(barras_medidor, org_comm(4), V_trif, V_FT, V_FFT, V_FF);
        fobj_comm_new = avaliaFO(tensores_med_real, tensores_calc_comm);
        
        % Atualiza se a nova solução for melhor
        if fobj_comm_new < fobj_array(i)
            populacao(i, :) = org_comm;
            fobj_array(i) = fobj_comm_new;
        end
        
        %% FASE DE PARASITISMO
        % Cria um parasita a partir do organismo i com parâmetros aleatórios para Zdist e Zdefeito
        parasita = populacao(i, :);
        parasita(3) = rand * 100;
        parasita(5) = rand * 20;
        
        [V_trif, V_FT, V_FFT, V_FF] = CurtoCircuito(caso, parasita, pu);
        tensores_calc_par = preencheMedidores(barras_medidor, parasita(4), V_trif, V_FT, V_FFT, V_FF);
        fobj_parasita = avaliaFO(tensores_med_real, tensores_calc_par);
        
        % Se o parasita apresentar melhor desempenho, substitui o organismo i
        if fobj_parasita < fobj_array(i)
            populacao(i, :) = parasita;
            fobj_array(i) = fobj_parasita;
        end
        
    end % fim do loop para cada organismo
end

%% Exibição dos resultados
% Ordena a população com base na função objetivo (valor menor é melhor)
[sorted_fobj, sorted_indices] = sort(fobj_array);
populacao_ordenada = populacao(sorted_indices, :);

disp('O curto original foi:');
disp('BarDe   BarPara   Zdistancia   Tipo_curto   Zdefeito');
disp(curto_real);

disp('As 5 configurações de curtos mais próximas do curto original:');
disp('BarDe   BarPara   Zdistancia   Tipo_curto   Zdefeito   Funcao_Objetivo');
resultados = [populacao_ordenada(1:5, :), sorted_fobj(1:5)];
disp(resultados);

%% Refinamento da População (antes das funções auxiliares)
% Seleciona os melhores anticorpos da população ordenada, considerando a função
% objetivo arredondada até a segunda casa decimal
uniqueVals = [];
melhores_anticorpos = [];  % Lista dos candidatos únicos (por FO arredondada a 2 decimais)
rounded_fobj = round(sorted_fobj, 2);
for i = 1:length(rounded_fobj)
    if ~ismember(rounded_fobj(i), uniqueVals)
        uniqueVals(end+1) = rounded_fobj(i);
        melhores_anticorpos = [melhores_anticorpos; populacao_ordenada(i, :)];
    end
end

% Cria a população refinada: para cada um dos melhores anticorpos, gera 10
% novos candidatos com pequenas variações nos parâmetros Zdist (3ª coluna)
% e Zdefeito (5ª coluna), variando aleatoriamente entre -10% e +10% do valor original.
populacao_refinada = [];
for i = 1:size(melhores_anticorpos, 1)
    base = melhores_anticorpos(i, :);
    for j = 1:10
        novo = base;  % Cópia da solução base
        
        % Variação na distância (3ª coluna)
        % Calcula variação aleatória entre -10% e +10% do valor original
        variacao_dist = 0.1 * base(3) * (2*rand - 1);
        novo(3) = clamp(base(3) + variacao_dist, 0, 100);
        
        % Variação na impedância de defeito (5ª coluna)
        variacao_def = 0.1 * base(5) * (2*rand - 1);
        novo(5) = clamp(base(5) + variacao_def, 0, 20);
        
        % Adiciona o novo candidato à população refinada
        populacao_refinada = [populacao_refinada; novo];
    end
end

% Avalia a função objetivo para cada elemento da população refinada
num_refinada = size(populacao_refinada, 1);
fobj_refinada = zeros(num_refinada, 1);
for k = 1:num_refinada
    candidato = populacao_refinada(k, :);
    [V_trif, V_FT, V_FFT, V_FF] = CurtoCircuito(caso, candidato, pu);
    tensores_calc = preencheMedidores(barras_medidor, candidato(4), V_trif, V_FT, V_FFT, V_FF);
    fobj_refinada(k) = avaliaFO(tensores_med_real, tensores_calc);
end

% Ordena a população refinada com base na função objetivo (menor é melhor)
[sorted_fobj_ref, idx_ref] = sort(fobj_refinada);
populacao_refinada_ordenada = populacao_refinada(idx_ref, :);

% Identifica o elemento da população refinada que melhor se assemelha ao curto original
melhor_refinado = populacao_refinada_ordenada(1, :);

% Exibe os resultados do refinamento
disp(' ');
disp('Resultados da População Refinada:');
disp('População Refinada Ordenada [BarDe, BarPara, Zdist, Tipo_curto, Zdefeito, Fobj]:');
resultados_refinados = [populacao_refinada_ordenada, sorted_fobj_ref];
disp(resultados_refinados);

disp('O melhor candidato refinado que se assemelha ao curto original é:');
disp('BarDe   BarPara   Zdist   Tipo_curto   Zdefeito');
disp(melhor_refinado);


%% ========== Funções Auxiliares ==========

% Função para selecionar um trecho aleatório com base na distância desejada
function trecho_escolhido = escolheTrecho(distMat, trecho_ref_idx, distancia_desejada)
    % Procura os índices em que a coluna 'trecho_ref_idx' da matriz de
    % distâncias é igual à 'distancia_desejada'
    indices = find(distMat(:, trecho_ref_idx) == distancia_desejada);
    if ~isempty(indices)
        % Seleciona um índice aleatoriamente entre as opções disponíveis
        trecho_escolhido = indices(randi(length(indices)));
    else
        trecho_escolhido = [];
    end
end

% Função para limitar (clamp) um valor entre um mínimo e máximo
function valor_clamped = clamp(valor, valor_min, valor_max)
    valor_clamped = max(valor_min, min(valor, valor_max));
end
