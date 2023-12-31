; settings
SPRITES_COUNT = 40

; PPU registers
PPU_CTRL    = $2000
PPU_MASK    = $2001
PPU_STATUS  = $2002
OAM_ADDR    = $2003
OAM_DATA    = $2004
PPU_SCROLL  = $2005
PPU_ADDR    = $2006
PPU_DATA    = $2007
OAM_DMA     = $4014

; internal CPU memory addresses
nmi_counter = $20
scroll_x    = $21
scroll_y    = $22
state       = $23
frame_delay = $24
seed_hi     = $25
seed_lo     = $26
oam_data    = $0200
speed_data  = $0300
