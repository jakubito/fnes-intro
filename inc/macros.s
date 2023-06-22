.macro LoadVram address
  bit PPU_STATUS
  lda #.hibyte(address)
  sta PPU_ADDR
  lda #.lobyte(address)
  sta PPU_ADDR
.endmacro

.macro UpdateScroll
  bit PPU_STATUS
  lda scroll_x
  sta PPU_SCROLL
  lda scroll_y
  sta PPU_SCROLL
.endmacro
