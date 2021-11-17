.include "headers.asm"


.segment "STARTUP"


.include "reset.asm"





:
    bit $2002
    bpl :-

    txa



CLEARMEM:
    sta $0000, X ; $0000 => $00FF
    sta $0100, X ; $0100 => $01FF
    sta $0300, X
    sta $0400, X
    sta $0500, X
    sta $0600, X
    sta $0700, X
    lda #$FF
    sta $0200, X ; $0200 => $02FF
    lda #$00
    inx
    bne CLEARMEM    

; wait for vblank
:
    bit $2002
    bpl :-

    lda #$02
    sta $4014
    nop

    ; $3F00
    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    ldx #$00

SPRITESTART = $0200
CONTROLLERREG = $4016

LoadPalettes:
    lda PaletteData, X
    sta $2007  ; $3F00, $3F01, $3F02 => $3F1F
    inx
    cpx #$20
    bne LoadPalettes    

    ldx #$00
LoadSprites:
    lda SpriteData, X
    sta SPRITESTART, X
    inx
    cpx #$20
    bne LoadSprites    

; Clear the nametables- this isn't necessary in most emulators unless
; you turn on random memory power-on mode, but on real hardware
; not doing this means that the background / nametable will have
; random garbage on screen. This clears out nametables starting at
; $2000 and continuing on to $2400 (which is fine because we have
; vertical mirroring on. If we used horizontal, we'd have to do
; this for $2000 and $2800)
    ldx #$00
    ldy #$00
    lda $2002
    lda #$20
    sta $2006
    lda #$00
    sta $2006
ClearNametable:
    sta $2007
    inx
    bne ClearNametable
    iny
    cpy #$08
    bne ClearNametable
    
; Enable interrupts
    cli

    lda #%10010000 ; enable NMI change background to use second chr set of tiles ($1000)
    sta $2000
    ; Enabling sprites and background for left-most 8 pixels
    ; Enable sprites and background
    lda #%00011110
    sta $2001





Loop:
    jmp Loop


PLAYERX = SPRITESTART + 3
PLAYERY = SPRITESTART
PLAYERSPRITE = SPRITESTART + 1


BUTTONS = $00

ReadController:
    lda #$01
    sta CONTROLLERREG
    ldx #$00
    stx CONTROLLERREG
    
    ReadLoop:
        lda CONTROLLERREG
        lsr
        ror BUTTONS
        inx
        cpx #$08
        bne ReadLoop
    rts

MoveRight:
    inc PLAYERX
    jmp EndOfMove
MoveLeft:
    dec PLAYERX
    jmp EndOfMove
MoveDown:
    inc PLAYERY
    jmp EndOfFall

FrameLoop:

    ldx PLAYERY
    cpx #$60
    bcc MoveDown
    EndOfFall:



    ldx BUTTONS
    cpx #%10000000
    beq MoveRight
    cpx #%01000000
    beq MoveLeft
    
    EndOfMove:
    rts

NMI:
    lda #$02 ; copy sprite data from $0200 => PPU memory for display
    sta $4014
    jsr ReadController
    jsr FrameLoop
    rti

.include "graphics_data.asm"

.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "game_data/chars.chr"