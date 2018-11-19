;programmer:Li Pan
;

;;; Directives
            PRESERVE8
            THUMB       

        		 
;;; Equates

INITIAL_MSP	EQU		0x20001000	; Initial Main Stack Pointer Value


;The onboard LEDS are on port C bits 8 and 9
;PORT C GPIO - Base Addr: 0x40011000
GPIOC_CRL	EQU		0x40011000	; (0x00) Port Configuration Register for Px7 -> Px0
RCC_APB2ENR	EQU		0x40021018	; APB2 Peripheral Clock Enable Register


; Times for delay routines
;make the delay time smaller
DELAYTIME	EQU		160000		; (200 ms/24MHz PLL)



; Vector Table Mapped to Address 0 at Reset
            AREA    RESET, Data, READONLY
            EXPORT  __Vectors

__Vectors	DCD		INITIAL_MSP			; stack pointer value when stack is empty
        	DCD		Reset_Handler		; reset vector
			
            AREA    MYCODE, CODE, READONLY
			EXPORT	Reset_Handler
			ENTRY

Reset_Handler		PROC

		BL GPIO_ClockInit
		BL GPIO_init
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;phase1 turn on the LED4 which is PC8
		ldr r0,=0x4001100c		;load GPIOx_ODR to change the state of our output I/O pins of PORT C
		ldr r1,[r0]				;load r0 to r1
		orr r1,r1,#0x100		;turn on port C 8
		str r1,[r0]				
		
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;phase2 switch LED with time range of DELAYTIME
;initial r5 with#0x0 increase until r5 reach r4(DELAYTIME) then switch LED light
		LDR r4,=DELAYTIME
		mov r5,#0x0
mainLoop
		ldr r0,=0x40010808		;PORT A  GPIOx_CRH
		ldr r1,[r0]
		and r1,#0x1				;left the LSB bit
		cmp r1,#0x1				;check the LSB bit is 1 or not
		beq turn_on				;if the LSB is 1 means the LED is on
		
		add r5,r5,#0x1			;increas R5 1 for each time
		cmp r5,r4				;compare until R5 reach the DELAYTIME 
		BNE mainLoop
		
;;switch between the two LED 		
tog
		ldr r0,=0x4001100c		;GPIO PORT C check GPIOx_ODR
		mov r5,#0x0
		ldr r1,[r0]
		eor r1,r1,#0x300		; 01 XOR 11 becomes 10 ; 10 XOR 11 becomes 01
		str r1,[r0]
		

		B	mainLoop
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;phase3 check the status if the status is in on, turn the light on , else turn the led off

switchLoop
		ldr r0,=0x40010808		;GPIO PORT A  GPIOx_IDR
		ldr r1,[r0]
		and r1,#0x1				
		cmp r1,#0x1				;check the status
		beq turn_on
		bne turn_off
		
turn_on
		ldr r0,=0x4001100c
		ldr r1,[r0]
		orr r1,r1,#0x300		;output mode MODE 11
		str r1,[r0]
		b switchLoop

turn_off
		ldr r0,=0x4001100c
		ldr r1,[r0]
		and r1,r1,#0x0
		str r1,[r0]
		b switchLoop
		

		ENDP



	ALIGN
;;;;;;;;Subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine will enable the clock for the Ports that you need	
;turn on the clock for PORT A and PORT C
;for RCC_APB2ENR IOPCEN bit4 and IOPAEN bit 2 : XX10100
;


GPIO_ClockInit PROC
	ldr r0,=0x40021018		;clock enable register RCC_APB2ENR
	ldr r1,[r0]				;load the register 
	orr r1,r1,#0x14			;turn on the clock for PORT A and PORT A
	str r1,[r0]				;store the r1 back to r0


	

	BX LR
	ENDP
		
		
	ALIGN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This routine enables the GPIO for the LEDs
;enable register (RCC_APB2ENR)
;For PORT C pin8 and 9(PC8 and PC9 )
; general output push-pull CNF:00 and 50 HZ MODE:11 ;
GPIO_init  PROC
	ldr r6,=0x40011004			;PORT C GPIOx_CRH
	ldr r0,[r6]
	and r0,r0,#0xffffff00		;cleaning the last byte
	orr r0,r0,#0x00000033		;enable the port 9 (0011)and port8 (0011)
	str r0,[r6]

;;PIN0 : CNF bits to float input: 01 and  MODE bits to input: 00	
	ldr r6,=0x40010800			;PORT A  GPIOx_CRL
	ldr r0,[r6]					
	and r0,r0,#0xfffffff0		;clean the last half byte
	orr r0,r0,#0x00000004		;enable the pin 0(0100)
	str r0,[r6]


	BX LR
	ENDP




	ALIGN


	END
