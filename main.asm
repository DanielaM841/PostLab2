;
; Created: 19/02/2025 18:14:52
; Author : Daniela Alexandra Moreira Cruz 23841
;Descripcion: implementacion de un led de 7 segmentos para un contador de 4 bits
;
// Encabezado 
.include "M328PDEF.inc" 
.cseg
.org 0x0000
.def COUNTER = R20
// Configuracion de la pila
LDI		 R16, LOW(RAMEND)
OUT		 SPL, R16
LDI		 R16, HIGH(RAMEND)
OUT		 SPH, R16
RJMP	SETUP			//Salto al SETUP
.org PCI2addr
    RJMP	PCINT1_ISR      //Vector de interrupción por cambio de pin en PC

// Configuracion MCU
SETUP:
//Variables
	;R18 es para el valor de la tabla del display (puntero) 
	;R21 es para el valor del contador para el of y uf del display
	;R20 es el valor del contador del timer para los ciclos 
	;R17 valor para comparción del estado del botón 
	;R19 valor para guardar el contador de 4 bits 
// Configurar Prescaler 
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16 // Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16 // Configurar Prescaler en 1MHz
	// Inicializar timer0
    CALL    INIT_TMR0
	// Puerto el bit 5 del puerto B como salidas
	// Configurar PB5 como salida para usarlo como "LED"
	LDI		R16, 0xFF
	OUT		DDRB, R16 // Puerto B como salida
	LDI		R16, 0x00
	OUT		PORTB, R16 //El puerto B conduce cero logico.
	// Deshabilitar serial 
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

	//Habilitar las interrupciones para el antirebote. 
	LDI		R16,	0x02			
	STS		PCICR,	R16				//pin change en el pin C
	LDI		R16,	(1<<PCINT10) | (1<<PCINT11)	//Habilitar pin 0 y pin 1
	STS		PCMSK1,	R16				//	Cargar a PCMSK1

	SEI 

// Loop Infinito
MAIN:
	
	//Timer para leds cambien 
	IN		R16, TIFR0 // Leer registro de interrupcion 
	SBRS	R16, TOV0 // Salta si el bit 0 esta en 1, es la bandera de of
	RJMP	MAIN // Reiniciar loop si no hay of
	SBI		TIFR0, TOV0 // Limpiar bandera de "overflow"
	LDI		R16, 100
	OUT		TCNT0, R16 // Volver a cargar valor inicial en TCNT0
	INC		COUNTER
	CPI		COUNTER, 100 // R20 = 10 después 1s (el TCNT0 está en to 10 ms)
	BRNE	MAIN
	CLR		COUNTER
	CPI		R19, R21
	INC     R19
	CPI		R19, 0x10 //comparar con 16
	BREQ	OF1 //Si el valor es igual al contador del display reiniciar 
	INC		R19 //si no es igual seguir contando 
	OUT		PORTB, R19 //si no es 16 cargar el valor 
	RJMP	MAIN
OF1:
	ANDI	R19, 0b10000 //Dejar solo el bit 4 y borrar lo demás 
	SBRS	R19, 4 //si el bit 4 esta encendido saltar, no hay necesidad de encender  
	RJMP	ASET
	SBRC	R19, 4	//Salta si el 4 bit está apagado, al saltar y hacer de nuevo va a encender
	RJMP	AOFF		
	RJMP	MAIN
ASET:
	LDI		R19, 0b10000 //Encender el bit 4 del port B
	ADD		


//Subrutinas para anti rebote 
PCINT1_ISR:
	ANDI	R19, 0x10				//Borrar los 4 bits menos significativos
	OUT		PORTB, R19
	IN		R17, PINC				//Leer el estado de los botones
	SBRS	R17, 2					//Verificar si el bit 2 esta en 1
	CALL	SUMA				//sumar el display
	SBRS	R17, 3					//Verificar si el bit 2 esta en 1
	CALL	RESTA				//restar el display
	OUT		PORTD, R18		   
	RETI
SUMA: 
	INC		R21
	CPI		R21, 0x10
	BREQ	OF2
	ADIW	Z,1
	LPM		R18,Z 
	RET
RESTA: 
	CPI		R21, 0x00
	BREQ	UF2 // si es 0 ir a under flow 
	DEC		R21
	SBIW	Z,1
	LPM		R18,Z 
	RET
OF2:
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
// NON-Interrupt subroutines
INIT_TMR0:
	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16 // Setear prescaler del TIMER 0 a 64
	LDI		R16, 100
	OUT		TCNT0, R16 // Cargar valor inicial en TCNT0
	RET
//Tabla para 7 segmentos 
TABLA: .DB 0x77, 0x06, 0xB3, 0x97, 0xC6, 0xD5, 0xF5, 0x07, 0xF7, 0xD7, 0xE7, 0xF4, 0x71, 0xB6, 0xF1, 0xE1