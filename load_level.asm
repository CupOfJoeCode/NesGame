LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  LDX #$00              ; start out at 0
  JMP StartLoadNameTable
NAMETABLEOUT = $2007
CURRENT_TILE = $02


SetAGrass:
    lda #$01
    jmp EndCheckY
SetAGround:
    lda #$02
    jmp EndCheckY

SetWater:
    lda #$06
    jmp EndCheckY

SetBlank:
    lda #$00
    cpy #$0F
    bcs SetWater
    jmp EndCheckY
CheckY:
    cpy CURRENT_TILE
    beq SetAGrass
    bcs SetAGround
    jmp EndCheckY

StartLoadNameTable:
ldy #$00
LoadNametable:
    ldx #$00
    
    DrawLine:
        lda LevelData,X
        and #$0f ; Get lower 4 bits
        sta CURRENT_TILE 
        lda #$00

        stx TMPX
        ldx CURRENT_TILE
        cpx #$0F
        bne CheckY
        beq SetBlank
        
        EndCheckY:
        sta NAMETABLEOUT
        ldx TMPX
        inx
        cpx #$20
        bne DrawLine
    iny
    cpy #$1F
    
    bne LoadNametable
LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
