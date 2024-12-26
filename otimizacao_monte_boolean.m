%--------- PROGRAMA PRINCIPAL DE LOCALIZAÇÃO DE FALTAS EM REDES RADIAIS
%--------- UTILIZANDO ALGORITMO SOS
clear; clc;

%------ leitura de dados
caso = 'caso33barras';           %% caso33barras   casoStevenson81  casoStevenson81Radial   casoSol4    casoUFU   casoieee4livro  casoSubTransDistrib33  casoLivroDistribuicao  casoieee14
pu=2; % 1= sim esta  2= nao esta em p.u.
[rede, barras, nomes, linhas, Geradores, Trafos] = feval(caso); 

% Matriz Distancia
 load('Matriz_dist1_33_barras.m');
 load('Matriz_dist2_33_barras.m');

%------ leitura da falta real
BarDe=23; %=input(' Barra "De"');
BarPara=24; %input(' Barra "Para" ');
Zdistancia=7.22;% % porcentual
Tipo_curto=3;  %1=trifasico   2=FASE-TERRA    3=FASE-FASE-TERRA    4=FASE-FASE
Zdefeito=9.0; %em p.u.
Bar_Med = [1; 3; 6]; % Barras com medidores
N_med=length(Bar_Med);

%------ Faz um curto circuito na falta
Anticorpo= [BarDe BarPara Zdistancia Tipo_curto Zdefeito];
[Vtrif,VFT,VFFT,VFF] = CurtoCircuito(caso,Anticorpo,pu);

%------ Preenche os medidores com o curto real
[Tens_Med] = preencheMedidores(Bar_Med,Tipo_curto,Vtrif,VFT,VFFT,VFF);

%------ Criar uma população inicial de x curtos
Num_Anticorpos = 50;  % Define que a população terá x curtos aleatórios
Populacao_Ant = zeros(Num_Anticorpos, 5); % Armazena os parâmetros dos curtos
fobj_array = zeros(Num_Anticorpos, 1); % Armazena os valores da função objetivo


% Gera xx curtos com configurações diferentes
for i=1:Num_Anticorpos
    % Geração de parâmetros aleatórios para os curtos
    poss1 = randi([1 length(linhas(:,1))]);
    BarDe = linhas(poss1,1); 
    BarPara = linhas(poss1,2);
    Zdistancia = rand(1)*100;
    Tipo_curto = ceil(rand(1)*4); 
    
    if Tipo_curto==2 || Tipo_curto==3
        Zdefeito = rand(1)*20; 
    else
        Zdefeito = 0.0; 
    end
    
    Populacao_Ant(i, :) = [BarDe BarPara Zdistancia Tipo_curto Zdefeito];
    
    % Avaliação inicial da função objetivo
    [Vtrif,VFT,VFFT,VFF] = CurtoCircuito(caso,Populacao_Ant(i,:),pu);
    [Tens_Calc] = preencheMedidores(Bar_Med,Tipo_curto,Vtrif,VFT,VFFT,VFF); 
    fobj_array(i) = avaliaFO(Tens_Med,Tens_Calc);
end

%------ Início do ciclo SOS
Num_Ciclos = 20; % Define o número de ciclos
for ciclo=1:Num_Ciclos

    %identificar o melhor solução da população 
    a = min(fobj_array);
    a2 = find(fobj_array(:)==a);
    best_solution = Populacao_Ant(a2,:);

    %------ Fase de Mutualismo
    for i=1:Num_Anticorpos
        % Seleção de dois indivíduos
        j = randi([1, Num_Anticorpos]);
        while j == i
            j = randi([1, Num_Anticorpos]);
        end
        disp("iteração");
        disp(i);
      
  


        % Vetor de relação mútua
        Mutual_Vector = (Populacao_Ant(i, :) + Populacao_Ant(j, :)) / 2;

        % BF é 1 ou 2 aleatorio
        BF1 = randsample([1, 2], 1);
        BF2 = randsample([1, 2], 1);

        
        % Atualização de Distância e Impedância de Defeito
        X_new_i = Populacao_Ant(i, :);
        X_new_j = Populacao_Ant(j, :);


        Barra_De_1 = X_new_i(1);
        Barra_De_2 = X_new_j(1);

        Barra_Para_1 = X_new_i(2);
        Barra_Para_2 = X_new_j(2);

        if(X_new_i(1) == X_new_j(1) || X_new_i(2) == X_new_j(2))

            Distancia=1;

        else

            % Acessar a coluna correspondente ao valor de X_new_i
            coluna_desejada_De = Matriz_dist1_33_barras(:, Barra_De_1);
            % Acessar a coluna correspondente ao valor de Barra_Para_1
            coluna_desejada_Para = Matriz_dist1_33_barras(:, Barra_Para_1);
    
            % Procurar a linha onde o valor na coluna é igual a Barra_de_2
            linha_encontrada_De = find(coluna_desejada_De == Barra_De_2);
            % Procurar a linha onde o valor na coluna é igual a Barra_de_2
            linha_encontrada_Para = find(coluna_desejada_Para == Barra_Para_2);
            
            % Procurar a coluna correspondente ao valor de Barra_de_1 em Matriz_dist2_33_barras
            coluna_encontrada_De = Matriz_dist2_33_barras(:, Barra_De_1);
            % Procurar a coluna correspondente ao valor de Barra_Para_1 em Matriz_dist2_33_barras
            coluna_encontrada_Para = Matriz_dist2_33_barras(:, Barra_Para_1);
    
            % Acessar o valor na linha linha_encontrada e na coluna coluna_encontrada
            distancia_De = coluna_encontrada_De(linha_encontrada_De);
            % Acessar o valor na linha linha_encontrada e na coluna coluna_encontrada
            distancia_Para = coluna_encontrada_Para(linha_encontrada_Para);
    
            % Pega a média das distancias
            Distancia = double(round((distancia_De + distancia_Para)/2));

        
        end


        Coluna_com_distancias = Matriz_dist2_33_barras(:,Barra_De_1);
        disp("Coluna_com_distancias");
        disp(Coluna_com_distancias);
        disp("Distancia");
        disp(Distancia);


        Barras_metade_do_caminho=find(Coluna_com_distancias==Distancia);

        if(length(Barras_metade_do_caminho) >1)
            Barra_metade_do_caminho =Barras_metade_do_caminho(randi([1, length(Barras_metade_do_caminho)]));
        else
            Barra_metade_do_caminho = Barras_metade_do_caminho;
        end
    

        % Procurar o valor de Barra_metade_do_caminho na coluna 1 da matriz 'linhas'
        linha_encontrada_mutual = find(linhas(:, 1) == Barra_metade_do_caminho, 1);


        if ~isempty(linha_encontrada_mutual)
            % Se encontrado na coluna 1
            Mutual_Vector(1) = Barra_metade_do_caminho; % Colocar em posição 1
            Mutual_Vector(2) = linhas(linha_encontrada_mutual, 2); % Valor da coluna 2 na posição 2
        else
            % Procurar o valor de Barra_metade_do_caminho na coluna 2
            linha_encontrada_mutual = find(linhas(:, 2) == Barra_metade_do_caminho, 1);

        if ~isempty(linha_encontrada_mutual)
            % Se encontrado na coluna 2
            Mutual_Vector(2) = Barra_metade_do_caminho; % Colocar em posição 2
            Mutual_Vector(1) = linhas(linha_encontrada_mutual, 1); % Valor da coluna 1 na posição 1
        end
        end
        
  

       %X_Best - Mutual_Vector - Para a barra

       X_Best = best_solution(1,:);

       Distancia_XBest_Mutual = calcula_distancia(X_Best, Mutual_Vector,Matriz_dist1_33_barras, Matriz_dist2_33_barras);

       if ~isscalar(Distancia_XBest_Mutual)
           Distancia_XBest_Mutual = 1;
       end

       % (Xbest - Mutual_Vector)*BF1
       Fator_1 = double(round(rand * Distancia_XBest_Mutual * BF1));

       if(Fator_1==0)
           Fator_1 = 1;
       end

       % (Xbest - Mutual_Vector)*BF1
       Fator_2 = double(round(rand * Distancia_XBest_Mutual * BF2));      

       if(Fator_2 == 0)
           Fator_2 = 1;
       end

   
     
        % Encontra a barra com distancia Factor 1 de X_new_i e escolhe uma
        % aleatoriamente
        Coluna_com_distancias = Matriz_dist2_33_barras(:,X_new_i(1));
        
        disp("Fator_1");
        disp(Fator_1);
        disp(isscalar(Fator_1));

        Barras_com_distancia_de_Xi=find(Coluna_com_distancias==Fator_1);
        disp("Barras com distancia de xi");
        disp(Barras_com_distancia_de_Xi);

          if isempty(Barras_com_distancia_de_Xi)
            Barras_com_distancia_de_Xi = max(Coluna_com_distancias);
          end

          


        if(length(Barras_com_distancia_de_Xi) >1)
            Barra_com_distancia_de_Xi =Barras_com_distancia_de_Xi(randi([1, length(Barras_com_distancia_de_Xi)]));
        else
            Barra_com_distancia_de_Xi = Barras_com_distancia_de_Xi;
        end
        
        % Encontra a barra com distancia Factor 2 de X_new_j e escolhe uma
        % aleatoriamente
        Coluna_com_distancias = Matriz_dist2_33_barras(:,X_new_j(1));
        
        Barras_com_distancia_de_Xj=find(Coluna_com_distancias==Fator_2);

        if isempty(Barras_com_distancia_de_Xj)
            Barras_com_distancia_de_Xj = max(Coluna_com_distancias);
        end

        if(length(Barras_com_distancia_de_Xj) >1)
            Barra_com_distancia_de_Xj =Barras_com_distancia_de_Xj(randi([1, length(Barras_com_distancia_de_Xj)]));
        else
            Barra_com_distancia_de_Xj = Barras_com_distancia_de_Xj;
        end

       % Encontra a barra inicial ou final em linhas para definir um trecho
       % que existe 

        % Procurar o valor de Barra_com_distancia_de_Xi na coluna 1 da matriz 'linhas'
        linha_encontrada_mutual = find(linhas(:, 1) == Barra_com_distancia_de_Xi, 1);

        if ~isempty(linha_encontrada_mutual)
            % Se encontrado na coluna 1
            X_new_i(1) = Barra_com_distancia_de_Xi; % Colocar em posição 1
            X_new_i(2) = linhas(linha_encontrada_mutual, 2); % Valor da coluna 2 na posição 2
        else
            % Procurar o valor de Barra_metade_do_caminho na coluna 2
            linha_encontrada_mutual = find(linhas(:, 2) == Barra_com_distancia_de_Xi, 1);

        if ~isempty(linha_encontrada_mutual)
            % Se encontrado na coluna 2
            X_new_i(2) = Barra_com_distancia_de_Xi; % Colocar em posição 2
            X_new_i(1) = linhas(linha_encontrada_mutual, 1); % Valor da coluna 1 na posição 1
        end
        end

       % Procurar o valor de Barra_com_distancia_de_Xj na coluna 1 da matriz 'linhas'
        linha_encontrada_mutual = find(linhas(:, 1) == Barra_com_distancia_de_Xj, 1);

        if ~isempty(linha_encontrada_mutual)
            % Se encontrado na coluna 1
            X_new_j(1) = Barra_com_distancia_de_Xj; % Colocar em posição 1
            X_new_j(2) = linhas(linha_encontrada_mutual, 2); % Valor da coluna 2 na posição 2
        else
            % Procurar o valor de Barra_metade_do_caminho na coluna 2
            linha_encontrada_mutual = find(linhas(:, 2) == Barra_com_distancia_de_Xj, 1);

        if ~isempty(linha_encontrada_mutual)
            % Se encontrado na coluna 2
            X_new_j(2) = Barra_com_distancia_de_Xj; % Colocar em posição 2
            X_new_j(1) = linhas(linha_encontrada_mutual, 1); % Valor da coluna 1 na posição 1
        end
        end


        clear linha_encontrada_mutual;

        % Impedância e Distancia

        X_new_i(3) = X_new_i(3) + rand*(best_solution(1,3) - Mutual_Vector(3)) * BF1; 
        if(X_new_i(3) < 0)
            X_new_i(3) = 0;
        end
        if(X_new_i(3) > 100)
            X_new_i(3) = 100;
        end
        
        X_new_i(5) = X_new_i(5) + rand*(best_solution(1,5) - Mutual_Vector(5)) * BF1;
         if(X_new_i(5) < 0)
            X_new_i(5) = 0;
        end
        if(X_new_i(5) > 20)
            X_new_i(5) = 20;
        end


        X_new_j(3) = X_new_j(3) + rand*(best_solution(1,3) - Mutual_Vector(3)) * BF2;
        if(X_new_j(3) < 0)
            X_new_j(3) = 0;
        end
        if(X_new_j(3) > 100)
            X_new_j(3) = 100;
        end


        X_new_j(5) = X_new_j(5) + rand*(best_solution(1,5) - Mutual_Vector(5)) * BF2;
        if(X_new_i(5) < 0)
            X_new_i(5) = 0;
        end
        if(X_new_i(5) > 100)
            X_new_i(5) = 20;
        end

        
        % Avaliação dos novos indivíduos
        [Vtrif,VFT,VFFT,VFF] = CurtoCircuito(caso,X_new_i,pu);
        Tens_Calc_i = preencheMedidores(Bar_Med,Tipo_curto,Vtrif,VFT,VFFT,VFF); 
        fobj_new_i = avaliaFO(Tens_Med,Tens_Calc_i);
        
        [Vtrif,VFT,VFFT,VFF] = CurtoCircuito(caso,X_new_j,pu);
        Tens_Calc_j = preencheMedidores(Bar_Med,Tipo_curto,Vtrif,VFT,VFFT,VFF); 
        fobj_new_j = avaliaFO(Tens_Med,Tens_Calc_j);
        
        % Substituição condicional
        if fobj_new_i < fobj_array(i)
            Populacao_Ant(i, :) = X_new_i;
            fobj_array(i) = fobj_new_i;
        end
        if fobj_new_j < fobj_array(j)
            Populacao_Ant(j, :) = X_new_j;
            fobj_array(j) = fobj_new_j;
        end
    

    %------ Fase de Comensalismo
        
        % Seleção de um indivíduo
        j = randi([1, Num_Anticorpos]);
        while j == i
            j = randi([1, Num_Anticorpos]);
        end
        
        % Atualização
        X_new = Populacao_Ant(i, :);
        X_new(3) = X_new(3) + (2* rand -1)*(best_solution(1,3) - Populacao_Ant(j, 3));
        if(X_new_i(3) < 0)
            X_new_i(3) = 0;
        end
        if(X_new_i(3) > 100)
            X_new_i(3) = 100;
        end


        X_new(5) = X_new(5) + (2* rand -1)*(best_solution(1,3) - Populacao_Ant(j, 5));
        if(X_new_i(3) < 0)
            X_new_i(3) = 0;
        end
        if(X_new_i(3) > 20)
            X_new_i(3) = 20;
        end 
        
        % Avaliação do novo indivíduo
        [Vtrif,VFT,VFFT,VFF] = CurtoCircuito(caso,X_new,pu);
        Tens_Calc = preencheMedidores(Bar_Med,Tipo_curto,Vtrif,VFT,VFFT,VFF); 
        fobj_new = avaliaFO(Tens_Med,Tens_Calc);
        
        % Substituição condicional
        if fobj_new < fobj_array(i)
            Populacao_Ant(i, :) = X_new;
            fobj_array(i) = fobj_new;
        end
    

    %------ Fase de Parasitismo
        % Geração de um parasita
        Parasita = Populacao_Ant(i, :);

        Parasita(3) = rand*100;
        Parasita(5) = rand*20;
        
        % Avaliação do parasita
        [Vtrif,VFT,VFFT,VFF] = CurtoCircuito(caso,Parasita,pu);
        Tens_Calc = preencheMedidores(Bar_Med,Tipo_curto,Vtrif,VFT,VFFT,VFF); 
        fobj_parasita = avaliaFO(Tens_Med,Tens_Calc);
        
        % Substituição condicional
        if fobj_parasita < fobj_array(i)
            Populacao_Ant(i, :) = Parasita;
            fobj_array(i) = fobj_parasita;
        end
    
    end

end


% Exibir as 5 melhores soluções após os ciclos
[sorted_fobj, sorted_indices] = sort(fobj_array);
Populacao_Ordenada = Populacao_Ant(sorted_indices, :);
disp('As 5 configurações de curtos mais próximas do curto original:');
disp('BarDe   BarPara   Zdistancia   Tipo_curto   Zdefeito');
disp(Populacao_Ordenada(1:5, :));
