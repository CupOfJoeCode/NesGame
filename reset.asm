Reset:
    sei ; Disables all interrupts
    cld ; disable decimal mode

    ; Disable sound IRQ
    ldx #$40
    stx $4017

    ; Initialize the stack register
    ldx #$FF
    txs

    inx ; #$FF + 1 => #$00

    ; Zero out the PPU registers
    stx $2000
    stx $2001

    stx $4010