# Controle de semáforo duplo com modo de manutenção usando o PIC18F45K22 em assembly

O objetivo deste projeto era desenvolver o controle de dois semáforos sincronizados usando o microcontrolador PIC18F45K22, com o programa escrito em linguagem Assembly. 

## Hardware

Tabela de componentes utilizado na montagem.



| Componente                  | Quantidade    | Função                                                   |     
|-----------------------------|---------------|----------------------------------------------------------|
| Microcontrolador PIC18F45K22| 1             | Unidade de controle do sistema                           |
| Protoboard                  | 2             | Base de montagem do circuito                             |
| LED vermelho 5mm            | 2             | Sinaleiras dos semáforos A e B                           |
| LED verde 5mm               | 2             | Sinaleiras dos semáforos A e B                           |
| LED amarelo 5mm             | 2             | Sinaleiras dos semáforos A e B                           |
| Cristal de 20MHz            | 1             | Fonte de clock externa                                   |
| Capacitor cerâmico de 22nF  | 2             | Capacitores de carga do cristal                          |
| Resistor de 10KΩ (5%)       | 3             | 1 no MCLR e 2 pull-up dos botões                         |
| Resistor de 330Ω (5%)       | 6             | Limitação de corrente dos LEDs                           |
| Chave táctil (push-button)  | 2             | Botões de manutenção e de reset                          |


\## Diagrama esquemático

!\[Diagrama esquemático](./midia/diagrama\_esquematico.svg)

### Em construção...

