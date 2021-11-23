LoadBackground_SRT:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  TAX              ; start out at 0

  
  
  
  JMP StartLoadNameTable_SRT



SetAGrass_SRT:
    lda #$01
    jmp EndCheckY
SetAGround_SRT:
    lda #$02
    jmp EndCheckY

SetWater_SRT:
    lda #$06
    jmp EndCheckY

SetBlank_SRT:
    lda #$00
    cpy #$0F
    bcs SetWater_SRT
    jmp EndCheckY
CheckY_SRT:
    cpy CURRENT_TILE
    beq SetAGrass_SRT
    bcs SetAGround_SRT
    jmp EndCheckY

StartLoadNameTable_SRT:
ldy #$00
LoadNametable_SRT:
    ldx CURRENT_LEVEL
    
    DrawLine_SRT:
        lda LevelData,X
        and #$0f ; Get lower 4 bits
        sta CURRENT_TILE 
        lda #$00

        stx TMPX
        ldx CURRENT_TILE
        cpx #$0F
        bne CheckY_SRT
        beq SetBlank_SRT
        
        EndCheckY_SRT:

        sta NAMETABLEOUT
        ldx TMPX
        inx
        txa
        clc
        sbc CURRENT_LEVEL
        clc
        adc #$01
        cmp #$20
        bne DrawLine_SRT
    iny
    cpy #$1F
    
    bne LoadNametable_SRT
; LoadAttribute_SRT:
;   LDA $2002             ; read PPU status to reset the high/low latch
;   LDA #$23
;   STA $2006             ; write the high byte of $23C0 address
;   LDA #$C0
;   STA $2006             ; write the low byte of $23C0 address
;   LDX #$00              ; start out at 0
rts