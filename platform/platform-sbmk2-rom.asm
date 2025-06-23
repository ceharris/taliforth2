        ; 65C02 processor (Tali will not compile on older 6502)
        .cpu "65c02"
        ; No special text encoding (eg. ASCII)
        .enc "none"

ram_end = $7F00-1
acia_buff = hist_buff-$100 ; begin of ACIA buffer memory
cp_end    = acia_buff      ; Last RAM byte available for code

        * = $8000

TALI_OPTIONAL_WORDS := [ "ed", "editor", "ramdrive", "block", "environment?", "assembler", "disassembler", "wordlist" ]
TALI_OPTION_CR_EOL := [ "cr", "lf" ]

.include "../taliforth.asm" ; Top-level definitions, memory map


CONF_REG := $FFF4
CONF_MODE_RAML_ROM := $40
CONF_MODE_RAMLW_ROM := $0

IPL = $F000
CPUTC = $FFE0
CGETC = $FFE3
CKBHIT = $FFE6
SETBRK = $FFE9

                * = $EF80

kernel_init:
                lda #CONF_MODE_RAML_ROM
                sta CONF_REG
                ldy #<kernel_break
                lda #>kernel_break
                jsr SETBRK
                jmp forth

kernel_bye:
                lda #CONF_MODE_RAMLW_ROM
                sta CONF_REG
                jmp IPL
kernel_getc:
                jsr CGETC
                bcc kernel_getc
                rts

kernel_break:
                lda #err_usersigint
                jmp error

            
kernel_kbhit = CKBHIT
kernel_putc = CPUTC

; END

