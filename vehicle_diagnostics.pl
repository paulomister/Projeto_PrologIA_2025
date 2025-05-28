% --- Declarações Dinâmicas ---
% Fatos que representam os sintomas do veículo. São dinâmicos
% para permitir a simulação de diferentes cenários nos testes.
:- dynamic(bateria/1).           % Voltagem da bateria.
:- dynamic(temperatura_motor/1). % Temperatura do motor.
:- dynamic(luz_check_engine/0).  % Luz 'Check Engine' acesa.
:- dynamic(luz_bateria/0).       % Luz da bateria acesa.
:- dynamic(falha_ignicao/0).      % Falha ao dar partida.
:- dynamic(nivel_oleo/1).         % Nível de óleo.
:- dynamic(rotacao_alta/0).      % Rotação alta/irregular.
:- dynamic(sensor_oxigenio/1).  % Leitura do sensor de O2.
:- dynamic(barulho_incomum/0).   % Barulho estranho.
:- dynamic(rotacao/0).           % Motor girando.
:- dynamic(perca_potencia/0).    % Perda de potência.
:- dynamic(rpm/1).               % Rotação por minuto.

% --- Possíveis Causas (Falhas) ---
% Lista das falhas que o sistema pode identificar.
causa(bateria_fraca).           % A bateria não tem carga suficiente.
causa(alternador_defeituoso).   % O alternador não está carregando a bateria.
causa(sistema_superaquecimento).% Problema no sistema de arrefecimento (radiador, etc.).
causa(baixo_nivel_oleo).        % Nível de óleo abaixo do recomendado.
causa(vela_ignicao_defeituosa). % Velas de ignição com problema (não usado nas regras atuais, mas definido).
causa(sensor_oxigenio_defeituoso).% Sensor O2 com leitura incorreta.
causa(problema_injecao).         % Problema no sistema de injeção de combustível.
causa(problema_transmissao).     % Problema na caixa de câmbio/transmissão.
causa(problema_interno_motor).  % Problema mecânico grave dentro do motor.


% --- Limiares de Operação ---
% Valores de referência para classificar as leituras.

limiar_temp_motor(100).
limiar_bateria(12).
limiar_oleo(0.2).
limiar_oxigenio(0.2).
limiar_RPM(3000).


% Estas regras verificam se os valores dos sensores ultrapassaram
% os limiares definidos. Elas simplificam as regras de diagnóstico.

% temp_alta: Verdadeiro se a temperatura do motor (T) for maior que o limiar (L).
temp_alta :-
    temperatura_motor(T),    % Obtém a temperatura atual.
    limiar_temp_motor(L),    % Obtém o limiar.
    T > L.                   % Compara.

% oleo_baixo: Verdadeiro se o nível de óleo (O) for menor que o limiar (L).
oleo_baixo :-
    nivel_oleo(O),           % Obtém o nível de óleo.
    limiar_oleo(L),          % Obtém o limiar.
    O < L.                   % Compara.

% bateria_baixa: Verdadeiro se a voltagem da bateria (B) for menor que o limiar (L).
bateria_baixa :-
    bateria(B),              % Obtém a voltagem da bateria.
    limiar_bateria(L),       % Obtém o limiar.
    B < L.                   % Compara.

% oxigenio_alto: Verdadeiro se a leitura do sensor de O2 (S) for maior que o limiar (L).
oxigenio_alto :-
    sensor_oxigenio(S),      % Obtém a leitura do sensor.
    limiar_oxigenio(L),      % Obtém o limiar.
    S > L.                   % Compara.

% rpm_alto: Verdadeiro se as rotações por minuto (X) forem maiores que o limiar (L).
rpm_alto :-
    rpm(X),                  % Obtém o RPM.
    limiar_RPM(L),           % Obtém o limiar.
    X > L.                   % Compara.

/*
* --- Regras de Diagnóstico ---
* O núcleo do sistema. Cada regra mapeia um conjunto de sintomas
* para uma causa provável, usando lógica Prolog.
*/

diagnostico(bateria_fraca) :-
    falha_ignicao,
    luz_bateria,
    bateria_baixa.

diagnostico(alternador_defeituoso) :- 
	luz_bateria,
    \+ diagnostico(bateria_fraca).

diagnostico(sistema_arrefecimento) :-
    temp_alta,
    \+ oleo_baixo,
    luz_check_engine.

diagnostico(baixo_nivel_oleo) :-
    oleo_baixo,
    \+ diagnostico(sistema_arrefecimento).

diagnostico(sensor_oxigenio_defetuoso) :-
    rotacao_alta,
    rpm_alto,
    luz_check_engine,
    oxigenio_alto.

diagnostico(problema_injecao) :-
    rpm_alto,
    luz_check_engine,
    \+ diagnostico(sensor_oxigenio_defetuoso),
    !.   
    
diagnostico(problema_interno_motor) :-
    barulho_incomum,
    rotacao,
    perca_potencia,
    \+ luz_check_engine,
    \+ temp_alta,
    !.

diagnostico(problema_transmissao) :-
    barulho_incomum,
    perca_potencia,
	\+ diagnostico(problema_interno_motor).

/*
* --- Diagnóstico Explicado ---
* Fornece explicações detalhadas para cada diagnóstico, incluindo
* as regras lógicas ativadas, uma justificativa em texto e as
* ações corretivas sugeridas.
*/

diagnostico_explicado(bateria_fraca,
    'Regras Ativadas: falha_ignicao, luz_bateria, bateria_baixa (mesmo que no limite ou ligeiramente acima, se a ignição falhar, a bateria ainda é suspeita),',
    'Justificativa: A falha na ignição combinada com a luz da bateria acesa e a voltagem da bateria abaixo ou no limiar indica que a bateria não está fornecendo voltagem adequada ou está com problemas. Prioriza-se bateria fraca, mas se recarregada e o problema continuar, investiga-se o alternador.',
    'Ações Corretivas: Recarregar ou substituir a bateria. Se o problema persistir, verificar o alternador'
) :-
    falha_ignicao,
    luz_bateria,
    bateria_baixa.

diagnostico_explicado(alternador_defeituoso,
    'luz_bateria, !diagnostico(bateria_fraca).',
    'A luz da bateria está acesa, mas outras causas de bateria fraca foram descartadas, sugerindo um problema no alternador que não está carregando a bateria adequadamente.',
    'Verificar a correia do alternador e, se necessário, trocar o alternador.'
) :-
    luz_bateria,
    \+ diagnostico(bateria_fraca). 

diagnostico_explicado(sistema_arrefecimento,
    'temp_alta, !oleo_baixo, luz_check_engine.',
    'A temperatura do motor está acima do limite e a luz de verificação do motor está acesa, indicando um problema de superaquecimento não relacionado ao baixo nível de óleo.',
    'Checar radiador, bomba d\'água, ventoinha e fluido de arrefecimento. Verificar possíveis vazamentos.'
) :-
    temp_alta,
    \+ oleo_baixo,
    luz_check_engine.

diagnostico_explicado(baixo_nivel_oleo,
    'oleo_baixo, !diagnostico(sistema_arrefecimento).',
    'O nível de óleo está abaixo do limiar, e o problema não é de superaquecimento primário',
    'Verificar o nível de óleo e adicionar se necessário. Investigar a possibilidade de vazamentos ou manutenção atrasada no sistema de oleo'
) :-
    oleo_baixo,
    \+ diagnostico(sistema_arrefecimento).

diagnostico_explicado(sensor_oxigenio_defeituoso,
    'rotacao_alta, rpm_alto, luz_check_engine, oxigenio_alto (ou valor fora da faixa ideal)',
    'O motor está com alta rotação e a luz de verificação esta acesa, e o sensor de oxigênio está coisando valores fora da faixa ideal, muito baixo, o que impacta a mistura ar-combustível',
    'Verificar e possivelmente substituir o sensor de oxigênio. Inspecionar o sistema de exaustão.'
) :-
    rotacao_alta,
    rpm_alto,
    luz_check_engine,
    (oxigenio_alto; (sensor_oxigenio(S), limiar_oxigenio(L), S < L, format(' (Sensor de Oxigenio muito baixo: ~w)', [S]))). 

diagnostico_explicado(problema_injecao,
    'rpm_alto, luz_check_engine, !diagnostico(sensor_oxigenio_defeituoso).',
    'O motor está com alta rotação e a luz de verificação do motor está acesa, mas um problema no sensor de oxigênio foi descartado direcionando para um possível problema no sistema de injecao de combustivel',
    'erificar injetores de combustível, bomba de combustível e filtros de combustível, Realizar diagnóstico eletrônico'
) :-
    rpm_alto,
    luz_check_engine,
    \+ diagnostico(sensor_oxigenio_defeituoso),
    !.

diagnostico_explicado(problema_interno_motor,
    'barulho_incomum, rotacao, perca_potencia, !luz_check_engine, !temp_alta',
    'Há barulhos incomuns, perda de potência e o motor está com rotação, mas sem as luzes de aviso de check engine ou superaquecimento, o que sugere um problema mecânico interno mais grave',
    'Requer uma investigação mecânica aprofundada do motor, como verificar rolamentos, virabrequim, bielas e pistões. Recomenda-se procurar um mecânico especializado imediatamente'
) :-
    barulho_incomum,
    rotacao,
    perca_potencia,
    \+ luz_check_engine,
    \+ temp_alta,
    !.

diagnostico_explicado(problema_transmissao,
    'barulho_incomum, perca_potencia, !diagnostico(problema_interno_motor).',
    'Há barulhos incomuns e perda de potência, mas os diagnósticos de problema interno do motor foram descartados, sugerindo que a questão reside na transmissão do veículo.',
    'Verificar o nível e a qualidade do fluido da transmissão. Inspecionar a embreagem (se manual) ou os componentes internos da transmissão. Consultar um especialista em transmissão.'
) :-
    barulho_incomum,
    perca_potencia,
    \+ diagnostico(problema_interno_motor).

% --- Recomendações Simplificadas ---
recomendacao(bateria_fraca, 
    'A bateria está com carga insuficiente. Verifique os terminais quanto à oxidação, teste a voltagem com um multímetro e considere recarregá-la ou substituí-la.').

recomendacao(alternador_defeituoso, 
    'O alternador pode não estar recarregando a bateria corretamente. Verifique a correia quanto ao tensionamento e desgaste. Se necessário, substitua o alternador.').

recomendacao(sistema_arrefecimento, 
    'O sistema de arrefecimento pode estar comprometido. Cheque o radiador, bomba d\'água, ventoinha e o nível do fluido. Procure por vazamentos ou sinais de superaquecimento.').

recomendacao(baixo_nivel_oleo, 
    'Possível vazamento ou manutenção atrasada. Verifique o nível de óleo com a vareta e procure por manchas no solo. Faça a troca se necessário.').

recomendacao(sensor_oxigenio_defetuoso, 
    'O sensor de oxigênio pode estar com defeito, afetando o consumo e as emissões. Recomenda-se escanear com ferramenta OBD e substituir o sensor, se necessário.').

recomendacao(problema_injecao, 
    'Falhas no sistema de injeção. Verifique os bicos injetores, pressão da bomba de combustível e sensores associados.').

recomendacao(problema_interno_motor, 
    'Há indícios de falhas internas no motor, como desgaste de pistões ou válvulas. É recomendável realizar testes de compressão e análise mecânica detalhada.').

recomendacao(problema_transmissao, 
    'Problemas na transmissão. Verifique o nível e estado do fluido e procure assistência especializada se houver dificuldade nas trocas de marcha ou ruídos.').

/*
* --- Procedimento Principal de Diagnóstico ---
* Orquestra todo o processo: busca diagnósticos, verifica se
* encontrou algo e chama as rotinas para exibir os resultados
* de forma organizada.
*/

diagnosticar :-
    findall(Causa, diagnostico(Causa), ListaCausas),
    (   ListaCausas \= []
    ->  format('Possiveis problemas diagnosticados: ~w~n',[ListaCausas]),
        listar_recomendacoes(ListaCausas),
    findall(
            (Causa, Regras, J, A),
            (member(Causa, ListaCausas), diagnostico_explicado(Causa, Regras, J, A)),
            ListaExplicacoes
        ),
        lista_diagnostico_explicado(ListaExplicacoes)
    ;   write('Nenhum problema foi diagnosticado com as informacoes atuais.'), nl
    ).


% --- Procedimentos de Exibição ---
% Imprime as listas de explicações e recomendações.
lista_diagnostico_explicado([]).
lista_diagnostico_explicado([(Causa, Regras, Justificativa, Acoes)|Resto]) :-
    format('~nProblema Diagnosticado: ~w~n', [Causa]),
    format('  - Regras Ativadas: ~w~n', [Regras]),
    format('  - Justificativa: ~w~n', [Justificativa]),
    format('  - Ações Corretivas Propostas: ~w~n', [Acoes]),
    lista_diagnostico_explicado(Resto).

listar_recomendacoes([]).
listar_recomendacoes([Causa|Resto]) :-
    recomendacao(Causa, Rec),
    format(' -> Para ~w, recomenda-se: ~w~n', [Causa, Rec]),
    listar_recomendacoes(Resto).

caso_teste_exemplo:-  
write('=== Caso de Teste 5: Bateria Fraca ou Alternador com Falha ==='), nl, limpar_estado, 
assertz(falha_ignicao),  
assertz(luz_bateria),  
assertz(bateria(12.5)),  
diagnosticar,  
limpar_estado. 


/*
* ==============================================================================
* CASOS DE TESTE
* ==============================================================================
* Cenários pré-definidos para validar a lógica do sistema.
* Aqui, comentários multi-linha são úteis para detalhar cada caso.
* ==============================================================================
*/

/* --- Caso de Teste 1: Bateria Fraca ---
* Objetivo: Validar a regra 'bateria_fraca'.
* Cenário: Falha ao ligar, luz da bateria acesa, voltagem baixa.
* Esperado: 'bateria_fraca'.
*/
caso_teste_1_partida_inconsistente :-
   write('~n=== Caso de Teste 1: Partida Inconsistente (Bateria Fraca) ===~n'),
   limpar_estado,
   assertz(falha_ignicao),  % Sintoma 1
   assertz(luz_bateria),    % Sintoma 2
   assertz(bateria(11.8)),  % Sintoma 3
   diagnosticar,
   limpar_estado.

/* --- Caso de Teste 2: Superaquecimento ---
* Objetivo: Validar 'sistema_superaquecimento' (com óleo OK).
* Cenário: Motor quente, 'Check Engine' acesa, óleo OK.
* Esperado: 'sistema_superaquecimento'.
*/
caso_teste_2_superaquecimento :-
   write('~n=== Caso de Teste 2: Superaquecimento no Motor ===~n'),
   limpar_estado,
   assertz(temperatura_motor(105)), % Sintoma 1
   assertz(nivel_oleo(1.1)),        % Condição (Óleo OK)
   assertz(luz_check_engine),       % Sintoma 2
   diagnosticar,
   limpar_estado.

/* --- Caso de Teste 3: Sensor O2 ---
* Objetivo: Validar 'sensor_oxigenio_defeituoso'.
* Cenário: Rotação alta, RPM alto, 'Check Engine', O2 alto.
* Esperado: 'sensor_oxigenio_defeituoso'.
*/
caso_teste_3_motor_engasgado_altas_rotacoes :-
   write('~n=== Caso de Teste 3: Motor Engasgado (Sensor O2) ===~n'),
   limpar_estado,
   assertz(rotacao_alta),         % Sintoma 1
   assertz(rpm(3500)),            % Sintoma 2
   assertz(luz_check_engine),     % Sintoma 3
   assertz(sensor_oxigenio(0.9)), % Sintoma 4
   diagnosticar,
   limpar_estado.

/* --- Caso de Teste 4: Motor Interno ---
* Objetivo: Validar 'problema_interno_motor' (sem luzes).
* Cenário: Barulho, perda de potência, SEM luzes, temp OK.
* Esperado: 'problema_interno_motor'.
*/
caso_teste_4_ruidos_ao_acelerar :-
   write('~n=== Caso de Teste 4: Ruídos no Motor (Interno) ===~n'),
   limpar_estado,
   assertz(barulho_incomum), % Sintoma 1
   assertz(rotacao),         % Condição
   assertz(perca_potencia),  % Sintoma 2
   diagnosticar,
   limpar_estado.

/* --- Caso de Teste 5: Diagnóstico Múltiplo ---
* Objetivo: Validar identificação de múltiplos problemas.
* Cenário: Luz bateria (bateria OK) + Motor quente ('Check Engine', óleo OK).
* Esperado: 'alternador_defeituoso' E 'sistema_superaquecimento'.
*/
caso_teste_5_conflito_bateria_aquecimento :-
   write('~n=== Caso de Teste 5: Conflito Bateria/Aquecimento (Múltiplo) ===~n'),
   limpar_estado,
   assertz(luz_bateria),            % Sintoma 1a
   assertz(bateria(12.5)),          % Condição 1a
   assertz(temperatura_motor(105)),   % Sintoma 2a
   assertz(luz_check_engine),       % Sintoma 2b
   assertz(nivel_oleo(1.0)),        % Condição 2a
   diagnosticar,
   limpar_estado.


/* --- Caso de Teste 6: Velas de Ignição ---
* Objetivo: Validar 'vela_ignicao_defeituosa' (bateria OK).
* Cenário: Falha ao ligar, perda de potência, bateria OK, SEM luz bateria.
* Esperado: 'vela_ignicao_defeituosa'.
*/
caso_teste_6_velas_ignicao :-
   write('~n=== Caso de Teste 6: Falha na Ignição (Velas) ===~n'),
   limpar_estado,
   assertz(falha_ignicao),  % Sintoma 1
   assertz(perca_potencia), % Sintoma 2
   assertz(bateria(12.6)),  % Condição (Bateria OK)
   diagnosticar,
   limpar_estado.

/*
* --- Limpeza de Estado ---
* Essencial para os testes: remove todos os fatos dinâmicos
* para garantir que um teste não interfira no próximo.
*/

limpar_estado :-
    retractall(bateria(_)),
    retractall(temperatura_motor(_)),
    retractall(nivel_oleo(_)),
    retractall(sensor_oxigenio(_)),
    retractall(luz_check_engine),
    retractall(luz_bateria),
    retractall(falha_ignicao),
    retractall(barulho_incomum),
    retractall(rotacao),
    retractall(perca_potencia),
    retractall(rotacao_alta),
    retractall(rpm(_)),
    retractall(rotacao_alta).


% --- Ponto de Entrada Principal ---
% Roda todos os casos de teste. Execute `?- main.`
main :-
   write('=== Iniciando Execução dos Casos de Teste ==='), nl,
   caso_teste_1_partida_inconsistente,
   caso_teste_2_superaquecimento,
   caso_teste_3_motor_engasgado_altas_rotacoes,
   caso_teste_4_ruidos_ao_acelerar,
   caso_teste_5_conflito_bateria_aquecimento,
   caso_teste_6_velas_ignicao,
   write('~n~n=== Fim da Execução ===~n').
