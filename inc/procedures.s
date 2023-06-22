; https://github.com/7800-devtools/lfsr6502
; Type:         galois8 extended to 16 bits
; 6502 author:  Fred Quimby
; RAM:          2 bytes
; Size:         13 bytes
; Cycles:       19-20
; Period:       65535
; References:   https://github.com/batari-Basic
; Notes:  This is the rand16 routine included with the 2600 development
;         language batari Basic, and the default rand routine in
;         7800basic. Its quick and compact for a 16-bit LFSR.
rand:
  lda seed_hi
  lsr
  rol seed_lo
  bcc :+
  eor #$b4
: sta seed_hi
  eor seed_lo
  rts

nmi:
  inc nmi_counter
  rti

wait_nmi:
  lda nmi_counter
: cmp nmi_counter
  beq :-
  rts
