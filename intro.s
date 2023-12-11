.include "inc/constants.s"
.include "inc/macros.s"
.include "inc/procedures.s"
.include "inc/palettes.s"
.include "inc/flash_colors.s"
.include "inc/title_screen.s"

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
.incbin "bin/sprites.chr"

.segment "CODE"

reset:
  sei             ; disable IRQs
  cld             ; disable decimal mode
  ldx #%01000000
  stx $4017       ; disable APU frame IRQ
  ldx #$ff
  txs             ; set up stack
  ldx #0
  stx PPU_CTRL    ; disable NMI
  stx PPU_MASK    ; disable rendering
  stx $4010       ; disable DMC IRQs

; first wait for vertical blank
vblank_wait1:
  bit PPU_STATUS
  bpl vblank_wait1

clear_memory:
  lda #0
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

prng_seed:
  lda #$89
  sta seed_lo

; second wait for vertical blank, PPU is ready after this
vblank_wait2:
  bit PPU_STATUS
  bpl vblank_wait2

clear_nametables:
  LoadVram $2400
  lda #0
  tax
  ldy #8
: sta PPU_DATA
  inx
  bne :-
  dey
  bne :-

load_palettes:
  LoadVram $3f00
  ldx #0
  ldy #$20
: lda palettes, x
  sta PPU_DATA
  inx
  dey
  bne :-

load_nametable:
  addr_lo = $00
  addr_hi = $01
  lda #.lobyte(title_screen)
  sta addr_lo
  lda #.hibyte(title_screen)
  sta addr_hi
  LoadVram $2800
  ldx #4
  ldy #0
: lda (addr_lo), y
  sta PPU_DATA
  iny
  bne :-
  inc addr_hi
  dex
  bne :-

initial_sprites:
  ldx #0
  ldy #0
: jsr new_sprite
  cpx #SPRITES_COUNT * 4 .mod $100
  bne :-

initial_scroll:
  lda #20
  sta scroll_y
  UpdateScroll

enable_rendering:
  lda #%10001000
  sta PPU_CTRL
  jsr wait_nmi
  lda #%00011000
  sta PPU_MASK

main_loop:
  jsr wait_nmi
  lda #0
  sta OAM_ADDR
  lda #.hibyte(oam_data)
  sta OAM_DMA
  lda state
  bne flash_text

scroll_title:
  inc scroll_y
  UpdateScroll
  lda scroll_y
  cmp #239
  bne prepare_sprites
  lda #1
  sta state
  lda #10
  sta frame_delay
  jmp prepare_sprites

flash_text:
  color_index = $02
  lda frame_delay
  beq :+
  dec frame_delay
  jmp prepare_sprites
: ldx color_index
  bne :+
  ldx #$0f            ; start from last index of flash_colors
  stx color_index
: LoadVram $3f07      ; text palette index
  lda flash_colors, x
  sta PPU_DATA
  LoadVram 0
  UpdateScroll
  dec color_index
  lda #5
  sta frame_delay

prepare_sprites:
  ldx #0
@loop:
  ldy speed_data, x
  inx
  inx
  inx
  lda oam_data, x
  cmp #4
  bcs :+
  dex
  dex
  dex
  ldy #1
  jsr new_sprite
  jmp @done
: dec oam_data, x
  dey
  bne :-
  inx
@done:
  cpx #SPRITES_COUNT * 4 .mod $100
  bne @loop
  jmp main_loop

new_sprite:
  jsr rand
  and #%00000011
  sta speed_data, x
  inc speed_data, x
  jsr rand
  sta oam_data, x     ; Y position
  inx
  jsr rand
  and #%00001111
  cpx #SPRITES_COUNT
  bcc :+
  and #%00000011
: sta oam_data, x     ; tile index
  inx
  jsr rand
  and #%00000011
  ora #%00100000
  sta oam_data, x     ; palette & priority
  inx
  lda #$ff
  cpy #1
  beq :+
  jsr rand
: sta oam_data, x     ; X position
  inx
  rts
