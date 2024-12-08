# Identificação de Areas de Risco Causadas por Variações de Tensão de Curta Duração - Nilberth Souza
Projeto de iniciação Ciêntifica - CNPQ - Universidade Federal de Ouro Preto - ICEA - DEELT 

Este repositório contém três scripts MATLAB destinados à localização de faltas em redes radiais de distribuição elétrica, utilizando algoritmos de simulação e classificação de faltas:

    boolean_localizador.m: Utiliza um algoritmo clonal combinado com a matriz de curtos fornecida para realizar a simulação e localização de faltas, aplicando técnicas de comparação para identificar as barras mais prováveis de ocorrer falhas.
    monte_carlo_curtos.m: Realiza a simulação de curtos com dados fornecidos diretamente, aplicando o método de Monte Carlo para simular e classificar as faltas, sem gerar uma população aleatória para comparação.
    otimizacao_monte_boolean.m: Utiliza um algoritmo de otimização baseado no método Monte Carlo combinado com o conceito de organismos sociais (SOS) para localizar faltas em redes radiais, simulando diversos tipos de faltas em diferentes barras da rede e ajustando os parâmetros de curto-circuito para minimizar a diferença entre os valores simulados e reais de tensão.

## Arquivos
### 1. boolean_localizador.m

Este script realiza a localização de faltas em redes radiais com o uso de um algoritmo clonal e Monte Carlo para simular faltas com variabilidade aleatória.

    Funcionalidade: Identifica e classifica as barras mais prováveis de ocorrência de faltas, usando uma matriz de curtos gerada por uma simulação inicial. Através de comparações probabilísticas, o script encontra o tipo de falta mais similar a partir de uma população de faltas aleatórias.
    Parâmetros principais:
        caso: Define o caso da rede de barras a ser utilizado (por exemplo, 'caso33barras').
        pu: Define se o sistema está em pu (1) ou não (2).
        num_tentativas: Controla o número de tentativas de Monte Carlo para a criação da matriz de curtos aleatórios.
        Num_Anticorpos: Quantidade de curtos aleatórios simulados para comparação.
    Método de Simulação: Baseia-se no ajuste das tensões nas barras através de uma matriz de comparação (Matriz_VTCD_Saida) que armazena os indicadores de VTCD (Variação Típica de Curto-Circuito em Defeito) para cada curto mais provável.

### 2. monte_carlo_curtos.m

Este script realiza a simulação direta das faltas em uma rede radial, aplicando uma matriz de curtos fornecida diretamente e sem gerar valores aleatórios para uma população comparativa.

    Funcionalidade: Usa um método de Monte Carlo direto para atribuir e classificar faltas de acordo com a matriz de curtos especificada. A matriz Matriz_Curtos_Com_Barras define todas as informações de cada falta, permitindo uma análise controlada do impacto das faltas nas barras.
    Parâmetros principais:
        caso: Define o caso da rede de barras a ser utilizado (por exemplo, 'caso33barras').
        pu: Define se o sistema está em pu (1) ou não (2).
    Método de Simulação: A simulação utiliza uma matriz Matriz_VTCD_Saida para armazenar os indicadores de VTCD em cada barra, indicando onde as tensões variam de forma significativa (0.1-0.9 ou 1.1-1.8 pu) durante uma falta.

### 3. otimizacao_monte_boolean.m

Este script realiza a localização de faltas em redes radiais utilizando uma otimização de Monte Carlo combinada com o algoritmo SOS (Social Organism System), inspirado em comportamentos sociais para ajustar os parâmetros de curtos-circuito.

    Funcionalidade: Simula faltas em diversas barras da rede, ajustando parâmetros de curto-circuito (barra de origem, barra de destino, tipo de defeito, distância) para minimizar a diferença entre as tensões medidas e simuladas. A otimização é feita através de um ciclo de mutação, comensalismo e parasitismo, onde a população de curtos é refinada para encontrar a melhor configuração de falta.
    Parâmetros principais:
        caso: Define o caso da rede de barras a ser utilizado (por exemplo, 'caso33barras').
        pu: Define se o sistema está em pu (1) ou não (2).
        num_tentativas: Define o número de tentativas de Monte Carlo para a otimização.
        Num_Anticorpos: Quantidade de curtos simulados.
    Método de Simulação: Através do ciclo de otimização, as simulações de faltas são ajustadas para encontrar a configuração mais precisa. A função objetivo é baseada na comparação entre as tensões reais e simuladas, e o algoritmo ajusta os parâmetros de cada curto para minimizar esse erro.

### Pré-requisitos

    MATLAB: Os scripts requerem MATLAB (versão minima 2023) para execução.
    Modelo de Rede Elétrica: Todos os scripts utilizam um modelo de rede elétrica com parâmetros de barras e linhas, como o arquivo 'caso33barras.m'. Certifique-se de que o arquivo correspondente ao caso da rede esteja presente no mesmo diretório.

Uso
Executando os Scripts

    Abra o MATLAB.

    Certifique-se de que os arquivos boolean_localizador.m, monte_carlo_curtos.m, otimizacao_monte_boolean.m, e o modelo de rede elétrica (caso33barras.m) estejam no mesmo diretório de trabalho.

    Execute o script desejado:

boolean_localizador

ou

monte_carlo_curtos

ou

    otimizacao_monte_boolean

Se você tiver dúvidas sobre como usar os scripts ou encontrar algum problema, sinta-se à vontade para abrir uma issue ou entrar em contato.
