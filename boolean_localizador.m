%--------- PROGRAMA PRINCIPAL DE LOCALIZAÇÃO DE FALTAS EM REDES RADIAIS
%--------- UTILIZANDO ALGORITMO CLONAL COM MATRIZ DE CURTOS FORNECIDA
clear; clc;

%------ leitura de dados
caso = 'caso33barras';  % Escolha do caso
pu = 2; % 1 = sim, está; 2 = não está em p.u.
[rede, barras, nomes, linhas, Geradores, Trafos] = feval(caso);

Trechos = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 21; 22; 23; 24; 25; 26; 27; 28; 29; 30; 31; 32];

N_Faltas = [1; 3; 2; 4; 1; 3; 2; 1; 4; 2; 3; 1; 4; 2; 3; 1; 4; 1; 2; 3; 4; 1; 3; 2; 4; 2; 1; 3; 1; 4; 2; 3];

[~, ~, ~, linhas] = caso33barras;

% Inicialização da matriz com 32 linhas e 2 colunas
Matriz = zeros(32, 2);

% Atribuição dos valores na primeira linha
Matriz(1, 1) = 0;               % Coluna 1, primeira linha começa em 0
Matriz(1, 2) = Matriz(1, 1) + N_Faltas(1); % Coluna 2, soma com o primeiro elemento de N_Faltas

% Preenchimento das linhas restantes
for i = 2:32
    Matriz(i, 1) = Matriz(i - 1, 2);      % Valor da coluna 1 é o valor da coluna 2 da linha anterior
    Matriz(i, 2) = Matriz(i, 1) + N_Faltas(i); % Valor da coluna 2 é a soma do valor da coluna 1 com o valor correspondente de N_Faltas
end

% Exibição da matriz resultante
% disp(Matriz);

% Último valor da última linha da matriz
ultimo_valor = Matriz(end, end);

% Vetor Qte_curtos inicializado com zeros
Qte_curtos = zeros(32, 1);

% Número de tentativas (pode ser alterado conforme necessário)
num_tentativas = 2.5*ultimo_valor; % Exemplo com 100 tentativas

% Loop para realizar tentativas de geração de números aleatórios
for t = 1:num_tentativas
    % Adcionar curva de distribuição 
    %como utilizar criterio de monte carlo para dados que seguem
    %distribuição normal 
    % Gera um número aleatório entre 0 e ultimo_valor
    numero_aleatorio = rand * ultimo_valor ;

    % Verifica em qual linha o número se encontra na matriz
    for i = 1:32
        if numero_aleatorio >= Matriz(i, 1) && numero_aleatorio < Matriz(i, 2)
            Qte_curtos(i) = Qte_curtos(i) + 1;
            break;
        end
    end
end

% Mostrando o vetor Qte_curtos com os contadores
% disp('Vetor Qte_curtos acumulado:');
% disp(Qte_curtos);

%%

% Quantidade acumulada de curtos
total_curtos = sum(Qte_curtos);

% Inicializar vetor Tipos_de_curtos_Distribuidos com zeros
Tipos_de_curtos_Distribuidos = zeros(total_curtos, 1);

% Distribuição probabilística dos tipos de falta
probabilidades = [0.05, 0.70, 0.10, 0.15]; % Probabilidades para 1, 2, 3, e 4
tipos_faltas = [1, 2, 3, 4]; % Tipos de falta: 1=trifasico, 2=FASE-TERRA, 3=FASE-FASE-TERRA, 4=FASE-FASE

% Preencher o vetor Tipos_de_curtos_Distribuidos conforme a distribuição de probabilidades
for i = 1:total_curtos
    % Gerar um número aleatório para decidir o tipo de curto
    rand_num = rand;
    
    % Atribuir o tipo de curto com base nas probabilidades
    if rand_num < probabilidades(1)
        Tipos_de_curtos_Distribuidos(i) = tipos_faltas(1); % Trifásico (1)
    elseif rand_num < sum(probabilidades(1:2))
        Tipos_de_curtos_Distribuidos(i) = tipos_faltas(2); % Monofásico (2)
    elseif rand_num < sum(probabilidades(1:3))
        Tipos_de_curtos_Distribuidos(i) = tipos_faltas(3); % Duas fases-terra (3)
    else
        Tipos_de_curtos_Distribuidos(i) = tipos_faltas(4); % Duas fases (4)
    end
end

% Exibição do vetor Tipos_de_curtos_Distribuidos
% disp('Vetor Tipos_de_curtos_Distribuidos:');
% disp(Tipos_de_curtos_Distribuidos);


%%

% Inicialização da matriz com total_curtos linhas e 5 colunas
Matriz_Curtos = zeros(total_curtos, 5);

% Preencher a primeira coluna com os trechos, conforme Qte_curtos
indice = 1; % Índice para percorrer as linhas da Matriz_Curtos
for i = 1:length(Qte_curtos)
    for j = 1:Qte_curtos(i)
        Matriz_Curtos(indice, 1) = i; % Atribui o valor do trecho
        indice = indice + 1;
    end
end

% Preencher a segunda coluna com os tipos de curtos
Matriz_Curtos(:, 2) = Tipos_de_curtos_Distribuidos;

% Preencher a terceira coluna com valores aleatórios de distância entre 0 e 1
Matriz_Curtos(:, 3) = rand(total_curtos, 1);

% Preencher a quarta coluna com impedância de defeito para tipos específicos
for k = 1:total_curtos
    if Matriz_Curtos(k, 2) == 2 || Matriz_Curtos(k, 2) == 3 % Tipo Fase-Terra ou Fase-Fase-Terra
        Matriz_Curtos(k, 4) = rand * 20; % Gera valor aleatório entre 0 e 20
    end
end




% Adicionar duas colunas iniciais à Matriz_Curtos
% As colunas "BarDe" e "BarPara" são retiradas das colunas 1 e 2 do vetor linhas

% Inicializar nova matriz com 2 colunas extras para "BarDe" e "BarPara"
Matriz_Curtos_Com_Barras = zeros(total_curtos, 7);

% Preencher "BarDe" e "BarPara" na nova matriz
for k = 1:total_curtos
    trecho = Matriz_Curtos(k, 1); % Trecho da primeira coluna de Matriz_Curtos
    Matriz_Curtos_Com_Barras(k, 1) = linhas(trecho, 1); % "BarDe"
    Matriz_Curtos_Com_Barras(k, 2) = linhas(trecho, 2); % "BarPara"
end

% Copiar as demais colunas de Matriz_Curtos para a nova matriz
Matriz_Curtos_Com_Barras(:, 3:end) = Matriz_Curtos;

% Exibir a nova matriz com as colunas "BarDe" e "BarPara" adicionadas
disp('Matriz_Curtos_Com_Barras:');
disp(Matriz_Curtos_Com_Barras);




%------ Configuração da Matriz de Saída
N = length(barras);               % Número de barras
M = size(Matriz_Curtos_Com_Barras, 1); % Número de curtos
Matriz_VTCD_Saida = zeros(N, M);  % Matriz de saída com N barras e M colunas para cada curto

%------ Loop para cada linha da Matriz_Curtos_Com_Barras
for m = 1:M
    % Extrair informações do curto real da linha m
    BarDe = Matriz_Curtos_Com_Barras(m, 1);
    BarPara = Matriz_Curtos_Com_Barras(m, 2);
    Zdistancia = Matriz_Curtos_Com_Barras(m, 3);
    Tipo_curto = Matriz_Curtos_Com_Barras(m, 4);
    Zdefeito = Matriz_Curtos_Com_Barras(m, 5);
    
    %------ Simular a falta real
    Anticorpo = [BarDe BarPara Zdistancia Tipo_curto Zdefeito];
    [Vtrif, VFT, VFFT, VFF] = CurtoCircuito(caso, Anticorpo, pu);

    %------ Preencher os medidores com o curto real
    Bar_Med = (1:length(barras))'; % Todas as barras
    [Tens_Med] = preencheMedidores(Bar_Med, Tipo_curto, Vtrif, VFT, VFFT, VFF);

    %------ Criar uma população de 10000 curtos aleatórios para comparação
    Num_Anticorpos = 10000;
    Populacao_Ant = zeros(Num_Anticorpos, 5);
    fobj_array = zeros(Num_Anticorpos, 1);

    for i = 1:Num_Anticorpos
        % Geração de parâmetros aleatórios para os curtos
        poss1 = randi([1 length(linhas(:,1))]);
        BarDe = linhas(poss1,1);
        BarPara = linhas(poss1,2);
        Zdistancia = rand * 100;
        Tipo_curto = ceil(rand * 4);

        if Tipo_curto == 2 || Tipo_curto == 3
            Zdefeito = rand * 20;
        else
            Zdefeito = 0.0;
        end

        Populacao_Ant(i, :) = [BarDe BarPara Zdistancia Tipo_curto Zdefeito];
        [Vtrif, VFT, VFFT, VFF] = CurtoCircuito(caso, Populacao_Ant(i,:), pu);
        [Tens_Calc] = preencheMedidores(Bar_Med, Tipo_curto, Vtrif, VFT, VFFT, VFF);
        fobj_array(i) = avaliaFO(Tens_Med, Tens_Calc);
    end

    % Ordenar a população de curtos e selecionar o mais próximo
    [~, sorted_indices] = sort(fobj_array);
    Melhor_Anticorpo = Populacao_Ant(sorted_indices(1), :);

    % Preencher todos os medidores com a configuração do melhor anticorpo
    [Melhor_Vtrif, Melhor_VFT, Melhor_VFFT, Melhor_VFF] = CurtoCircuito(caso, Melhor_Anticorpo, pu);
    [Tens_Calc] = preencheMedidores(Bar_Med, Melhor_Anticorpo(4), Melhor_Vtrif, Melhor_VFT, Melhor_VFFT, Melhor_VFF);

    % Criar a matriz de vtcd para cada barra
    Matriz_Vtcd = zeros(N, 1);

    for j = 1:N
        tensoes_barra = Tens_Calc(j, :);
        if any((tensoes_barra >= 0.1 & tensoes_barra <= 0.9) | (tensoes_barra >= 1.1 & tensoes_barra <= 1.8))
            Matriz_Vtcd(j) = 1;
        end
    end

    % Armazenar os resultados de VTCD para este curto na coluna m da matriz de saída
    Matriz_VTCD_Saida(:, m) = Matriz_Vtcd;
end

% Exibir a matriz de saída final
disp('Matriz de classificação de VTCD para cada curto mais provável:');
disp(Matriz_VTCD_Saida);
