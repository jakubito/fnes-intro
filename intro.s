.include "inc/constants.s"

.segment "HEADER"
  .byte $4e, $45, $53, $1a  ; iNES header
  .byte 2                   ; 2x 16KB PRG code
  .byte 1                   ; 1x 8KB CHR data
  .byte 0                   ; horizontal mirroring, mapper 0

.segment "VECTORS"
  .addr nmi
  .addr reset
  .addr 0

.segment "STARTUP"

.segment "CHARS"
.incbin "bin/background.chr"

.segment "CODE"

reset:
  sei           ; disable IRQs
  cld           ; disable decimal mode
  ldx #$40
  stx $4017     ; disable APU frame IRQ
  ldx #$ff      ; set up stack
  txs
  ldx #$00
  stx PPU_CTRL  ; disable NMI
  stx PPU_MASK  ; disable rendering
  stx $4010     ; disable DMC IRQs

; first wait for vertical blank
vblank_wait1:
  bit PPU_STATUS
  bpl vblank_wait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

; second wait for vertical blank, PPU is ready after this
vblank_wait2:
  bit PPU_STATUS
  bpl vblank_wait2

load_palettes:
  lda PPU_STATUS
  lda #$3f
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldx #$00
@loop:
  lda palettes, x
  sta PPU_DATA
  inx
  cpx #$20
  bne @loop

load_nametable:
  lda #.lobyte(title_screen)
  sta $00
  lda #.hibyte(title_screen)
  sta $01
  lda PPU_STATUS
  lda #$20
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldx #$04
  ldy #$00
@loop:
  lda ($00), y
  sta PPU_DATA
  iny
  bne @loop
  inc $01
  dex
  bne @loop

enable_rendering:
  lda #%10000000  ; enable NMI
  sta PPU_CTRL
  lda #%00001000  ; enable background rendering
  sta PPU_MASK

forever:
  jmp forever

nmi:
  rti

.include "inc/palettes.s"
.include "inc/title_screen.s"
