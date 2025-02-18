

                ACIA_CTRL = ACIA_PORT+0
                ACIA_DATA = ACIA_PORT+1

                ACIA_TDRE =  %00000010
                ACIA_DIV16 = %00000001
                ACIA_RESET = %00000011
                ACIA_8N1  = %00010100
                ACIA_RIE = %10000000

                ACIA_NOT_RTS = %01000000

                ACIA_CONFIG = ACIA_DIV16 | ACIA_8N1 | ACIA_RIE


                ACIA_RING = acia_buff   ; address of the ring buffer
                ACIA_HEAD = $fe	        ; address of the head index pointer
                ACIA_TAIL = $ff		; address of the tail index pointer
		ACIA_RING_SIZE = $0100          ; changing this alone won't be sufficient
                ACIA_HIGH_WATER = ACIA_RING_SIZE - 16
                ACIA_LOW_WATER = 8


;-----------------------------------------------------------------------
; acia_init:
; Initializes the ACIA hardware and ring buffer.
;
acia_init:	
		stz ACIA_HEAD
		stz ACIA_TAIL
		
                ; initialize the ACIA hardware
		lda #ACIA_RESET
		sta ACIA_CTRL
		lda #ACIA_CONFIG
		sta ACIA_CTRL

		rts


;-----------------------------------------------------------------------
; acia_shutdown:
; Resets the ACIA hardware.
;
acia_shutdown:
		lda #ACIA_RESET
		sta ACIA_CTRL
                rts


;-----------------------------------------------------------------------
; acia_putc:
; Writes a character to the console serial port.
;
; On entry:
;       A = the character to send
;
acia_putc:
                pha                     ; save the character to send
_await_tdre:
                lda ACIA_CTRL           ; fetch status register
                and #ACIA_TDRE          ; isolate TDRE flag
                beq _await_tdre         ; wait if TDRE flag not set
                pla                     ; recover character to send
                sta ACIA_DATA           ; write the character
                rts


;-----------------------------------------------------------------------
; acia_getc:
; Reads the next input character from the console serial port if one
; is available.
;
; On return:
;       carry set => A is the next input character
;       carry clear => no character is available (A clobbered)
;
acia_getc:        
                sei                     ; disable interrupts
                lda ACIA_HEAD           ; get head index
                cmp ACIA_TAIL           ; compare to tail index
                bne _char_waiting       ; go if at least one character
                clc                     ; indicate none available
                cli                     ; enable interrupts
                rts
_char_waiting:
                phx
                tax                     ; X = head index
                lda ACIA_RING,x         ; fetch next character fron ring
                inx                     ; next head index
                stx ACIA_HEAD           ; store new head index
                plx
                pha                     ; preserve input character

                ; how many characters are in the ring?
                sec
                lda ACIA_TAIL
                sbc ACIA_HEAD

                cmp #ACIA_LOW_WATER     ; at the low water mark?
                bne _no_rts_change      ; nope

                ; assert RTS signal
                lda #(ACIA_CONFIG & ~ACIA_NOT_RTS)
                sta ACIA_CTRL
_no_rts_change:
                cli                     ; enable interrupts
                pla                     ; recover input character
                sec                     ; indicate character available
                rts

acia_kbhit:
                lda ACIA_TAIL
                cmp ACIA_HEAD           
                rts

;-----------------------------------------------------------------------
; acia_isr:
; Handle the interrupt request for the ACIA.
;

acia_isr:
                pha
_next_char:
                lda ACIA_CTRL           ; fetch status register
                ror                     ; shift RDRF flag into carry
                bcs _read_char          ; go if character waiting
                pla
                rti
_read_char:
                phx
                ldx ACIA_TAIL           ; fetch tail index for ring buffer
                lda ACIA_DATA           ; fetch the input character
                sta ACIA_RING,x         ; store input character in the ring
                inx                     ; next ring index
                stx ACIA_TAIL           ; store the new tail index
                plx

                ; how many characters are in the ring?
                sec
                lda ACIA_TAIL
                sbc ACIA_HEAD

                cmp #ACIA_HIGH_WATER    ; at the high water mark?
                bne _next_char          ; nope

                ; deassert RTS signal
                lda #(ACIA_CONFIG | ACIA_NOT_RTS)
                sta ACIA_CTRL
                bra _next_char
        
