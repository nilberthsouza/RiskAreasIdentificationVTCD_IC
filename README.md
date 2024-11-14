# Localização de Faltas em Redes Radiais

Este repositório contém dois scripts MATLAB destinados à localização de faltas em redes radiais de distribuição elétrica, utilizando algoritmos de simulação e classificação de faltas:

1. **`boolean_localizador.m`**: Utiliza um algoritmo clonal combinado com a matriz de curtos fornecida para realizar a simulação e localização de faltas, aplicando técnicas de comparação para identificar as barras mais prováveis de ocorrer falhas.
2. **`monte_carlo_curtos.m`**: Realiza a simulação de curtos com dados fornecidos diretamente, aplicando o método de Monte Carlo para simular e classificar as faltas, sem gerar uma população aleatória para comparação.

## Arquivos

### 1. `boolean_localizador.m`

Este script realiza a localização de faltas em redes radiais com o uso de um **algoritmo clonal** e **Monte Carlo** para simular faltas com variabilidade aleatória.

- **Funcionalidade**: Identifica e classifica as barras mais prováveis de ocorrência de faltas, usando uma matriz de curtos gerada por uma simulação inicial. Através de comparações probabilísticas, o script encontra o tipo de falta mais similar a partir de uma população de faltas aleatórias.
- **Parâmetros principais**:
  - `caso`: Define o caso da rede de barras a ser utilizado (por exemplo, `'caso33barras'`).
  - `pu`: Define se o sistema está em pu (`1`) ou não (`2`).
  - `num_tentativas`: Controla o número de tentativas de Monte Carlo para a criação da matriz de curtos aleatórios.
  - `Num_Anticorpos`: Quantidade de curtos aleatórios simulados para comparação.
- **Método de Simulação**: Baseia-se no ajuste das tensões nas barras através de uma matriz de comparação (`Matriz_VTCD_Saida`) que armazena os indicadores de VTCD (Variação Típica de Curto-Circuito em Defeito) para cada curto mais provável.
  
### 2. `monte_carlo_curtos.m`

Este script realiza a simulação direta das faltas em uma rede radial, aplicando uma matriz de curtos fornecida diretamente e sem gerar valores aleatórios para uma população comparativa.

- **Funcionalidade**: Usa um método de Monte Carlo direto para atribuir e classificar faltas de acordo com a matriz de curtos especificada. A matriz `Matriz_Curtos_Com_Barras` define todas as informações de cada falta, permitindo uma análise controlada do impacto das faltas nas barras.
- **Parâmetros principais**:
  - `caso`: Define o caso da rede de barras a ser utilizado (por exemplo, `'caso33barras'`).
  - `pu`: Define se o sistema está em pu (`1`) ou não (`2`).
- **Método de Simulação**: A simulação utiliza uma matriz `Matriz_VTCD_Saida` para armazenar os indicadores de VTCD em cada barra, indicando onde as tensões variam de forma significativa (0.1-0.9 ou 1.1-1.8 pu) durante uma falta.

## Pré-requisitos

- **MATLAB**: Os scripts requerem MATLAB para execução.
- **Modelo de Rede Elétrica**: Ambos os scripts utilizam um modelo de rede elétrica com parâmetros de barras e linhas, como o arquivo `'caso33barras.m'`. Certifique-se de que o arquivo correspondente ao caso da rede esteja presente no mesmo diretório.

## Uso

### Executando os Scripts

1. Abra o MATLAB.
2. Certifique-se de que os arquivos `boolean_localizador.m`, `monte_carlo_curtos.m`, e o modelo de rede elétrica (`caso33barras.m`) estejam no mesmo diretório de trabalho.
3. Execute o script desejado:

   ```matlab
   boolean_localizador
