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
PPU_NAMETABLE = $2000

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

; Clear the nametables
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

.include "load_level.asm"



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
PLAYERATTR = SPRITESTART + 2
PLAYERY = SPRITESTART
PLAYERSPRITE = SPRITESTART + 1


BUTTONS = $00
JUMPTIMER = $01
CURRENT_GROUND = $03
TMPX = $04

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
    lda %01000000 ; Face Right
    sta PLAYERATTR
    jmp EndOfMoveRight
MoveLeft:
    dec PLAYERX
    lda %00000000 ; Face Left
    sta PLAYERATTR
    jmp EndOfMoveLeft
MoveDown:
    inc PLAYERY
    jmp EndOfFall
ResetJumpTimer:
    lda #$00
    sta JUMPTIMER
    jmp EndOfFall
MoveUp:
    dec PLAYERY ; Move Up Twice
    dec PLAYERY
    inc JUMPTIMER
    jmp EndOfJumpUp
JumpUp:
    ldx JUMPTIMER
    cpx #$20
    bcc MoveUp
    jmp EndOfJumpUp

MultEightAddFive:
    asl 
    asl 
    asl ; Multiply By 8
    adc #$05 ; Add 5
    jmp EndCheckCurrentGround

FrameLoop:    
    ldx PLAYERX
    txa 
    lsr 
    lsr
    lsr ; Divide By 8
    tax
    lda LevelData,x
    and #$0f
    cmp #$0f
    bne MultEightAddFive
    lda #$ff
    EndCheckCurrentGround:
    sta CURRENT_GROUND
    

    ldx PLAYERY
    cpx CURRENT_GROUND
    bcc MoveDowd
    jmp ResetJumpTimer
    EndOfFall:

    ; TODO: Add Collisions

    ; Movement for buttons
    lda #%10000000 ; Right Button
    bit BUTTONS
    bne MoveRight
    EndOfMoveRight:
    lda #%01000000 ; Left Button
    bit BUTTONS
    bne MoveLeft
    EndOfMoveLeft:
    lda #%00000001 ; A Button
    bit BUTTONS
    bne JumpUp
    EndOfJumpUp:
    
    
    rts

NMI:
    lda #$02 ; copy sprite data from $0200 => PPU memory for display
    sta $4014
    jsr ReadController
    jsr FrameLoop
    rti


.include "level_data.asm"

.include "graphics_data.asm"

.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "game_data/chars.chr"