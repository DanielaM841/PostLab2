;
; Created: 19/02/2025 18:14:52
; Author : Daniela Alexandra Moreira Cruz 23841
;Descripcion: implementacion de un led de 7 segmentos para un contador de 4 bits
;
// Encabezado 
.include "M328PDEF.inc" 
.dseg
.org	SRAM_START
.cseg
.org 0x0000

// Configuracion de la pila
LDI		 R16, LOW(RAMEND)
OUT		 SPL, R16
LDI		 R16, HIGH(RAMEND)
OUT		 SPH, R16
// Configuracion MCU
SETUP:
	//Configurar los pines 

	 //Puerto C como entrada
	LDI		R16, 0x00
	OUT		DDRC, R16
	LDI		R16, 0xFF
	OUT		PORTC, R16		//Pull-up

	//Puerto B como salida
	LDI		R16, 0xFF
	OUT		DDRB, R16		// Puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16		//El puerto B conduce cero logico.

	//Puerto D como salida
	LDI R16, 0xFF
	OUT DDRD, R16  ; Configura PORTD como salida
	LDI R16, 0x00
	OUT PORTD, R16  ; Inicializa en 0		
	// Deshabilitar serial 
	LDI		R16, 0x00
	STS		UCSR0B, R16
	LDI		R17, 0x7F //Estado de los botones

	//Salidas
	LDI		R18, 0x00		//Contador de 4 bit
	LDI		R21, 0x00 //contador of y uf 
	
	//Cargar la tabla como salida
	LDI		ZH, HIGH(TABLA<<1)  //Carga la parte alta de la dirección de tabla en el registro ZH
	LDI		ZL, LOW(TABLA<<1)	//Carga la parte baja de la dirección de la tabla en el registro ZL
	LPM		R18, Z			    //Carga en R16 el valor de la tabla en ela dirreción Z
	OUT		PORTD, R18		   //Muestra en el puerto D el valor leido de la tabla
// Loop Infinito
MAIN:
	IN		R16, PINC // Guardando el estado de PORTC en R16 0xFF
	CP		R17, R16 // Comparamos estado "viejo" con estado "nuevo"
	BREQ	MAIN
	CALL	DELAY
	IN		R16, PINC
	CP		R17, R16
	BREQ	MAIN
	// Volver a leer PIND
	MOV		R17, R16 //copia el estado actual del pin en R17
	SBRS	R16, 2 // Salta si el bit 2 del PIND es 1 (no apachado)
	CALL	SUMA //si el botón esta presionado suma
	SBRS	R16, 3 //Si el bit 3 de PIND es 1 (botón NO presionado), salta la siguiente instrucción
	CALL	RESTA // Si el boton 2 está presionado, llama a RESTA
	OUT		PORTD, R18
	RJMP	MAIN
SUMA: 
	INC		R21
	CPI		R21, 0x10
	BREQ	OF1
	ADIW	Z,1
	LPM		R18,Z 
	RET
RESTA: 
	CPI		R21, 0x00
	BREQ	UF2 // si es 0 ir a under flow 
	DEC		R18
	DEC		R21
	SBIW	Z,1
	LPM		R18,Z 
	RET
OF1:
	LDI		ZH, HIGH(TABLA<<1)  //Posicionarse nuevamente en la primera posición  
	LDI		ZL, LOW(TABLA<<1)	
	
	LPM		R18, Z			   
	OUT		PORTD, R18		   
	LDI		R21,	0x00
	RET

UF2:
	LDI		ZH, HIGH(TABLA<<1) //Posicionarse en la útima posición 
	LDI		ZL, LOW(TABLA<<1)
	ADIW	Z, 15	
	LPM		R18, Z			   
	OUT		PORTD, R18		   
	LDI		R21,	0x0F
	RET
// Sub-rutina 
DELAY:
	LDI		R19, 0xFF
SUB_DELAY1:
	DEC		R19
	CPI		R19, 0
	BRNE	SUB_DELAY1
	LDI		R19, 0xFF
SUB_DELAY2:
	DEC		R19
	CPI		R19, 0
	BRNE	SUB_DELAY2
	LDI		R19, 0xFF
SUB_DELAY3:
	DEC		R19
	CPI		R19, 0
	BRNE	SUB_DELAY3
	RET

//Tabla para 7 segmentos 
TABLA: .DB 0x77, 0x06, 0xB3, 0x97, 0xC6, 0xD5, 0xF5, 0x07, 0xF7, 0xD7, 0xE7, 0xF4, 0x71, 0xB6, 0xF1, 0xE1