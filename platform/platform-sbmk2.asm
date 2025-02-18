        ; 65C02 processor (Tali will not compile on older 6502)
        .cpu "65c02"
        ; No special text encoding (eg. ASCII)
        .enc "none"

ram_end = $9F00-1
acia_buff = hist_buff-$100 ; begin of ACIA buffer memory
cp_end    = acia_buff      ; Last RAM byte available for code

        * = $A000

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

CONF_REG := $FFF4
CONF_CURRENT_MODE := $70
CONF_ENABLE_ROM := $DF
IPL_VECTOR := $F000
BYE_VECTOR := $F0

bye_fn:
                ; renable the ROM
                lda #CONF_CURRENT_MODE 
                and #CONF_ENABLE_ROM
                sta CONF_REG
                jmp IPL_VECTOR

BYE_FN_LENGTH := *-bye_fn

kernel_bye:
                sei
                jsr acia_shutdown
                ldx #BYE_FN_LENGTH
                ldy #0
_copy:
                lda bye_fn,y
                sta BYE_VECTOR,y
                iny
                dex
                bne _copy
                jmp BYE_VECTOR


ACIA_PORT := $FFF0
.include "acia.asm"

noop_isr:
                rti

; Add the machine vectors
        * = $fffa
        .word noop_isr
        .word kernel_init
        .word acia_isr


; END

