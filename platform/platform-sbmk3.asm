        ; 65C02 processor (Tali will not compile on older 6502)
        .cpu "65c02"
        ; No special text encoding (eg. ASCII)
        .enc "none"

ram_end = $9F00-1
acia_buff = hist_buff-$100 ; begin of ACIA buffer memory
cp_end    = acia_buff      ; Last RAM byte available for code

        * = $A000
                .word $CE5B
                .byte 0,1,2,3,4,5,6,7,8,9,$8A,$8B,$8C,$8D,$8E,$8F
                .word kernel_init
                .align 16


TALI_OPTIONAL_WORDS := [ "ed", "editor", "ramdrive", "block", "environment?", "assembler", "disassembler", "wordlist" ]
TALI_OPTION_CR_EOL := [ "cr", "lf" ]

.include "../taliforth.asm" ; Top-level definitions, memory map


; Put the I/O routines in the last 1K of ROM
                * = $F000

kernel_init:
                jsr acia_init
                jmp forth

kernel_getc:
                jsr acia_getc
                bcc kernel_getc
                rts

kernel_kbhit = acia_kbhit
kernel_putc = acia_putc

CONF_REG := $FFD8
CONF_MMUE := $80
MMU_SLOT0 = $FFC0
IPL_VECTOR := $F000
BYE_VECTOR := $F0

bye_fn:
                lda CONF_REG
                and #~CONF_MMUE
                sta CONF_REG
                jmp IPL_VECTOR

BYE_FN_LENGTH := *-bye_fn

kernel_bye:
                sei
                jsr acia_shutdown
		; put bank 0 in slot zero since we will disable MMU
		stz MMU_SLOT0
                ldx #BYE_FN_LENGTH
                ldy #0
_copy:
                lda bye_fn,y
                sta BYE_VECTOR,y
                iny
                dex
                bne _copy
                jmp BYE_VECTOR


.include "acia.s"

noop_isr:
                rti

; Add the interrupt vectors
        * = $ffe0
        .word noop_isr                  ; IRQ0
        .word noop_isr                  ; IRQ1
        .word noop_isr                  ; IRQ2
        .word acia_isr                  ; IRQ3 (ACIA)
        .word noop_isr                  ; IRQ4
        .word noop_isr                  ; IRQ5
        .word noop_isr                  ; IRQ6
        .word noop_isr                  ; IRQ7

        * = $fffa
        .word noop_isr
        .word kernel_init
        .word noop_isr


; END

