%--------- PROGRAMA PRINCIPAL DE LOCALIZAÇAO DE FALTAS EM REDES RADIAIS
%--------- UTILIZANDO ALGORITMO CLONAL
clear; clc;
%------ leitura de dados
caso = 'caso33barras';           %% caso33barras   casoStevenson81  casoStevenson81Radial   casoSol4    casoUFU   casoieee4livro  casoSubTransDistrib33  casoLivroDistribuicao  casoieee14
pu=2; % 1= sim esta  2= nao esta em p.u.
[rede, barras, nomes, linhas, Geradores, Trafos] = feval(caso); 

%------ leitura da falta real
BarDe=27;
BarPara=28;
Zdistancia=7.22;
Tipo_curto=3;  %1=trifasico   2=FASE-TERRA    3=FASE-FASE-TERRA    4=FASE-FASE
Zdefeito=9.0; %em p.u.
%------ Barras onde estão os medidores
Bar_Med = (1:length(barras))'; % Preenche todos os medidores (todas as barras)
N_med=length(Bar_Med);

%------ faz um curto circuito na falta
Anticorpo= [BarDe BarPara Zdistancia Tipo_curto Zdefeito];
[Vtrif,VFT,VFFT,VFF] = CurtoCircuito(caso,Anticorpo,pu);

%------ Preenche os medidores com o curto real
[Tens_Med] = preencheMedidores(Bar_Med,Tipo_curto,Vtrif,VFT,VFFT,VFF);

%------ Criar uma população de 10000 curtos aleatórios para comparação
Num_Anticorpos = 10000;  % Define que a população será de 10.000 curtos aleatórios
Populacao_Ant = zeros(Num_Anticorpos, 5); % Armazena os parâmetros dos curtos
fobj_array = zeros(Num_Anticorpos, 1); % Armazena os valores da função objetivo

% Gera 10.000 curtos com configurações diferentes
for i=1:Num_Anticorpos
    % Geração de parâmetros aleatórios para os curtos
    poss1=randi([1 length(linhas(:,1))]); % Sorteia aleatoriamente um trecho da linha
    BarDe=linhas(poss1,1); % Barra de origem
    BarPara=linhas(poss1,2); % Barra de destino
    Zdistancia=rand(1)*100; % Distância no trecho em porcentagem
    Tipo_curto=ceil(rand(1)*4); % Tipo de curto aleatório (1 a 4)
    
    % Definir a impedância do defeito com base no tipo de curto
    if Tipo_curto==2 || Tipo_curto==3
        Zdefeito=rand(1)*20; % Impedância aleatória até 20 ohms
    else
        Zdefeito=0.0; % Impedância de curto nula para outros tipos
    end
    
    % Armazena as configurações de curto geradas
    Populacao_Ant(i, :) = [BarDe BarPara Zdistancia Tipo_curto Zdefeito];
    
    % Faz o curto circuito com os parâmetros gerados
    [Vtrif,VFT,VFFT,VFF] = CurtoCircuito(caso,Populacao_Ant(i,:),pu);
    
    % Preenche os medidores com os resultados do curto gerado
    [Tens_Calc] = preencheMedidores(Bar_Med,Tipo_curto,Vtrif,VFT,VFFT,VFF); 
    
    % Avalia a função objetivo comparando a medição real com a gerada
    fobj_array(i) = avaliaFO(Tens_Med,Tens_Calc);
end

% Ordenar a população de curtos com base no valor da função objetivo
[sorted_fobj, sorted_indices] = sort(fobj_array); % Ordena a função objetivo
Populacao_Ordenada = Populacao_Ant(sorted_indices, :); % Ordena a população com base na função objetiva

% Selecionar a configuração de curto mais próxima da falta original
Melhor_Anticorpo = Populacao_Ordenada(1, :);

% Preencher todos os medidores usando a configuração de curto mais próxima
[Melhor_Vtrif, Melhor_VFT, Melhor_VFFT, Melhor_VFF] = CurtoCircuito(caso,Melhor_Anticorpo,pu);
[Tens_Calc] = preencheMedidores(Bar_Med,Melhor_Anticorpo(4),Melhor_Vtrif,Melhor_VFT,Melhor_VFFT,Melhor_VFF);

% Exibir a configuração de curto mais próxima da falta original
disp('A configuração de curto mais próxima da falta original:');
disp('BarDe   BarPara   Zdistancia   Tipo_curto   Zdefeito');
disp(Melhor_Anticorpo);
