.include "headers.asm"


.segment "STARTUP"


.include "reset.asm"

SPRITESTART = $0200
CONTROLLERREG = $4016
PPU_NAMETABLE = $2000


PLAYERX = SPRITESTART + 3
PLAYERATTR = SPRITESTART + 2
PLAYERY = SPRITESTART
PLAYERSPRITE = SPRITESTART + 1

LIFECOUNTSPRITE = SPRITESTART + 5



BUTTONS = $00
GROUND_FLAG = $01
CURRENT_GROUND = $03
TMPX = $04
COLLISION_FLAG = $05
MOVE_DIRECTION = $06
REVERSE_MOVE_DIRECTION = $07
RUN_TIMER = $08
LIVES_COUNT = $09
CURRENT_LEVEL = $0A


PLAYERY_HIGH  = $10
PLAYERY_LOW   = $11
PLAYERYV_HIGH = $12
PLAYERYV_LOW  = $13

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



; Game Start
    lda #$05
    sta LIVES_COUNT


Loop:
    jmp Loop


FallDown:
    ; FALL
    clc
    lda PLAYERYV_LOW
    adc #$0F
    sta PLAYERYV_LOW
    lda PLAYERYV_HIGH
    adc #$00
    sta PLAYERYV_HIGH
    clc
    lda PLAYERY_LOW
    adc PLAYERYV_LOW
    sta PLAYERY_LOW
    lda PLAYERY_HIGH
    adc PLAYERYV_HIGH
    sta PLAYERY_HIGH
    clc
    rts

FallUp:
    clc
    lda PLAYERY_LOW
    sbc PLAYERYV_LOW
    sta PLAYERY_LOW
    lda PLAYERY_HIGH
    sbc PLAYERYV_HIGH
    sta PLAYERY_HIGH
    clc
    lda #$00
    sta PLAYERYV_HIGH
    sta PLAYERYV_LOW
    sta PLAYERY_LOW
    sta COLLISION_FLAG
    clc
    
    rts

CheckCurrentGroud:
    ldx PLAYERX
    txa 
    clc
    adc #$03
    lsr 
    lsr
    lsr ; Divide By 8
    clc
    adc CURRENT_LEVEL
    tax
    lda LevelData,x
    and #$0f
    cmp #$0f
    bne MultEightAddFive
    lda #$ff
    EndCheckCurrentGround:
    sta CURRENT_GROUND
    rts
MoveBackTwice:
    clc
    adc REVERSE_MOVE_DIRECTION
    clc
    rts
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
SetCollision:
    lda #$01
    jmp EndCheckCollision
CheckCollision: ; Checks for collision and writes a #$00 or #$01 to COLLISION_FLAG
    ldx PLAYERY
    cpx CURRENT_GROUND
    bcs SetCollision
    lda #$00
    EndCheckCollision:
    sta COLLISION_FLAG
    rts




MultEightAddFive:
    asl 
    asl 
    asl ; Multiply By 8
    adc #$05 ; Add 5
    jmp EndCheckCurrentGround
MoveDown:
    inc PLAYERY
    jmp EndOfFall



UndoMove:
    lda PLAYERX
    jsr MoveBackTwice
    sta PLAYERX
    jmp EndOfMove


; TODO:
;
;   Fix loading new screen into nametable
;
;   Fix player bobbing up and down
;   Add multiple screens
;   Add enemies   
;   Add sound
;   Add music

FrameLoop:    
    
    jsr CheckCurrentGroud

    jsr FallDown

    
    jsr CheckCollision
    ldx COLLISION_FLAG
    sta GROUND_FLAG
    cpx #$01
    beq UndoFall
    lda PLAYERY_HIGH
    sta PLAYERY
    jmp EndOfFall
    UndoFall:
        jsr FallUp
    EndOfFall:
    lda PLAYERY_HIGH
    sta PLAYERY
    

    lda #$00
    sta REVERSE_MOVE_DIRECTION
    sta MOVE_DIRECTION

    ; Movement for buttons
    lda #%10000000 ; Right Button
    bit BUTTONS
    bne MoveRight

    lda #%01000000 ; Left Button
    bit BUTTONS
    bne MoveLeft

    EndOfMoveLeftRight:
    lda PLAYERX
    clc
    adc MOVE_DIRECTION
    clc
    sta PLAYERX
    jsr CheckCurrentGroud
    jsr CheckCollision
    ldx COLLISION_FLAG
    cpx #$01
    beq UndoMove
    EndOfMove:

    lda #%00000001 ; A Button
    bit BUTTONS
    bne JumpUp
    EndOfJumpUp:
    
    lda RUN_TIMER
    lsr
    lsr
    lsr
    and #$03
    clc
    adc #$01
    sta PLAYERSPRITE

    lda LIVES_COUNT
    and #$0F
    adc #$F0
    sta LIFECOUNTSPRITE

    ldx PLAYERY
    cpx #$F0
    bcs Death
    EndOfDeathCheck:
    
    ldx PLAYERX
    cpx #$f8
    bcs NextLevel
    EndOfNextLevel:

    rts

NextLevel:
    lda #$08
    sta PLAYERX
    ; lda CURRENT_LEVEL
    ; adc #$20
    ; sta CURRENT_LEVEL
    ; dec CURRENT_LEVEL
    clc
    ; jsr LoadBackground_SRT
    jmp EndOfNextLevel

SetNegativeYV:
    lda #$fe
    sta PLAYERYV_HIGH
    lda #$00
    sta PLAYERYV_LOW
    jmp EndOfJumpUp
JumpUp:
    ldx GROUND_FLAG
    cpx #$01
    beq SetNegativeYV
    
    jmp EndOfJumpUp
MoveRight:
    inc RUN_TIMER
    lda %01000000 ; Face Right
    sta PLAYERATTR
    lda #$01
    sta MOVE_DIRECTION
    lda #$ff
    sta REVERSE_MOVE_DIRECTION
    jmp EndOfMoveLeftRight
MoveLeft:
    inc RUN_TIMER
    lda %00000000 ; Face Left
    sta PLAYERATTR
    lda #$ff
    sta MOVE_DIRECTION
    lda #$01
    sta REVERSE_MOVE_DIRECTION
    jmp EndOfMoveLeftRight
Death:
    dec LIVES_COUNT
    lda #$08
    sta PLAYERX
    sta PLAYERY
    sta PLAYERY_HIGH
    lda #$00
    sta PLAYERY_LOW
    sta PLAYERYV_HIGH
    sta PLAYERYV_LOW
    ; sta CURRENT_LEVEL
    ; jsr LoadBackground_SRT
    jmp EndOfDeathCheck

NMI:
    lda #$02 ; copy sprite data from $0200 => PPU memory for display
    sta $4014
    jsr ReadController
    jsr FrameLoop
    rti

.include "load_level_srt.asm"

.include "game_data/level_data.asm"

.include "game_data/graphics_data.asm"

MusicData:
    .incbin "game_data/music.bin"


.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "game_data/chars.chr"