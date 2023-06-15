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
  bit PPU_STATUS
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
  addr_lo = $00
  addr_hi = $01
  lda #.lobyte(title_screen)
  sta addr_lo
  lda #.hibyte(title_screen)
  sta addr_hi
  bit PPU_STATUS
  lda #$28
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  ldx #$04
  ldy #$00
@loop:
  lda (addr_lo), y
  sta PPU_DATA
  iny
  bne @loop
  inc addr_hi
  dex
  bne @loop

initial_scroll:
  bit PPU_STATUS
  lda #$00
  sta PPU_SCROLL
  ldx #$20
  stx PPU_SCROLL

enable_nmi:
  lda #%10000000
  sta PPU_CTRL

enable_background:
  jsr wait_nmi
  lda #%00001000
  sta PPU_MASK

scroll_title:
  jsr wait_nmi
  bit PPU_STATUS
  lda #$00
  sta PPU_SCROLL
  stx PPU_SCROLL
  inx
  cpx #$f0
  bne scroll_title

wait_frames:
  ldx #$10
@wait:
  jsr wait_nmi
  dex
  bne @wait

flash_text:
  ldx #$0f  ; start from last index of flash_colors
@next:
  ldy #$05  ; number of frames per color entry
@wait:
  jsr wait_nmi
  dey
  bne @wait
  bit PPU_STATUS
  lda #$3f
  sta PPU_ADDR
  lda #$0b
  sta PPU_ADDR
  lda flash_colors, x
  sta PPU_DATA
  lda #$00
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  lda #$00
  sta PPU_SCROLL
  lda #$ef
  sta PPU_SCROLL
  dex
  bne @next
  jmp flash_text

nmi:
  inc nmi_counter
  rti

wait_nmi:
  lda nmi_counter
@loop:
  cmp nmi_counter
  beq @loop
  rts

.include "inc/palettes.s"
.include "inc/flash_colors.s"
.include "inc/title_screen.s"
