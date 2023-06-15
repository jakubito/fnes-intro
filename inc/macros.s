.macro load_vram address
  bit PPU_STATUS
  lda #.hibyte(address)
  sta PPU_ADDR
  lda #.lobyte(address)
  sta PPU_ADDR
.endmacro

.macro update_scroll
  bit PPU_STATUS
  lda scroll_x
  sta PPU_SCROLL
  lda scroll_y
  sta PPU_SCROLL
.endmacro

.macro wait_frames count
  .local @wait
  ldx #count
@wait:
  jsr wait_nmi
  dex
  bne @wait
.endmacro
