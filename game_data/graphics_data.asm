PaletteData:
  ;background palette data
  .byte $21,$01,$29,$16
  .byte $21,$01,$29,$16
  .byte $21,$01,$29,$16
  .byte $21,$01,$29,$16  

  ;sprite palette data
  .byte $21,$07,$27,$26 ; Player palette
  .byte $21,$07,$27,$26
  .byte $21,$07,$27,$26
  .byte $21,$00,$0F,$30 ; Text/number palette

SpriteData:
  .byte $08, $01, %00000000, $08 ; PLAYER
  .byte $08, $F0, %00000011, $08 ; LIFE COUNT
  