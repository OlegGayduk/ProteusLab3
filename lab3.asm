#include <P16F877A.INC>	

__CONFIG _WDT_OFF&_HS_OSC&_PWRTE_ON&_LVP_OFF
 COUNT_R  EQU 0x21
 OUT_R     EQU 0X22
 Reg_1   EQU 0X23
 Reg_2   EQU 0X24
 OUT_L  EQU 0x25
 COUNT_L  EQU 0x26
 COUNT3  EQU 0x29
 COUNT_TMR1 EQU 0x27
 Reg_3   EQU 0X28
 OUT_ADD EQU 0x2A
ORG 0x0000
 GOTO INIT

ORG 0x0004
GOTO Interrupt_TIMER_TMR1
ORG 0x0005

INIT
 BCF STATUS,RP0
 BCF STATUS,RP1        ;инит
 BCF STATUS,IRP        ;инит
 MOVLW 0x9F
 MOVWF FSR             ;Адрес регистра ADCON1(тип PORTA)
 MOVLW 0x06            ;PORTA Digital
 MOVWF INDF           
 
 MOVLW 0X00
 MOVWF INTCON          ;инит
 CLRF PORTA
 CLRF PORTB
 CLRF PORTC
 CLRF PORTD
 CLRF PORTE
 MOVLW 0X85
 MOVWF FSR             ;указатель
 MOVLW 0X00 
 MOVWF INDF             ;TRISA выход
 MOVLW 0X86
 MOVWF FSR
 MOVLW 0X10
 MOVWF INDF          ;TRISB выход,RB4 вход
 MOVLW 0x87
 MOVWF FSR           ;TRISC
 MOVLW 0x00
 MOVWF INDF          ;TRISC выход
 MOVLW 0x88
 MOVWF FSR           ;TRISD
 MOVLW 0X00
 MOVWF INDF          ;TRISD выход
 MOVLW 0x89
 MOVWF FSR            ;TRISE
 MOVLW 0x00
 MOVWF INDF           ;TRISE выход

 ;MOVLW 0xC0
 ;MOVWF PORTC

INIT2
 CLRF COUNT_TMR1    ;инит доп.счетчика TMR1
 CLRF COUNT_R        ;инит счетчика 1
 CLRF COUNT_L        ;инит счетчика 2
 CLRF COUNT3        ;инит счетчика 3
 MOVLW 0X90        
 MOVWF OUT_R        ;правый индикатор в ноль
 MOVLW 0X10
 MOVWF OUT_L        ;левый индикатор в ноль
 Call INIT_TIMER_TMR1
 
MAIN                 
 CALL Delay_Main ;не слишком быстрый опрос кнопки
 BTFSC PORTB,4   ;проверяем нажатие кнопкм RB4
 GOTO MAIN
 CALL Delay_RB4  ;дребезг контакта
 MOVF COUNT_R,0   ;пересылаем в W
 ADDWF COUNT_L,0  ;сложение счетчиков,результат в W
 MOVWF OUT_ADD   ;сохряняем результат сложения в OUT_ADD
 MOVLW 0x0A
 SUBWF OUT_ADD,0   ;вычитаем из результата сложения 10
 BTFSS STATUS,C  ;проверяем флаг переноса из старшего бита
 GOTO  Fun_sub   ;не было переноса
 GOTO  Fun_add   ;перенос
 GOTO MAIN

INIT_TIMER_TMR1 ;инитим таймер 1 значением прерывания на 62,5мс 
  MOVLW 0xC0
  MOVWF INTCON ;разрешаем прерывание,и немаскированные от периферийных модулей
  MOVLW 0x31
  MOVWF T1CON ;влючаем модуль TMR1,предделитель 1:8
  BCF  PIR1,TMR1IF;сброс флага переполнения таймера TMR1
  MOVLW 0x67   ;0x67  
  MOVWF TMR1H
  MOVLW 0x69   ;0x69 
  MOVWF TMR1L
  MOVLW 0x8C
  MOVWF FSR          ; указатель на регистр PIE1
  BSF INDF,TMR1IE    ;BSF   PIE1,TMR1IE вот как можно оказывается!!раз,прерывания TMR1
  RETURN
Interrupt_TIMER_TMR1 ;обработчик прерываний таймера 1
  BTFSS   PIR1,TMR1IF
  RETURN
  BCF  PIR1,TMR1IF  ;сброс флага прерывания TMR1,и перезарядка TMR1
  MOVLW 0xC0         
  MOVWF INTCON ;разрешаем прерывание,и немаскированные от периферийных модулей
  MOVLW 0x67 ;0x67  
  MOVWF TMR1H
  MOVLW 0x69   ;0x69  
  MOVWF TMR1L
  BTFSC COUNT3,0 ; счетчик 1 или о,какой индикатор будет зажигатся с частотой прерывания
  GOTO  Indicator_L
  GOTO  Indicator_R  
Compare
  BTFSC COUNT_TMR1,3 ;COUNT_TMR1,3 счет до 8 ,это 0,5 сек ,в режиме теста на 32 множим COUNT_TMR1,5
  GOTO  Compare_R       ;если 1 то 0,5 сек сосчитано
  INCF  COUNT_TMR1   ;инкремент счетчика TMR1
  RETURN
  
  
Compare_R
 CLRF COUNT_TMR1    ;обнуляем значение доп.счетчика TMR1
 INCF COUNT_R         ;инкремент значение цифры в правом индикаторе
 MOVLW 0xA           ;конечная цифра счета индикатора
 SUBWF COUNT_R,0      ;вычитаем из регистра рабочий регистр
 BTFSC STATUS,Z      ;проверяем результат операции вычитания,Z если 1
 GOTO Compare_L       ;переход на обработку левого индикатора
 GOTO DynamicIndication_R ;переход на функцию определения кода правого сем.индикатора 
 
 
Compare_L
 ClRF COUNT_R     ;обнуляем счетчик правого индикатора 
 MOVLW 0x90      ;костыль на ноль правого индикатора после 9 возможно считать до 11 надо
 MOVWF OUT_R
 INCF COUNT_L      ;устанавливаем значение левого индикатора
 MOVLW 0xA           ;конечная цифра счета индикатора
 SUBWF COUNT_L,0      ;вычитаем из регистра рабочий регистр
 BTFSC STATUS,Z      ;проверяем результат операции вычитания,Z если 1
 CLRF COUNT_L
 GOTO DynamicIndication_L ;переход на функцию определения кода левого сем.индикатора 
   

DynamicIndication_R ;аналог оператора swith-case си,определяем какой код подставить 
 MOVF COUNT_R,0         ;правому индикатору
 CALL Mas_Ind_R
 MOVWF OUT_R
 RETURN

DynamicIndication_L ;аналог оператора swith-case си,определяем какой код подставить 
 MOVF COUNT_L,0         ;левому индикатору
 CALL Mas_Ind_L
 MOVWF OUT_L
 RETURN
  
Mas_Ind_R
 ADDWF PCL,F
 RETLW 0x90
 RETLW 0xDB
 RETLW 0x8C
 RETLW 0x89
 RETLW 0xC3
 RETLW 0xA1
 RETLW 0xA0
 RETLW 0x9B
 RETLW 0x80
 RETLW 0x81
 RETURN

Mas_Ind_L
 ADDWF PCL,F
 RETLW 0x10
 RETLW 0x5B
 RETLW 0x0C
 RETLW 0x09
 RETLW 0x43
 RETLW 0x21
 RETLW 0x20
 RETLW 0x1B
 RETLW 0x00
 RETLW 0x01
 RETURN

Indicator_L
  DECF COUNT3
  MOVF  OUT_L,0
  MOVWF PORTC
  GOTO Compare
Indicator_R
  INCF COUNT3
  MOVF OUT_R,0
  MOVWF PORTC
  GOTO Compare

Fun_add
  MOVWF COUNT_L   ;пересылаем в счетчик левого индикатора
  CALL DynamicIndication_L 
  GOTO MAIN

Fun_sub
 MOVF OUT_ADD,0 
 MOVWF COUNT_L
 CALL DynamicIndication_L
 GOTO MAIN
  
 Delay_RB4  ;50ms
 MOVLW       .169
 MOVWF       Reg_1
 MOVLW       .69
 MOVWF       Reg_2
 MOVLW       .2
 MOVWF       Reg_3
 DECFSZ      Reg_1,F
 GOTO        $-1
 DECFSZ      Reg_2,F
 GOTO        $-3
 DECFSZ      Reg_3,F
 GOTO        $-5
 NOP
 NOP

 RETURN

Delay_Main  ;200ms
        
 MOVLW       .173
 MOVWF       Reg_1
 MOVLW       .19
 MOVWF       Reg_2
 MOVLW       .6
 MOVWF       Reg_3
 DECFSZ      Reg_1,F
 GOTO        $-1
 DECFSZ      Reg_2,F
 GOTO        $-3
 DECFSZ      Reg_3,F
 GOTO        $-5
 NOP
 NOP

 RETURN

END
