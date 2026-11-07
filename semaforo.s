;===============================================================================
; SEMÁFORO COM MODO MANUTENÇÃO
;===============================================================================
; DESCRIÇÃO:
;   Controla dois semáforos (A e B) com três LEDs cada (vermelho, amarelo e
;   verde).
;
;     Estado 0 : Semáforo A verde     / Semáforo B vermelho   -> 10 s (20 ticks)
;     Estado 1 : Semáforo A amarelo   / Semáforo B vermelho   ->  5 s (10 ticks)
;     Estado 2 : Semáforo A vermelho  / Semáforo B verde      -> 10 s (20 ticks)
;     Estado 3 : Semáforo A vermelho  / Semáforo B amarelo    ->  5 s (10 ticks)
;     Estado 4 : MANUTENÇÃO - os 6 LEDs piscam a cada 0,5 s
;
;   Dois botões geram interrupção externa:
;     - Botão MANUTENÇÃO (INT0/RB0): entra no modo manutenção.
;     - Botão RESET (INT1/RB1): reinicia o sistema ao estado inicial (Estado 0)
;       por software, sem reiniciar o PIC.
;
;-------------------------------------------------------------------------------
; HARDWARE
;-------------------------------------------------------------------------------
;   MCU      : PIC18F45K22
;   Clock    : Cristal externo de 20 MHz
;
;-------------------------------------------------------------------------------
; MAPEAMENTO DE PINOS (PORTB)
;-------------------------------------------------------------------------------
;   SAÍDAS (LEDs) - RB2 a RB7:
;     RB7 : LED vermelho  - Semáforo A
;     RB6 : LED amarelo   - Semáforo A
;     RB5 : LED verde     - Semáforo A
;     RB4 : LED vermelho  - Semáforo B
;     RB3 : LED amarelo   - Semáforo B
;     RB2 : LED verde     - Semáforo B
;
;   ENTRADAS (botões) - RB0 e RB1:
;     RB0 : Botão MANUTENÇÃO (INT0) - ativo em borda de descida
;     RB1 : Botão RESET      (INT1) - ativo em borda de descida
;
;   TRISB = 0x03  (RB0, RB1 entrada ; RB2..RB7 saída)
;   ANSELB = 0x00 (todos os pinos do PORTB em modo digital)
;
;-------------------------------------------------------------------------------
; BOTÕES / RESISTORES
;-------------------------------------------------------------------------------
;   Configuração ACTIVE-LOW com resistores de PULL-UP EXTERNOS (10k):
;     - Resistor de 10K entre o pino e +5 V
;     - Botão entre o pino e o GND
;     - Pino solto = nível ALTO (1) ; pino pressionado = nível BAIXO (0)
;
;-------------------------------------------------------------------------------
; TOOLCHAIN : pic-as (MPLAB XC8)
;===============================================================================
					    
#include <xc.inc>			    ; Inclui definições de registradores/bits do PIC
  
CONFIG FOSC = HSHP			    ; Oscilador externo HS de alta potência (cristal > 16 MHz)
CONFIG PLLCFG = OFF			    ; PLL 4x OFF (20 MHz x4 = 80 MHz estouraria o limite de 64 MHz)
CONFIG PRICLKEN = ON			    ; Mantém o oscilador primário (cristal) sempre habilitado
CONFIG WDTEN = OFF			    ; Watchdog Timer desligado
CONFIG LVP = OFF			    ; Programação em baixa tensão desligada (libera o pino RB5/PGM como I/O)
    
cnt_9520	EQU 0x01		    ; Endereço para armazenar quantas vezes passou pelo TIMER0 (Ticks)
tick_9520	EQU 0x02		    ; Endereço para armazenar a comunicação entre o TIMER0 e o lacoPrincipal_9520
estado_9520	EQU 0x03		    ; Endereço para armazenar o ESTADO dos semáforos
					  
PSECT initVec, class=CODE, delta=1, abs	    ; Seção de código em endereço FIXO
ORG		0x0000			    ; Endereço onde o programa inicia
GOTO		principal_9520		    ; Direciona o programa para principal_9520

					    
PSECT intVec, class=CODE, delta=1, abs	    ; Seção de código em endereço FIXO para o vetor de interrupção
ORG		0x0008			    ; Endereço de interrupção de alta prioridade do PIC18F45K22
GOTO		interrupcao_9520	    ; Direciona o programa para interrupcao_9520
    
PSECT code, class=CODE, delta=1, reloc=2    ; Seção de código RELOCÁVEL para o programa principal    
principal_9520:				    ; Label onde é configurada as principais funções que seram utilizadas do PIC
    BANKSEL	ANSELB			    ; Seleciona o Banco que esta localizado ANSELB
    CLRF	ANSELB, b		    ; Desativa as funções analógicas
    BANKSEL	TRISB			    ; Seleciona o Banco que esta localizado TRISB
    MOVLW	0x03			    ; Carrega 0x03 no registrador W
    MOVWF	TRISB, c		    ; Move o valor de W para TRISB definindo os pinos RB0:1 como input
    BANKSEL	LATB			    ; Seleciona o Banco que esta localizado LATB
    CLRF	LATB, c			    ; Define as os pinos RB0:7 com nivel lógico BAIXO
    CLRF	cnt_9520, c	    	    ; Limpa o Byte de cnt_9520
    CLRF	estado_9520, c		    ; Limpa o Byte de estado_9520
    CLRF	tick_9520,c		    ; Limpa o Byte de tick_9520
    MOVLW	0x87			    ; Carrega 0x87 equivalente a 10000111B no registrador W
    MOVWF	T0CON, c		    ; Move o valor de W para o registrador T0CON ativando o TIMER0 com 16bits , T0PS razão do prescaler 111 (1:256)
    MOVLW	0xD9			    ; Carrega 0xD9 no registrador W
    MOVWF	TMR0H, c		    ; Carrega o primeiro resgistrador com parte do valor que sera utilizado no TIMER0
    MOVLW	0xDA			    ; Carrega 0xDA no registrador W
    MOVWF	TMR0L, c		    ; Carrega o segundo registrador do TIMER0(os dois formam  0xD9DA = 55770)
    BCF		INTCON, 2, c		    ; TMR0IF = 0 limpa o bit da flag de estouro do TIMER0
    BCF		INTCON2, 6, c		    ; INTEDG0 = 0 define a detecção do botão na borda de DESCIDA (botão manutenção)
    BCF		INTCON2, 5, c		    ; INTEDG1 = 0 define a detecção do botão na borda de DESCIDA (botão reset)
    BCF		INTCON, 1, c		    ; INT0IF = 0 limpa a flag gerada ao pressionar o boão de manutenção
    BCF		INTCON3, 0, c		    ; INT1IF = 0 limpa a flag gerada ao pressionar o boão de reset
    BSF		INTCON, 4, c		    ; INT0IE = 1 habilita a interrupção INT0 na PORTB 0 (botão manutenção)
    BSF		INTCON3, 3, c		    ; INT1IE = 1 habilita a interrupção INT1 na PORTB 1 (botão reset)
    BSF		INTCON, 5, c		    ; TMR0IE = 1 habilita interrupção do Timer0
    BSF		INTCON, 7, c		    ; GIE = 1  habilita interrupções globais
    MOVLW	0x30			    ; Carrega 0x30 no registrador W
    MOVWF	LATB, c			    ; Move o valor de W para LATB iniciando com A: verde e B: Vermelho
   
lacoPrincipal_9520:			    ; Laço principal onde esta toda a lógica 
    BTFSS	tick_9520, 0, c		    ; Verifica se passou 0,5s 
    GOTO	lacoPrincipal_9520	    ; Volta paro o inicio de lacoPrincipal_9520
    CLRF	tick_9520, c		    ; Limpa o Byte de tick_9520
    MOVF	estado_9520, W, c	    ; carrega o valor do estado_9520 em W
    XORLW	0x04			    ; Verifica se W é igual  XOR 4  (zero se estado_9520 == 4)
    BTFSC	STATUS, 2, c		    ; Verifica a flag Z do registrador STATUS (se W == 4 z == 1)
    GOTO	manutencao_9520		    ; Se for igual a 1 direciona o programa para manutencao_9520
    INCF	cnt_9520, F, c		    ; Incrementa em 1 o valor de cnt_9520 e armazena novamente em cnt_9520
    CALL	duracao_9520		    ; Direciona o programa para duracao_9520 para definir qual a duração do estado
    CPFSLT	cnt_9520, c		    ; Compara o valor de W com cnt_9520 se for menor pula a próxima instrução
    GOTO	testeEstados_9520	    ; Direciona o programa para testeEstados_9520 para definir qual é o próximo estado
    GOTO	lacoPrincipal_9520	    ; Reinicia o laço
     
interrupcao_9520:			    ; Label para tratar interrupções geradas pelo TIMER0
    BTFSS	INTCON, 2, c		    ; TMR0IF - Verifica se a interrupção foi gerada pelo TIMER0
    GOTO	interrupcaoManutencao_9520  ; Direciona para interrupcaoManutencao_9520
    MOVLW	0xD9			    ; Carrega 0xD9 no registrador W
    MOVWF	TMR0H, c		    ; Carrega o primeiro resgistrador com parte do valor que sera utilizado no TIMER0
    MOVLW	0xDA			    ; Carrega 0xDA no registrador W
    MOVWF	TMR0L, c		    ; Carrega o segundo registrador do TIMER0(os dois formam  0xD9DA = 55770)
    BCF		INTCON, 2, c		    ; TMR0IF - Limpa o bit de interrupção gerado pelo TIMER0
    BSF		tick_9520, 0, c		    ; Registra ter passado 0,5s em tick_9520 no bit 0
    RETFIE 1				    ; Retorna restaurando W/STATUS/BSR e religando GIE

interrupcaoManutencao_9520:		    ; Label para tratar interrupções geradas pelo INT0 (botão de manutenção)
    BTFSS	INTCON, 1, c		    ; INT0IF - Verifica se a interrupção foi gerada pelo INT0
    GOTO	interrupcaoReset_9520	    ; Direciona para interrupcaoReset_9520
    MOVLW	0x04			    ; Carrega 0x04 no registrador W
    MOVWF	estado_9520, c		    ; Move o valor de W para estado_9520 definindo o ESTADO como 4 (MODO MANUTENÇÃO)
    BCF		INTCON, 4, c		    ; INT0IE = 0 Desabilita a interrupção pelo INT0
    BCF		INTCON, 1, c		    ; INT0IF = 0 limpa a flag gerada ao pressionar o boão de manutenção
    MOVLW	0xFC			    ; Carrega 0xFC no registrador W
    MOVWF	LATB, c			    ; Move o valor de W para LATB acendendo os 6 LEDs
    RETFIE 1				    ; Retorna restaurando W/STATUS/BSR e religando GIE
    
interrupcaoReset_9520:			    ; Label para tratar interrupções geradas pelo INT1 (botão de reset)
    BTFSS	INTCON3, 0, c		    ; INT1IF - Verifica se a interrupção foi gerada pelo INT1
    RETFIE 1				    ; Retorna restaurando W/STATUS/BSR e religando GIE
    MOVLW	0xD9			    ; Carrega 0xD9 no registrador W
    MOVWF	TMR0H, c		    ; Carrega o primeiro resgistrador com parte do valor que sera utilizado no TIMER0
    MOVLW	0xDA			    ; Carrega 0xDA no registrador W
    MOVWF	TMR0L, c		    ; Carrega o segundo registrador do TIMER0(os dois formam  0xD9DA = 55770)
    BCF		INTCON, 1, c		    ; INT0IF = 0 limpa a flag gerada ao pressionar o boão de manutenção
    BSF		INTCON, 4, c		    ; INT0IE = 1 habilita a interrupção INT0 na PORTB 0 (botão manutenção)
    CLRF	LATB, c			    ; Define as os pinos RB0:7 com nivel lógico BAIXO
    CLRF	cnt_9520, c	    	    ; Limpa o Byte de cnt_9520
    CLRF	estado_9520, c		    ; Limpa o Byte de estado_9520
    CLRF	tick_9520,c		    ; Limpa o Byte de tick_9520
    MOVLW	0x30			    ; Carrega 0x30 no registrador W
    MOVWF	LATB, c			    ; Move o valor de W para LATB iniciando com A: verde e B: Vermelho
    BCF		INTCON3, 0, c		    ; INT1IF = 0 limpa a flag gerada ao pressionar o boão de reset
    RETFIE 1				    ; Retorna restaurando W/STATUS/BSR e religando GIE
    
manutencao_9520:			    ; Label que inverte os 6 ultimos bits de LATB
    MOVF	LATB, W, c		    ; Carrega W com o estado atual do LATB
    XORLW	0xFC			    ; Inverte os bits de W
    MOVWF	LATB, c			    ; Move o valor de W para LATB
    GOTO	lacoPrincipal_9520	    ; Retorna para lacoPrincipal_9520
    
testeEstados_9520:			    ; Label que direciona para o proximo estado
    INCF	estado_9520, F, c	    ; Incrementa em 1 o valor do estado_9520 e armazena novamente em estado_9520
    CLRF	cnt_9520, c		    ; Limpa o byte de cnt
    MOVF	estado_9520, W, c	    ; carrega o valor do estado_9520 em W
    XORLW	0x04			    ; Compara se W é igual estado_9520 XOR 4
    BTFSC	STATUS, 2, c		    ; Verifica a flag Z do registrador STATUS (se W == 4 z == 1)
    CLRF	estado_9520, c		    ; Limpa o byte estado_9520 reiniciando o estado
    BTFSC	estado_9520, 1, c	    ; Verifica se o bit 1 == 1
    GOTO	testeEstados_B_9520	    ; Direciona o programa para testeEstados_B_9520
    
testeEstados_A_9520:			    ; Label para verificar o bit 0 do estado_9520
    BTFSS	estado_9520, 0, c	    ; Verifica se o bit 0 == 0
    GOTO	trataEstado0_9520	    ; Direciona o programa para trataEstado0_9520
    GOTO	trataEstado1_9520	    ; Direciona o programa para trataEstado1_9520
    
testeEstados_B_9520:			    ; Label para verificar o bit 0 do estado_9520
    BTFSS	estado_9520, 0, c	    ; Verifica se o bit 0 == 0
    GOTO	trataEstado2_9520	    ; Direciona o programa para trataEstado2_9520
    GOTO	trataEstado3_9520	    ; Direciona o programa para trataEstado3_9520
    
trataEstado0_9520:			    ; Label para tratar o ESTADO 0 
    MOVLW	0x30			    ; Carrega 0x30 no registrador W
    MOVWF	LATB, c			    ; Move o valor de W para LATB A: verde e B: Vermelho
    GOTO	lacoPrincipal_9520	    ; Direciona o programa para lacoPrincipal_9520
    
trataEstado1_9520:			    ; Label para tratar o ESTADO 1
    MOVLW	0x50			    ; Carrega 0x50 no registrador W
    MOVWF	LATB, c			    ; Move o valor de W para LATB A: amarelo e B: Vermelho
    GOTO	lacoPrincipal_9520	    ; Direciona o programa para lacoPrincipal_9520
   
trataEstado2_9520:			    ; Label para tratar o ESTADO 2 
    MOVLW	0x84			    ; Carrega 0x84 no registrador W
    MOVWF	LATB, c			    ; Move o valor de W para LATB A: vermelho e B: verde
    GOTO	lacoPrincipal_9520	    ; Direciona o programa para lacoPrincipal_9520
    
trataEstado3_9520:			    ; Label para tratar o ESTADO 3 
    MOVLW	0x88			    ; Carrega 0x88 no registrador W
    MOVWF	LATB, c			    ; Move o valor de W para LATB A: vermelho e B: amarelo
    GOTO	lacoPrincipal_9520	    ; Direciona o programa para lacoPrincipal_9520
    
duracao_9520:				    ; Label para definir qual a duração do estado
    BTFSS	estado_9520, 0, c	    ; Verifica se o bit 0 é igual a 0 que seria um ESTADO PAR
    GOTO	dur_par_9520		    ; Direciona para dur_par_9520
    
dur_impar_9520:				    ; Label de duração para ESTADOS IMPAR
    MOVLW	0x0A			    ; Carrega 0x0A no registrador W equivalente a 10 TICKS de 0,5s totalizando em 5s
    RETURN				    ; Retorna para a ultima chama com CALL
    
dur_par_9520:				    ; Label de duração para ESTADOS PAR
    MOVLW	0x14			    ; Carrega 0x14 no registrador W equivalente a 20 TICKS de 0,5s totalizando em 10s
    RETURN				    ; Retorna para a ultima chama com CALL

END principal_9520			    ; Fim do código; principal_9520 é o ponto de entrada do programa
   
