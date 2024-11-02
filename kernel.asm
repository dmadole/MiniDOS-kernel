; *******************************************************************
; *** This software is copyright 2006 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

#include ops.inc
#include bios.inc

            org     300h

keybuf:     equ     080h
dta:        equ     100h


          ; New names for error codes that are a little more concise, self-
          ; explanitory, and that follow the ?_ type naming convention of
          ; other public kernel API constants. Also, keep length to 10
          ; characters maximum like other existing ?_ API constants.

e_exists:   equ 1         ; tried to create something that already exists
e_notfound: equ 2         ; could not find something being looked for
e_notdir:   equ 3         ; item in path that should be a directory is not
e_notfile:  equ 4         ; tried a file operation on something not a file
e_notempty: equ 5         ; tried to remove a directory that is not empty
e_notexec:  equ 6         ; tried to execute something not executable


          ; New error codes not previously defined but needed to cover more
          ; situations reasonably.

e_nospace:  equ 7         ; not enough space available to complete operation
e_deverror: equ 8         ; hardware failure reading or writing the device
e_readonly: equ 9         ; write operation tried on something read-only
e_invname:  equ 10        ; file name is not a valid length or format
e_notopen:  equ 11        ; tried operation on a descriptor that is not open


          ; Legacy error constants that were never widely implemented.

errexists:      equ   e_exists
errnoffnd:      equ   e_notfound
errinvdir:      equ   e_notdir
errisdir:       equ   e_notfile
errdirnotempty: equ   e_notempty
errnotexec:     equ   e_notexec

ff_dir:     equ     1
ff_exec:    equ     2
ff_write:   equ     4
ff_hide:    equ     8
ff_archive: equ     16

o_cdboot:   lbr     coldboot
o_wrmboot:  lbr     warmboot
o_open:     lbr     open
o_read:     lbr     read
o_write:    lbr     write
o_seek:     lbr     seek
o_close:    lbr     close
o_opendir:  lbr     opendir
o_delete:   lbr     delete
o_rename:   lbr     rename
o_exec:     lbr     exec
o_mkdir:    lbr     mkdir
o_chdir:    lbr     chdir
o_rmdir:    lbr     rmdir
o_rdlump:   lbr     readlump
o_wrtlump:  lbr     writelump
o_type:     lbr     f_tty
o_msg:      lbr     f_msg
o_readkey:  lbr     f_read
o_input:    lbr     f_input
o_prtstat:  lbr     return
o_print:    lbr     return
o_execdef:  lbr     execbin
o_setdef:   lbr     setdef
o_kinit:    lbr     kinit
o_inmsg:    lbr     f_inmsg
o_getdev:   lbr     f_getdev
o_gettod:   lbr     f_gettod
o_settod:   lbr     f_settod
o_inputl:   lbr     f_inputl
o_boot:     lbr     f_boot
o_tty:      lbr     f_tty
o_setbd:    lbr     f_setbd
o_initcall: lbr    f_initcall
o_brktest:  lbr     f_brktest
o_devctrl:  lbr     deverr
o_alloc:    lbr     alloc
o_dealloc:  lbr     dealloc
o_termctl:  lbr     error
o_nbread:   lbr     f_nbread
o_memctrl:  lbr     deverr

deverr:    ldi     0

error:     smi     0
           sep     sret

           org     3d0h                ; reserve some space for users
user:      db      0

           org     3f0h
intret:    sex     r2
           irx
           ldxa
           shr
           ldxa
           ret
iserve:    dec     r2
           sav
           dec     r2
           stxd
           shlc
           stxd
           db      0c0h
ivec:      dw      intret

           org     400h
version:   db      4,3,1

build:     dw      [build]

date:      db      [month],[day]
           dw      [year]

sysfildes: db      0,0,0,0             ; current offset
           dw      dta                 ; dta
           dw      0                   ; eof
           db      0                   ; flags
           db      0,0,0,0             ; dir sector
           dw      0                   ; dir offset
           db      255,255,255,255     ; current sector

intfildes: db      0,0,0,0             ; current offset
           dw      intdta              ; dta
           dw      0                   ; eof
intflags:  db      0                   ; flags
           db      0,0,0,0             ; dir sector
           dw      0                   ; dir offset
           db      255,255,255,255     ; current sector

           db      0,0,0,0,0,0,0,0,0,0 ; was mdfildes space
           db      0,0,0,0,0,0,0,0,0

himem:      dw      0
d_idereset: lbr    f_idereset          ; jump to bios ide reset
d_ideread:  lbr     f_ideread           ; jump to bios ide read
d_idewrite: lbr    f_idewrite          ; jump to bios ide write
d_reapheap: lbr    reapheap            ; passthrough to heapreaper
d_progend:  lbr    warm3
d_lmpsize:  lbr     return              ; deprecated and unnecessary
            db      0,0,0,0
            db      0,0,0,0,0,0,0
shelladdr:  dw      0
stackaddr:  dw      0
lowmem:     dw      04000h
retval:     db      0
heap:       dw      0
d_incofs:   lbr     incofs1             ; internal vector, not a published call
d_append:   lbr     append              ; internal vector, not a published call
clockfrq:   dw      4000

#define LMPSHIFT 3                     ; these are statically defined now
#define LMPMASK 0fh

lmpshift:  db      LMPSHIFT            ; variables kept but deprecated
lmpmask:   db      LMPMASK

curdrive:  db      0
date_time: db      1,17,49,0,0,0
secnum:    dw      0
secden:    dw      0


path:      ds      128

           org     0500h

getfddwrd: plo     re
           push    rd
           glo     re
           str     r2
           glo     rd
           add
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           ldn     rd
           plo     r7
           pop     rd
return:    sep     sret


setfddwrd: plo     re
           push    rd
           glo     re
           str     r2
           glo     rd
           add
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           inc     rd
           inc     rd
           inc     rd
           sex     rd
           glo     r7
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           str     rd
           sex     r2
           pop     rd
           sep     sret


; ********************************
; *** Get eof file descriptor  ***
; *** RD - file descriptor     ***
; *** Returns: RF - eof offset ***
; ********************************
getfdeof:  glo     rd                  ; move descriptor to eof
           adi     6
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get dir sector
           phi     rf
           ldn     rd
           plo     rf
fdminus7:  glo     rd                  ; move pointer back to beginning
           smi     7
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

; ********************************
; *** Set eof file descriptor  ***
; *** RD - file descriptor     ***
; *** RF - eof                 ***
; ********************************
setfdeof:  glo     rd                  ; move descriptor to eof
           adi     6
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     rf
           str     rd
           inc     rd
           glo     rf
           str     rd
           br      fdminus7

; **************************************
; *** Get flags from file descriptor ***
; *** RD - file descriptor           ***
; *** Returns D - flags              ***
; **************************************
getfdflgs: glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags
fdminus8:  plo     re                  ; save D
           glo     rd                  ; move pointer back to beginning
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           glo     re                  ; recover D
           sep     sret                ; and return to caller

; ************************************
; *** Set flags in file descriptor ***
; *** RD - file descriptor         ***
; ***  D - flags                   ***
; ************************************
setfdflgs: plo     re                  ; save D
           glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           glo     re                  ; recover D
           str     rd                  ; store into descriptor
           br      fdminus8            ; and return

; *******************************************
; *** Get dir offset from file descriptor ***
; *** RD - file descriptor                ***
; *** Returns: R9 - dir offset            ***
; *******************************************
getfddrof: glo     rd                  ; move descriptor to flags
           adi     13
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get dir sector
           phi     r9
           ldn     rd
           plo     r9
fdminus14: glo     rd                  ; move pointer back to beginning
           smi     14
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

; *******************************************
; *** Set dir offset in file descriptor   ***
; *** RD - file descriptor                ***
; *** R9 - dir offset                     ***
; *******************************************
setfddrof: glo     rd                  ; move descriptor to flags
           adi     13
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     r9
           str     rd
           inc     rd
           glo     r9
           str     rd
           br      fdminus14

; ******************************
; *** Convert sector to lump ***
; *** R8.0:R7 - Sector       ***
; *** Returns: RA - Lump     ***
; ******************************

sectolump: glo     r8                  ; save consumed registers
           stxd

           ghi     r7
           phi     ra
           glo     r7
           plo     ra

           ldi     LMPSHIFT            ; retrieve shift count
           plo     re                  ; and set into shift counter

lmptosec1: glo     r8
           shr
           plo     r8
           ghi     ra
           shrc
           phi     ra
           glo     ra
           shrc
           plo     ra

           dec     re                  ; decrement shift count
           glo     re                  ; see if at end
           lbnz    lmptosec1           ; loop back if more shifts needed

           irx                         ; recover consumed registers
           ldx
           plo     r8

           sep     sret                ; return to caller

; *******************************
; *** Convert lump to sector  ***
; *** RA - lump               ***
; *** Returns: R8.0:R7 - Sector ***
; *******************************

lumptosec: glo     ra                  ; transfer lump to sector
           plo     r7
           ghi     ra
           phi     r7

           ldi     0                   ; zero high word
           plo     r8

           ldi     LMPSHIFT            ; get shift count
           plo     re                  ; and put into shift counter

sectolmp1: glo     r7                  ; perform shift
           shl
           plo     r7
           ghi     r7
           shlc
           phi     r7
           glo     r8
           shlc
           plo     r8
           dec     re                  ; decrement shift count
           glo     re                  ; check for completion
           lbnz    sectolmp1           ; loop back if more shifts needed

           sep     sret                ; return to caller


; ********************************************
; *** Convert lump to latSector, latOffset ***
; *** RA - lump                            ***
; *** Returns: R8.0:R7 - lat sector        ***
; ***             R9 - lat offset          ***
; ********************************************
lmpsecofs: glo     ra                  ; get low byte of lump
           shl                         ; multiply by 2
           plo     r9                  ; put into offset
           ldi     0
           shlc                        ; propagate carry
           phi     r9                  ; R9 now has lat offset

           ghi     ra                  ; get high byte of lump
           adi     low 17              ; add in base of lat table
           plo     r7                  ; place into r7
           ldi     0
           adci    high 17             ; propagate the carry
           phi     r7

           ldi     0                   ; need to zero R8
           plo     r8

           sep     sret                ; return to caller




rawwrite:  glo   r9                     ; preserve work register
           stxd
           ghi   r9
           stxd

           glo   rf                     ; preserve work register
           stxd
           ghi   rf
           stxd

           glo   rd
           adi   4
           plo   r9
           ghi   rd
           adci  0
           phi   r9

           lda   r9                     ; get dta address
           phi   rf
           lda   r9
           plo   rf

           inc   r9                     ; move to flags
           inc   r9

           ldn   r9                     ; clear dirty flag
           ani   255-1
           str   r9

           glo   rd                     ; point to sector lsb
           adi   18
           plo   r9
           ghi   rd
           adci  0
           phi   r9

           sex   r9                     ; so we can use stxd

           glo   r7                     ; fill in sector number
           stxd
           ghi   r7
           stxd
           glo   r8
           stxd
           ghi   r8
           str   r9

           ori   0e0h                   ; set legacy lba bits
           phi   r8

           sep   scall                  ; write sector out
           dw    d_idewrite

           ldn   r9
           phi   r8

           irx                          ; restore work register
           ldxa
           phi   rf
           ldxa
           plo   rf

           ldxa
           phi   r9
           ldxa
           plo   r9

           sep   sret                   ; return



; ***************************************
; *** Read raw sector                 ***
; *** R8:R7 - Sector address to read  ***
; ***    RD - File descriptor         ***
; ***************************************


rawread:    glo   r9
            stxd
            ghi   r9
            stxd

            glo   rd                    ; save pointer and move to sector
            adi   18
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            sex   r9                    ; do read if sector lsb different
            glo   r7
            sm
            lbnz  needread

            dec   r9                    ; do read if next lsb different
            ghi   r7
            sm
            lbnz  needread

            dec   r9                    ; do read if next msb different
            glo   r8
            sm
            lbnz  needread

            dec   r9                    ; do read if msb different
            ghi   r8
            sm
            lbnz  needread

            sex   r2

            irx                        ; else just restore and return
            ldxa
            phi   r9
            ldx
            plo   r9

            sep   sret

needread:   sex   r2

            glo   rf                   ; save current rf
            stxd
            ghi   rf
            stxd

            glo   rd                    ; point to dta
            adi   4
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            lda   r9                    ; get dta address
            phi   rf
            lda   r9
            plo   rf

            inc   r9                    ; move to flags
            inc   r9

            ldn   r9                    ; if not dirty then don't write
            ani   1
            lbz   nodirty


            ldn   r9                    ; clear dirty flag
            xri   1
            str   r9

            glo   r7                    ; save sector to load
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd

            glo   rd                    ; move to sector address
            adi   15
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            lda   r9                    ; get sector address
            phi   r8
            lda   r9
            plo   r8
            lda   r9
            phi   r7
            lda   r9
            plo   r7
            sep   scall                 ; write out current sector
            dw    d_idewrite

            ghi   rf
            smi   2
            phi   rf

            irx                         ; restore sector to read
            ldxa
            phi   r8
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7



nodirty:    glo   rd
            adi   18
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            sex   r9

            glo   r7
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            str   r9

            ori   0e0h
            phi   r8

            sep   scall
            dw    d_ideread

            ldn   r9
            phi   r8

            irx
            ldxa
            phi   rf
            ldxa
            plo   rf

            ldxa
            phi   r9
            ldx
            plo   r9

            adi   0
            sep   sret



; *************************************
; *** write sector using sysfildes  ***
; *** R8:R7 - sector to write       ***
; *************************************
writesys:  glo     rd
           stxd
           ghi     rd
           stxd
           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the sector
           dw      rawwrite
           irx                         ; restore consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; return to caller

; *************************************
; *** read sector using sysfildes   ***
; *** R8:R7 - sector to read        ***
; *************************************
readsys:   glo     rd
           stxd
           ghi     rd
           stxd

           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd

           sep     scall               ; read the sector
           dw      rawread

           irx                         ; restore consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd

           sep     sret                ; return to caller


; **********************************
; *** Get starting lump for file ***
; *** RD - file descriptor       ***
; *** Returns: RA - lump         ***
; **********************************

startlump: glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd

           glo     rd                  ; point to dir sector
           adi     9
           plo     rd
           ghi     rd
           adci    0
           phi     rd

           lda     rd                  ; retrieve dir sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7

           sep     scall               ; read the directory sector
           dw      readsys

           inc     rd                  ; pointer to starting lump
           ldn     rd
           adi     low (dta+2)
           plo     r7

           dec     rd
           ldn     rd
           adci    high (dta+2)
           phi     r7

           lda     r7                  ; get starting lump
           phi     ra
           ldn     r7
           plo     ra

           glo     rd                  ; restore rd to beginning
           smi     13
           plo     rd
           ghi     rd
           smbi    0
           phi     rd

           irx                         ; recover consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7

           sep     sret                ; and return to caller


; **************************
; *** Write value to lat ***
; *** R8.1 - drive       ***
; *** RA - lump          ***
; *** RF - value         ***
; **************************

writelump: glo     ra                  ; do not allow write of lump 0
           lbnz    writelmp
           ghi     ra
           lbz     return

writelmp:  glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rd
           stxd
           ghi     rd
           stxd

           ldi     high sysfildes      ; get system dta
           phi     rd
           ldi     low sysfildes
           plo     rd

           sep     scall               ; convert lump to sector:offset
           dw      lmpsecofs

           sep     scall               ; read the sector
           dw      rawread

           glo     r9                  ; add offset to dta
           adi     low dta
           plo     r9
           ghi     r9
           adci    high dta
           phi     r9

           ghi     rf                  ; write value
           str     r9
           inc     r9
           glo     rf
           str     r9

           sep     scall
           dw      rawwrite            ; write sector back to disk

popr789d:  irx                         ; recover consumed registers
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7

           sep     sret                ; return to caller


; ******************************
; *** Get next lump in chain ***
; *** R8.1 - drive           ***
; *** RA   - lump            ***
; *** Returns: RA - lump     ***
; ******************************

readlump:  glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rd
           stxd
           ghi     rd
           stxd

           ldi     high sysfildes      ; get system dta
           phi     rd
           ldi     low sysfildes
           plo     rd

           sep     scall               ; convert lump to sector:offset
           dw      lmpsecofs

           sep     scall               ; read the sector
           dw      rawread

           glo     r9
           adi     low dta
           plo     r9
           ghi     r9
           adci    high dta
           phi     r9

           lda     r9                  ; get value
           phi     ra
           ldn     r9
           plo     ra

           lbr     popr789d


; ***************************
; *** Delete a lump chain ***
; *** R8.1 - drive        ***
; *** RA - starting lump  ***
; ***************************
delchain:  glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
delchlp:   ghi     ra                  ; make copy of lump
           phi     rc
           glo     ra
           plo     rc
           sep     scall               ; read lump value
           dw      readlump
           ghi     ra                  ; move to rb
           phi     rb
           glo     ra
           plo     rb
           ghi     rc                  ; transfer original copy back to ra
           phi     ra
           glo     rc
           plo     ra
           ldi     0                   ; need to zero it
           phi     rf
           plo     rf
           sep     scall               ; write the lump
           dw      writelump
           ghi     rb                  ; move next lump value to ra
           phi     ra
           glo     rb
           plo     ra
           smi     0feh                ; check for end of chain
           lbnz    delchlp             ; loop back if not
           ghi     ra                  ; check high byte too
           smi     0feh
           lbnz    delchlp
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller

; ***********************************
; *** Check for last lump and eof ***
; *** sets flags and/or eof value ***
; *** RD - file descriptor        ***
; *** RA - lump                   ***
; ***********************************
cklstlmp:  glo     r7                  ; save lump value
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save lump value
           stxd
           ghi     r8
           stxd
           glo     ra                  ; save lump value
           stxd
           ghi     ra
           stxd
           glo     rf                  ; save lump value
           stxd
           ghi     rf
           stxd
           sep     scall               ; read value of lump
           dw      readlump
           glo     ra                  ; see if on last lump
           smi     0feh
           lbnz    cklstno             ; jump if not last
           ghi     ra                  ; check high value as well
           smi     0feh
           lbnz    cklstno
           sep     scall               ; get descriptor flags
           dw      getfdflgs
           ori     4                   ; set last lump flag
           sep     scall               ; and write it back
           dw      setfdflgs

           sep     scall               ; get file offset
           dw      getfdeof
           ghi     rf
           ani     LMPMASK             ; and mask the high byte
           stxd                        ; then store for later
           glo     rf
           stxd
           ldi     0
           sep     scall
           dw      getfddwrd
;           sep     scall               ; get file offset
;           dw      getfdofs
           glo     r7                  ; subtract eof from offset
           irx                         ; move to eof on stack
           sm                          ; perform subtract
           irx                         ; point to high byte
           ghi     r7                  ; need to mask high byte
           ani     LMPMASK             ; keep only offset portion
           smb                         ; perform subtract of high byte
           lbnf    cklstdone           ; jump if not beyond eof
           glo     r7                  ; get offset
           plo     rf                  ; and move for eof
           ghi     r7
           ani     LMPMASK             ; need to mask high byte
           phi     rf
           sep     scall               ; write eof back
           dw      setfdeof
           lbr     cklstdone           ; recover registers and return
cklstno:   sep     scall               ; get flags
           dw      getfdflgs
           ani     0fbh                ; clear last lump flag
           sep     scall               ; and write it back
           dw      setfdflgs
cklstdone: irx                         ; recover registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; and return to caller


; *********************************
; *** Load corresponding sector ***
; *** RD - file descriptor      ***
; *********************************
loadsec:   glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd

           lda     rd                  ; get current offset
           shr                         ; need to shift by 9
           plo     r8                  ; perform shift by 8
           lda     rd
           shrc
           phi     r7
           ldn     rd
           shrc
           plo     r7

           dec     rd                  ; move descriptor back to beginning
           dec     rd

           sep     scall
           dw      getdrive

           sep     scall               ; get lump count
           dw      sectolump

           ghi     ra                  ; transfer to count
           phi     rc
           glo     ra
           plo     rc

           sep     scall               ; get starting lump for file
           dw      startlump

ldseclp:   ghi     rc                  ; see if done
           lbnz    ldsecgo             ; more to do
           glo     rc
           lbnz    ldsecgo

ldsecct:   ldi     LMPSHIFT            ; get the shift count
           plo     r8                  ; R8.0 will be the count
           ldi     0                   ; will user R8.1 to build mask
           phi     r8

ldsctlp1:  glo     r8                  ; see if more shifts are needed
           lbz     ldsectg1            ; jump if not

           ghi     r8                  ; otherwise perform a shift
           shl
           ori     1                   ; set low bit
           phi     r8                  ; put it back
           dec     r8                  ; decrement the shift count
           lbr     ldsctlp1            ; loop back until shifts are done

ldsectg1:  ghi     r8                  ; get mask
           str     r2                  ; and put in memory for use

           glo     r7                  ; get sector offset
           and                         ; mask out lump portion
           plo     rc                  ; save it

           sep     scall               ; convert lump to sector
           dw      lumptosec

           glo     rc                  ; get offset
           str     r2                  ; and add to sector

           glo     r7
           add
           plo     r7
           ghi     r7
           adci    0
           phi     r7
           glo     r8
           adci    0
           plo     r8

           sep     scall
           dw      getdrive

           sep     scall               ; now read the sector
           dw      rawread

           sep     scall               ; check for final lump/eof
           dw      cklstlmp

           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7

           sep     sret                ; and return to caller

ldsecgo2:  dec     rc                  ; decrement lump count
           irx                         ; remove saved lump from stack
           irx
           lbr     ldseclp             ; and keep looking

ldsecgo:   glo     ra                  ; save lump number
           stxd
           ghi     ra
           stxd

           sep     scall               ; get next lump in chain
           dw      readlump

           glo     ra                  ; see if have last lump of file
           smi     0feh
           lbnz    ldsecgo2            ; jump if not

           ghi     ra                  ; check high byte
           smi     0feh
           lbnz    ldsecgo2

           irx                         ; recover last lump number
           ldxa
           phi     ra
           ldx
           plo     ra

ldsecadlp: sep     scall               ; append a lump to the file
           dw      append

           sep     scall               ; read new lump value
           dw      readlump

           dec     rc                  ; decrement the count
           glo     rc                  ; get count
           lbnz    ldsecadlp           ; jump if need to add more
           ghi     rc                  ; check high byte as well
           lbnz    ldsecadlp

           glo     rf                  ; save RF
           stxd
           ghi     rf
           stxd

           ldi     0                   ; set eof for new lump
           phi     rf
           plo     rf

           sep     scall               ; write to descriptor
           dw      setfdeof

           irx                         ; recover RF
           ldxa
           phi     rf
           ldx
           plo     rf

           lbr     ldsecct             ; then continue


; ***********************************
; *** Seek file descriptor to end ***
; *** RD - file descriptor        ***
; ***********************************
seekend:   glo     r7                  ; save registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save registers
           stxd
           ghi     r8
           stxd
           glo     ra                  ; save registers
           stxd
           ghi     ra
           stxd
           glo     rf                  ; save registers
           stxd
           ghi     rf
           stxd
           ldi     0                   ; set offset to zero
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall               ; get starting lump for file
           dw      startlump
           sep     scall               ; read next lump
           dw      readlump
seekendlp: glo     ra                  ; see if have last lump
           smi     0feh
           lbnz    seekendgo           ; jump if not
           ghi     ra                  ; check high byte too
           smi     0feh
           lbnz    seekendgo
           sep     scall               ; get file offset
           dw      getfdeof
           glo     rf                  ; add into offset
           str     r2
           glo     r7
           add
           plo     r7
           ghi     rf
           str     r2
           ghi     r7
           adc
           phi     r7
           glo     r8
           adci    0
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           ldi     0
           sep     scall
           dw      setfddwrd
;           sep     scall               ; write offset to descriptor
;           dw      setfdofs
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller
seekendgo: ldi     LMPSHIFT            ; get the shift count
           plo     re                  ; and place into the loop counter
           ldi     02h                 ; set intial value at 512 bytes
           phi     rf
           ldi     0
           plo     rf
seeklp1:   glo     re                  ; see if done with shifts
           lbz     seekendg1           ; jump if so
           dec     re                  ; otherwise decrement count
           ghi     rf                  ; and update bytes per lump
           shl
           phi     rf
           lbr     seeklp1             ; loop until correct number of shifts
seekendg1: ghi     r7                  ; add bytes per lump to offset
           str     r2             
           ghi     rf
           add
           phi     r7
           glo     r8                  ; propagate carry
           adci    0
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           sep     scall               ; read value of next lump
           dw      readlump
           lbr     seekendlp           ; loop until end found

; ************************************************
; *** Perform file seek                        ***
; *** R8:R7 - offset                           ***
; ***    RD - file descriptor                  ***
; ***    RC - Whence 0-start, 1-current, 2-eof ***
; *** Returns: R8:R7 - original position       ***
; ************************************************
seek:      sep     scall               ; check for valid FILDES
           dw      chkvld
           lbnf    seekgo              ; jump if FILDES is good
           ldi     2                   ; signal invalid FILDES
           sep     sret                ; and return
seekgo:    inc     rd                  ; point to low byte
           inc     rd
           inc     rd
           glo     rc                  ; get whence
           lbnz    seeknot0            ; jump if not 0
seekcont2: ghi     r8                  ; check for negative offset
           shl
           lbnf    seekgo2             ; jump if offset is positive
           ldi     00dh                ; signal error
           shr
           dec     rd                  ; restore rd
           dec     rd
           dec     rd
           sep     sret                ; and return
seekgo2:   glo     r7                  ; transfer new offset
           str     rd
           dec     rd
           ghi     r7
           str     rd
           dec     rd
           glo     r8
           str     rd
           dec     rd
           ghi     r8
           str     rd

seekcont:  sep     scall               ; read the corresponding sector
           dw      loadsec

; *****************************************************
; *** Code added to check for seek past end of file ***
; *****************************************************
           sep     scall               ; check if pointer is at or past eof
           dw      checkeof
           lbnf    seekret             ; return to caller if not

           glo     rd                  ; save rd
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save rf
           stxd
           ghi     rf
           stxd

           inc     rd                  ; point 2nd lsb of ofs
           inc     rd
           lda     rd                  ; get msb of lump offset
           ani     LMPMASK             ; and mask it
           phi     rf                  ; save into rf
           lda     rd                  ; get low byte of lump offset
           plo     rf                  ; rf now holds new eof
           inc     rd                  ; move past dta field
           inc     rd
           ghi     rf                  ; write new eof
           str     rd
           inc     rd                  ; point to lsb of eof
           glo     rf                  ; and write rest of eof
           str     rd
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldx
           plo     rd

seekret:   lda     rd                  ; retrieve file pointer into R8:R7
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           ldn     rd
           plo     r7
           dec     rd                  ; restore RD
           dec     rd
           dec     rd
           adi     0                   ; clear DF
           sep     sret                ; and return to caller

seeknot0:  smi     1                   ; check for seek from current
           lbnz    seeknot1            ; jump if not

seekct2:   glo     r7                  ; add file position to offset
           str     r2
           ldn     rd
           add
           plo     r7
           dec     rd
           ghi     r7
           str     r2
           ldn     rd
           adc
           phi     r7
           dec     rd
           glo     r8
           str     r2
           ldn     rd
           adc
           plo     r8
           dec     rd
           ghi     r8
           str     r2
           lda     rd
           adc
           phi     r8
           inc     rd                  ; put rd back at lsb
           inc     rd
           lbr     seekcont2           ; and then perform seek


;seekct2:   glo     r7                  ; add offset to current offset
;           str     r2                  ; place into memory for add
;           ldn     rd                  ; get value from descriptor
;           plo     r7                  ; keep copy
;           add                         ; add new offset
;           str     rd                  ; store new offset
;           dec     rd                  ; point to previous byte
;           ghi     r7                  ; add offset to current offset
;           str     r2                  ; place into memory for add
;           ldn     rd                  ; get value from descriptor
;           phi     r7                  ; keep copy
;           adc                         ; add new offset
;           str     rd                  ; store new offset
;           dec     rd                  ; point to previous byte
;           glo     r8                  ; add offset to current offset
;           str     r2                  ; place into memory for add
;           ldn     rd                  ; get value from descriptor
;           plo     r8                  ; keep copy
;           adc                         ; add new offset
;           str     rd                  ; store new offset
;           dec     rd                  ; point to previous byte
;           ghi     r8                  ; add offset to current offset
;           str     r2                  ; place into memory for add
;           ldn     rd                  ; get value from descriptor
;           phi     r8                  ; keep copy
;           adc                         ; add new offset
;           str     rd                  ; store new offset
;           lbr     seekcont            ; load new sector
seeknot1:  smi     1                   ; check for seek from end
           lbnz    seeknot2
           dec     rd                  ; move to beginning of descriptor
           dec     rd
           dec     rd
           sep     scall               ; move pointer to end of file
           dw      seekend
           inc     rd                  ; point to low byte
           inc     rd
           inc     rd
           lbr     seekct2
seeknot2:  dec     rd                  ; restore descriptor
           dec     rd
           dec     rd
           ldi     0fh                 ; signal error
           shr
           sep     sret                ; and return to caller


          ; Open Master Directory File
          ;
          ; Returns DF set if error, otherwise file descriptor RD is open.
          ;
          ; Input:   RF - Drive ID (ASCIIZ) pointer
          ;          RD - File descriptor pointer

openmd:     glo   r7                     ; save working registers
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd
            glo   r9
            stxd
            ghi   r9
            stxd
            glo   ra
            stxd
            ghi   ra
            stxd

            ldi   0                     ; sector 0 of drive 0
            plo   r7
            phi   r7
            plo   r8
            phi   r8


          ; Try to read the drive identifier as an ASCII decimal number.
          ; If that succeeds, use it, otherwise we'll treat is as a label.

            sep   scall                 ; get drive id if number
            dw    f_atoi
            lbnf  mdnumber

            ldn   rf                    ; if empty then error
            lbz   mdreturn
            smi   '/'
            lbz   mdreturn


          ; Since the drive ID is non-numeric, search all the drive system
          ; sectors for the label that was specified.

            ldi   intfildes.1
            phi   rd
            ldi   intfildes.0
            plo   rd

            ldi   high (intdta+100h)    ; pointer to filesystem data
            phi   r9

mdsearch:   sep   scall                 ; read system sector
            dw    rawread

            ldi   low 104h              ; pointer to filesystem type
            plo   r9

            ldn   r9                    ; if not type one then skip
            smi   1
            lbnz  mdnextdr

            ldi   low 12ch+0ch          ; pointer to volume label
            plo   r9

            glo   rf                    ; save drive id pointer
            stxd
            ghi   rf
            stxd


          ; Compare the identifier to the label on the disk. A successful
          ; match is terminated with either a zero byte or a slash.

            sex   rf                    ; for sm to compare

mdstrcmp:   lda   r9                    ; get next char, jump if end
            lbz   mdendstr

            sm                          ; compare char, loop if match
            inc   rf
            lbz   mdstrcmp

            lbr   mdnoname              ; else there is no match


mdendstr:   ldn   rf                    ; success if zero or slash
            lbz   mdfound
            smi   '/'                
            lbz   mdfound

            lbr   mdnoname              ; otherwise fail


          ; If the label was found, leave RF pointing to the terminating
          ; character and fill in the file descriptor.

mdfound:    sex   r2                    ; if match then setup fd

            irx                         ; discard start of string
            irx

            lbr   mdopener              ; open file descriptor


          ; If no match, then restore the identifier pointer and loop back
          ; and check the next drive.

mdnoname:   sex   r2                    ; else restore id and try again

            irx
            ldxa
            phi   rf
            ldx
            plo   rf

mdnextdr:   ghi   r8                    ; advance to next drive
            adi   1
            phi   r8

            smi   32                    ; if not last drive check next
            lbnz  mdsearch

            lbr   mdreturn              ; and return


          ; If drive identifier was numeric, then just load the system sector
          ; from that drive.

mdnumber:   glo   rd                    ; set drive number
            phi   r8

            ldi   intfildes.1
            phi   rd
            ldi   intfildes.0
            plo   rd

            sep   scall                 ; read system sector
            dw    rawread


          ; Fill in the file descriptor with the master directory information
          ; and load the first data sector, the same as if open was called.

mdopener:   ldi   low 12ch              ; dir offset in system data sector
            plo   r9 
            ldi   high 12ch
            phi   r9

            glo   rf
            stxd
            ghi   rf
            stxd

            ldi   low (intdta+12ch)
            plo   rf
            ldi   high (intdta+12ch)
            phi   rf

            sep   scall                 ; read first sector
            dw    setupfd

            irx
            ldxa
            phi   rf
            ldx
            plo   rf

            adi   0                     ; signal success

mdreturn:   irx                         ; recover used registers
            ldxa
            phi   ra
            ldxa
            plo   ra
            ldxa
            phi   r9
            ldxa
            plo   r9
            ldxa
            phi   r8
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7

            sep   sret                  ; return to caller


; **************************************
; *** Get a free lump                ***
; *** Input:   R8.1 - drive          ***
; *** Returns: RA - lump             ***
; ***          DF=0 - lump found     ***
; ***          DF=1 - lump not found *** 
; **************************************

freelump:  glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           glo     rd
           stxd
           ghi     rd
           stxd
           glo     rf
           stxd
           ghi     rf
           stxd

           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd

           ldi     0                   ; zero high word
           plo     r8
           phi     r7
           plo     r7

           sep     scall               ; read sector 0
           dw      rawread

           ldi     low dta             ; point to sector
           adi     low 261             ; add 261, address of md sector
           plo     rf
           ldi     high dta
           adci    high 261
           phi     rf

           lda     rf                  ; get sector value
           phi     rb
           lda     rf
           plo     rb

           ldi     17
           plo     r7

freelump1: glo     rb                  ; check if end of lat table
           str     r2
           glo     r7
           sm
           lbnz    freelump2           ; jump if not
           ghi     rb                  ; check if end of lat table
           str     r2
           ghi     r7
           sm
           lbnz    freelump2           ; jump if not

           ldi     1                   ; signal no lump was found

freelumpe: shr                         ; shift result
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller

freelump2: sep     scall               ; read next allocation sector
           dw      rawread

           ldi     high dta            ; point to dta
           phi     r9
           ldi     low dta
           plo     r9

           ldi     1                   ; 256 entries per sector
           phi     rc
           ldi     0
           plo     rc

freelump3: lda     r9                  ; get value from table
           lbnz    freelump4           ; jump if nonzero
           ldn     r9                  ; check low value
           lbnz    freelump4           ; jump if nonzero

           dec     r9                  ; reset offset

           ghi     r9                  ; subtract out buffer address
           smi     1
           phi     r9

           glo     r7                  ; subtract 17 from sector number
           smi     17
           phi     ra                  ; place into ra (* 256)

           ghi     r9                  ; offset divided by 2
           shr
           glo     r9
           shrc
           plo     ra

           ldi     0                   ; signal a lump was found
           lbr     freelumpe           ; and return

freelump4: inc     r9                  ; point to next entry

           dec     rc                  ; decrement count
           glo     rc                  ; check if end
           lbnz    freelump3           ; loop back if more to check

           inc     r7                  ; increment sector number
           lbr     freelump1


; *************************************
; *** Append a lump to current file ***
; *** RD - file descriptor          ***
; *** Returns DF=0 - success        ***
; ***         DF=1 - failed         ***
; *************************************

append:    ghi     r8
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd

           sep     scall
           dw      getdrive

           sep     scall               ; find a free lump
           dw      freelump
           lbnf    append1             ; jump if one was found

           ldi     1                   ; signal an error

appende:   shr                         ; shift into df
           irx                         ; recover consumed register
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldx
           phi     r8
           sep     sret                ; and return to caller

append1:   glo     rb                  ; save additional registers
           stxd
           ghi     rb
           stxd
           glo     rc                  ; save additional registers
           stxd
           ghi     rc
           stxd
           glo     rf                  ; save additional registers
           stxd
           ghi     rf
           stxd

           ghi     ra                  ; move new lump
           phi     rc
           glo     ra
           plo     rc

           sep     scall               ; get first lump of file
           dw      startlump

           ghi     ra                  ; copy start lump to temp
           phi     rb
           glo     ra
           plo     rb

append2:   glo     ra                  ; get for end of chain code
           smi     0feh
           lbnz    append3             ; jump if not
           ghi     ra
           smi     0feh
           lbnz    append3

           lbr     append4             ; end found

append3:   ghi     ra                  ; copy lump to temp
           phi     rb
           glo     ra
           plo     rb

           sep     scall               ; get next lump
           dw      readlump

           lbr     append2             ; loop until last lump is found

append4:   ghi     rb                  ; transfer lump
           phi     ra
           glo     rb
           plo     ra
           ghi     rc                  ; transfer new lump
           phi     rf
           glo     rc
           plo     rf

           sep     scall               ; write new lump value
           dw      writelump

           ghi     rc                  ; get new lump
           phi     ra
           glo     rc
           plo     ra

           ldi     0feh                ; end of chain code
           phi     rf
           plo     rf

           sep     scall               ; write new lump value
           dw      writelump

           sep     scall               ; get file descriptor flags
           dw      getfdflgs

           ani     0fbh                ; indicat current sector is not last

           sep     scall               ; and write back
           dw      setfdflgs

           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldx
           plo     rb

           ldi     0                   ; indicate success
           lbr     appende             ; and return


; **********************************
; *** Check if at end of file    ***
; *** RD - file descriptor       ***
; *** Returns: DF=0 - not at end ***
; ***          DF=1 - At end     ***
; **********************************
checkeof:  glo     rf                  ; save rf
           stxd
           ghi     rf
           stxd
           glo     rd                  ; save rd
           stxd
           adi     8                   ; and move to flags
           plo     rd
           plo     rf
           ghi     rd
           stxd
           adci    0
           phi     rd
           phi     rf
           ldn     rd                  ; get flags
           ani     4                   ; see if in final lump
           lbz     noeof               ; jump if not
           dec     rf                  ; move rf to eof low byte
           dec     rd                  ; move rd to current offset
           dec     rd
           dec     rd
           dec     rd
           dec     rd
; ******************************************************************
; *** This was original code which compared for the offset being ***
; *** equal to the eof field.                                    ***
; ******************************************************************
;           ldn     rd                  ; get byte from offset
;           str     r2
;           ldn     rf                  ; get eof byte
;           sm                          ; compare them
;           lbnz    noeof               ; jump if no match
;           dec     rf                  ; move to previous byte
;           dec     rd
;           ldn     rf                  ; get byte from eof
;           str     r2                  ; this byte needs to be masked
;           glo     re                  ; get mask
;           and                         ; and apply to the value
;           stxd                        ; keep value on the stack
;           ldn     rd                  ; get byte from offset
;           str     r2                  ; this value must also be masked
;           glo     re                  ; obtain mask
;           and                         ; and perform the masking
;           irx                         ; move back to the last byte
;           sm                          ; compare values
;           lbnz    noeof               ; jump if not at eof
; ******************************************************************
; *** Replaced with the following code which sees if the current ***
; *** offset is equal OR greater than the eof byte               ***
; ******************************************************************
           ldn     rf                  ; get byte from eof
           str     r2                  ; store for comparison
           ldn     rd                  ; get byte from offset
           sm                          ; and subtract
           dec     rf                  ; move to msb of eof
           dec     rd                  ; move to next most byte of offset
           ldn     rf                  ; get byte from eof
           ani     LMPMASK             ; and mask eof byte
           stxd                        ; save it for now
           ldn     rd                  ; get offset byte
           ani     LMPMASK             ; and mask offset byte
           irx                         ; point x back to masked eof byte
           smb                         ; and continue subtraction
           lbnf    noeof               ; jump if not at or past eof
; ***********************
; *** End of new code ***
; ***********************
ateof:     ldi     1                   ; signal at end
checkeofe: shr                         ; shift result into df
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller
noeof:     ldi     0                   ; signal not at eof
           lbr     checkeofe

; *****************************************
; *** Increment current offset          ***
; *** RD - file descriptor              ***
; *** Returns: DF=1 - new sector loaded ***
; *****************************************

incofs1:   inc     rd                  ; move to 3rd byte
           inc     rd

           ldn     rd                  ; retrieve it

           dec     rd                  ; move back to beginning
           dec     rd

           plo     re                  ; keep a copy
           ani     1
           lbnz    incofse1            ; jump if not zero

           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd

           glo     re                  ; of the current file pointer
           ani     LMPMASK             ; combine with mask
           plo     re                  ; and keep in re

           glo     rd                  ; move descriptor to current sector
           adi     15
           plo     rd
           ghi     rd
           adci    0
           phi     rd

           lda     rd                  ; get current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7

           glo     rd                  ; move descriptor back to beginning
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd

           glo     re                  ; recover byte 3rd byte of file pointer
           lbz     incofslmp           ; need a new lump

           inc     r7                  ; increment count

           glo     r7                  ; see if rollover happened
           lbnz    incofs2             ; jump if not
           ghi     r7
           lbnz    incofs2

           inc     r8                  ; propagate the incrment

incofs2:   sep     scall               ; read the new sector
           dw      rawread

incofse2:  irx                         ; recover consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7

           ldi     1
           shr
           sep     sret                ; return to caller

incofslmp: glo     ra                  ; save additional consumed registers
           stxd
           ghi     ra
           stxd

           sep     scall               ; convert sector to lump
           dw      sectolump

           sep     scall               ; get next lump
           dw      readlump

           sep     scall               ; get first sector of next lump
           dw      lumptosec

           sep     scall               ; read the next sector in
           dw      rawread

           sep     scall               ; get next lump
           dw      readlump

           glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd

           glo     ra                  ; check for ending lump
           smi     0feh                ; check for end of chain code
           lbnz    incofs3             ; jump if not
           ghi     ra
           smi     0feh
           lbnz    incofs3

           ldn     rd                  ; get flags
           ori     4                   ; indicate last lump loaded

incofs4:   str     rd                  ; put it back

           glo     rd                  ; move descriptor back
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd

           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldx
           plo     ra

           lbr     incofse2

incofs3:   ldn     rd                  ; get flags
           ani     0fbh                ; indicate not last lump

           lbr     incofs4             ; and continue

incofse1:  ldi     0
           shr
           sep     sret                ; return to caller


; ***************************************
; *** Check for valid file descriptor ***
; *** RD - file descriptor            ***
; *** Returns: DF=0 - valid FILDES    ***
; ***          DF=1 - Invalid FILDES  ***
; ***************************************
chkvld:    push    rd                  ; save file descriptor position
           glo     rd                  ; point to flags byte
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags byte
           plo     re                  ; save it for a moment
           pop     rd                  ; recover file descriptor
           glo     re                  ; recover flags
           ani     08h                 ; if FILDES marked valid
           lbz     chkvldno            ; jump if not
           ldi     0                   ; mark good
           shr
           sep     sret                ; and return
chkvldno:  ldi     1                   ; mark invalid
           shr
           sep     sret                ; and return


           ; Read bytes from file
           ;
           ; Input:
           ;   RC - Number of bytes to read
           ;   RD - Pointer to file descriptor
           ;   RF - Pointer to read buffer
           ;
           ; Output:
           ;   RC - Number of bytes actually read
           ;   RD - Unchanged
           ;   RF - Points after last byte read
           ;   DF - Set if error occurred
           ;   D  - Error code

read:      sep     scall
           dw      chkvld
           lbnf    rdvalid

           ldi     2<<1 + 1            ; return d=2, df=1, invalid fd
           lbr     reterror

           ; Check size of read request, if it's zero, declare success.

rdvalid:   glo     rc                  ; if there is nothing to do, return
           lbnz    nonzero
           ghi     rc
           lbz     reterror            ; return d=0, df=0, success

nonzero:   glo     r8                  ; save r8.0 to use for flags
           stxd

           glo     r9                  ; save r9 to use for dta pointer
           stxd
           ghi     r9
           stxd

           glo     ra                  ; save ra for bytes requested
           stxd
           ghi     ra
           stxd

           glo     rb                  ; save rb to use for loop counter
           stxd
           ghi     rb
           stxd

           glo     rc                  ; copy bytes requested to ra
           plo     ra
           ghi     rc
           phi     ra

           ldi     0
           plo     r8                  ; clear flags byte
           plo     rc                  ; clear bytes read counter
           phi     rc


           ; loops back to here

readloop:  inc     rd
           inc     rd                  ; rd = fd+2 (file offset nlsb)


           ; Check if we have already checked for an eof adjustment to 
           ; reduce the read bytes requested, if so, dont do it again.

           glo     r8
           ani     1
           lbnz    readdata


           ; The following checks if we are in the "final lump" which is the
           ; last allocation unit in the file, and if so, we are near eof.
           ; Its not actually easily possible to know how much data is
           ; remaining in the file until we get to this point, as eof is only
           ; stored relative to the start of this final allocation unit.

           glo     rd                  ; this way we dont have to fix the
           adi     6                   ; result back if the branch below not
           plo     rb                  ; taken, also the separate copy is
           ghi     rd                  ; used even if the branch is taken
           adci    0
           phi     rb                  ; rb = fd+8 (flags)

           ldn     rb                  ; check final lump flag
           ani     4
           lbz     readdata


           ; If we are in the final lump, then calculate how much data is
           ; remaining in the file and if more data has been requested than
           ; is in the file, reduce the request to match what is available.
           ; Since the request size is kept across loops, this adjustment
           ; only needs to be done once, and only can be done once.

           inc     r8                  ; remember weve already done this

           dec     rb                  ; rb = fd+7 (eof offset lsb)
           inc     rd                  ; rd = fd+3 (file offset lsb)

           ldn     rb                  ; get eof offset lsb and subtract file
           sex     rd                  ; offset lsb from it
           sm 
           plo     r9

           dec     rd                  ; rd = fd+2 (file offset nlsb)
           dec     rb                  ; rb = fd+6 (eof offset msb)

           ldi     LMPMASK             ; and lump mask msb with file offset
           and                         ; nlsb, then subtract from eof offset
           sex     rb                  ; msb
           sdb
           phi     r9                  ; r9 = bytes to eof
           sex     r2

           lbnz    readneof            ; if bytes remaining to eof are not
           glo     r9                  ; zero then continue reading
           lbz     readpopr

readneof:  glo     r9
           str     r2
           glo     ra                  ; compare bytes left in file to bytes
           sd                          ; requested to read (ra)
           ghi     r9
           str     r2
           ghi     ra
           sdb
           lbdf    readdata            ; if ra <= bytes left leave as-is

           ghi     r9                  ; else replace request count with
           phi     ra                  ; what is actually left in file
           glo     r9 
           plo     ra


           ; Setup the source copy pointer into the current sector in memory
           ; and determine how much data we are going to copy, which will be
           ; the lesser of whats left in the sector or what was requested.

readdata:  lda     rd                  ; get sector offset as low 9 bits of
           ani     1
           phi     rb
           lda     rd                  ; rd = fd+4 (dta msb)
           plo     rb                  ; rb = sector offset

           sex     rd                  ; add dta address to sector offset
           inc     rd                  ; in rb and put result into r9
           glo     rb                  ; as copy source pointer
           add
           plo     r9
           dec     rd
           ghi     rb
           adc
           phi     r9                  ; rd = fd+4 (dta msb)
           sex     r2

           glo     rb                  ; find what is left in sector by
           sdi     low 512             ; subtracting sector offset from 512
           plo     rb                  ; overwrite original value
           ghi     rb
           sdbi    high 512
           phi     rb

           glo     rb                  ; compare bytes requested to bytes
           str     r2
           glo     ra                  ; left in sector
           sm 
           ghi     rb
           str     r2
           ghi     ra
           smb
           lbdf    readleft            ; if fewer in sector, read that many

           ghi     ra                  ; otherwise read what was requested
           phi     rb
           glo     ra
           plo     rb
           lbr     readupdt

readleft:  inc     r8                  ; set flag to load more data
           inc     r8

readupdt:  glo     rb
           str     r2
           glo     ra                  ; subtract bytes we are going to copy 
           sm                          ; from bytes requested and at the 
           plo     ra                  ; same time put into loop counter rb
           ghi     rb
           str     r2
           ghi     ra
           smb
           phi     ra

           glo     rb                  ; add bytes we are going to copy to rc
           str     r2
           glo     rc
           add
           plo     rc
           ghi     rb
           str     r2
           ghi     rc
           adc
           phi     rc

           dec     rd                  ; rd = fd+3 (file offset lsb)

           sex     rd                  ; add the amount we are going to copy
           glo     rb                  ; onto the current file offset
           add
           stxd
           ghi     rb
           adc
           stxd
           ldi     0
           adc
           stxd
           ldi     0
           adc
           str     rd                  ; rd = fd+0 (base)
           sex     r2

readcopy:  lda     r9                  ; copy rb bytes from dta at m(r9)
           str     rf                  ; to user buffer at m(rf)
           inc     rf
           dec     rb
           glo     rb
           lbnz    readcopy
           ghi     rb
           lbnz    readcopy

           glo     r8                  ; check if flag is set to read data
           ani     2
           lbz     readrest            ; if not, we are done

           dec     r8                  ; clear read data flag
           dec     r8

           sep     scall               ; get another sector
           dw      incofs1

           glo     ra
           lbnz    readloop
           ghi     ra
           lbnz    readloop            ; and finish satisfying request

           lbr     readrest

readpopr:  dec     rd
           dec     rd                  ; rd = fd+0 (start)

           lbr     readrest



           ; Write bytes to file
           ;
           ; Input:
           ;   RC - Number of bytes to write
           ;   RD - Pointer to file descriptor
           ;   RF - Pointer to write buffer
           ;
           ; Output:
           ;   RC - Number of bytes actually written
           ;   RD - Unchanged
           ;   RF - Points after last byte written
           ;   DF - Set if error occurred
           ;   D  - Error code

write:     sep     scall
           dw      chkvld
           lbnf    wrvalid

           ldi     2<<1 + 1            ; return d=2, df=1, invalid fd
           lbr     reterror

           ; Check size of read request, if it's zero, declare success.

wrvalid:   glo     rc                  ; if there is nothing to do, return
           lbnz    chkwrite
           ghi     rc
           lbz     reterror            ; return d=0, df=0, success


           ; Only if this is a write operation, check the read-only flag.

chkwrite:  glo     re                  ; check if fd is read-only
           ani     2
           lbz     nordonly

           ldi     1<<1 + 1            ; return d=1, df=1, read-only
           lbr     reterror


           ; Push the registers that are used that are common to both
           ; the read and write code paths and initialize some register
           ; values that are also common to both. Put the read or write
           ; indicator into RE.0 at this point to survive the pushes.

nordonly:  glo     r8                  ; save r8.0 to use for flags
           stxd

           glo     r9                  ; save r9 to use for dta pointer
           stxd
           ghi     r9
           stxd

           glo     ra                  ; save ra for bytes requested
           stxd
           ghi     ra
           stxd

           glo     rb                  ; save rb to use for loop counter
           stxd
           ghi     rb
           stxd

           glo     rc                  ; copy bytes requested to ra
           plo     ra
           ghi     rc
           phi     ra

           ldi     0
           plo     r8                  ; clear flags byte
           plo     rc                  ; clear bytes read counter
           phi     rc

           ; The write-specific code starts from here, this is reached by
           ; the LSKP instruction on the proir page.

           glo     r6                  ; save r9 to use for dta pointer
           stxd
           ghi     r6
           stxd

           glo     r7                  ; save r9 to use for dta pointer
           stxd
           ghi     r7
           stxd


           ; Processing of write operations loops back to here

writloop:  inc     rd
           inc     rd                  ; rd = fd+2 (file offset nlsb)

           lda     rd                  ; get sector offset as low 9 bits of
           ani     1                   ; file offset, save in rb
           phi     rb
           lda     rd                  ; rd = fd+4 (dta msb)
           plo     rb

           sex     rd
           inc     rd                  ; add dta address to sector offset
           glo     rb
           add                         ; on stack and put result into r9
           plo     r9                  ; as copy destination pointer
           dec     rd
           ghi     rb
           adc
           phi     r9
           sex     r2

           glo     rb                  ; find the space left in sector by
           sdi     low 512             ; subtracting sector offset from 512
           plo     rb                  ; overwrite original value
           ghi     rb
           sdbi    high 512
           phi     rb

           glo     rb                  ; compare bytes to write to bytes
           str     r2                  ; left in sector
           glo     ra
           sm 
           ghi     rb
           str     r2
           ghi     ra
           smb
           lbdf    writleft            ; if fewer in sector, write that many

           ghi     ra                  ; otherwise write what was requested
           phi     rb
           glo     ra
           plo     rb
           lbr     writupdt

writleft:  inc     r8                  ; set flag to load more data
           inc     r8

writupdt:  glo     rb
           str     r2
           glo     ra                  ; subtract bytes we are going to copy 
           sm                          ; from bytes requested and at the 
           plo     ra                  ; same time put into loop counter rb
           ghi     rb
           str     r2
           ghi     ra
           smb
           phi     ra

           glo     rb
           str     r2
           glo     rc
           add
           plo     rc
           ghi     rb
           str     r2
           ghi     rc
           adc
           phi     rc

           dec     rd                  ; rd = fd+3 (file offset lsb)

           sex     rd                  ; add the amount we are going to copy
           glo     rb                  ; onto the current file offset
           add
           stxd
           ghi     rb
           adc
           stxd
           ldi     0
           adc
           stxd
           ldi     0
           adc
           str     rd                  ; rd = fd+0 (base)
           sex     r2

           ; The following checks if we are in the "final lump" which is the
           ; last allocation unit in the file, and if so, we are near eof.
           ; Its not actually easily possible to know how much data is
           ; remaining in the file until we get to this point, as eof is only
           ; stored relative to the start of this final allocation unit.

           glo     rd                  ; this way we dont have to fix the
           adi     8                   ; result back if the branch below not
           plo     r7                  ; taken, also the separate copy is
           ghi     rd                  ; used even if the branch is taken
           adci    0
           phi     r7                  ; r7 = fd+8 (flags)

           ldn     r7                  ; get flags 
           ori     16+1                ; mark sector and file as written to
           str     r7
           ani     4                   ; check if in final lump
           lbz     writcopy

           ; If we are in the final lump, then find if the file offset is
           ; past the eof offset, if it is, then update the eof offset to
           ; match the file offset since we are extending the file.

           dec     r7                  ; r7 = fd+7 (eof offset lsb)

           inc     rd
           inc     rd
           inc     rd                  ; rd = fd+3 (file offset lsb)

           ldn     rd                  ; get file offset lsb and subtract eof
           plo     r6
           sex     r7                  ; offset lsb from it
           sd

           dec     rd                  ; rd = fd+2 (file offset nlsb)
           dec     r7                  ; r7 = fd+6 (eof offset msb)

           ldi     LMPMASK             ; and lump mask msb with file offset
           sex     rd
           and                         ; nlsb, then subtract eof offset from it
           phi     r6
           sex     r7                  ; msb
           sdb
           sex     r2

           dec     rd
           dec     rd                  ; rd = fd+0 (begin)

           glo     r6
           lbnz    writnapp
           ghi     r6
           lbnz    writnapp

           sep     scall               ; append a new lump if eof offset
           dw      append              ; wrapped to zero

writnapp:  lbdf    writcopy            ; if eof offset is larger or equal

           ghi     r6
           str     r7
           inc     r7
           glo     r6
           str     r7

           ; Setup the destination copy pointer into the current sector in
           ; memory and determine how much data we are going to copy, which
           ; will be the lesser of whats left in the sector or what was
           ; requested.

writcopy:  lda     rf                  ; copy rb bytes from dta at m(r9)
           str     r9                  ; to user buffer at m(rf)
           inc     r9
           dec     rb
           glo     rb
           lbnz    writcopy
           ghi     rb
           lbnz    writcopy

           glo     r8                  ; check if flag is set to read data
           ani     2
           lbz     writretn            ; if not, we are done

           dec     r8                  ; clear read data flag
           dec     r8

           sep     scall               ; get another sector
           dw      incofs1

           glo     ra
           lbnz    writloop
           ghi     ra
           lbnz    writloop            ; and finish satisfying request

writretn:  inc     r2

           lda     r2                  ; restore saved r9
           phi     r7
           lda     r2
           plo     r7

           lda     r2                  ; restore saved r9
           phi     r6
           ldn     r2
           plo     r6

readrest:  inc     r2

           lda     r2                  ; restore saved rb
           phi     rb
           lda     r2
           plo     rb

           lda     r2                  ; restore saved ra
           phi     ra
           lda     r2
           plo     ra

           lda     r2                  ; restore saved r9
           phi     r9
           lda     r2
           plo     r9

           ldn     r2
           plo     r8

           ldi     0

reterror:  shr
           sep     sret

       
          ; Close a file
          ;
          ; Input:
          ;   RD - file descriptor
          ; Returns:
          ;   DF - set if error

close:      glo   rd                    ; point rd to fildes flags
            adi   8
            plo   rd
            ghi   rd
            adci  0
            phi   rd

            ldn   rd                    ; if not open and written to
            ani   16+8
            smi   16+8
            lbnf  clearflg


          ; Since the file is open and has been written to, update the EOF
          ; count and the date and time in it's directory entry.

            glo   r9                    ; save working registers
            stxd
            ghi   r9
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd
            glo   r7
            stxd
            ghi   r7
            stxd

            inc   rd                    ; skip flags

            lda   rd                    ; get sector of directory entry
            phi   r8
            lda   rd
            plo   r8
            lda   rd
            phi   r7
            lda   rd
            plo   r7

            lda   rd                    ; push offset of directory entry
            stxd
            lda   rd
            stxd

            glo   rd                    ; back to beginning of fildes
            smi   15
            plo   rd
            ghi   rd
            smbi  0
            phi   rd


          ; Note that before rawread loads the directory sector, it will
          ; automatically flush the buffer data first if it's dirty.

            sep   scall                 ; read in directory sector
            dw    rawread

            inc   rd                    ; point to dta address
            inc   rd
            inc   rd
            inc   rd

            inc   rd                    ; add dta address to offset
            ldn   rd
            irx
            add
            plo   r9
            dec   rd
            lda   rd
            irx
            adc
            phi   r9
            inc   rd


          ; R9 now points to the entry within the loaded directory sector.
          ; Update the flags, EOF, and date and time into the buffer.

            inc   r9                    ; skip file allocation unit
            inc   r9
            inc   r9
            inc   r9

            lda   rd                    ; update eof count into entry
            str   r9
            inc   r9
            lda   rd
            str   r9
            inc   r9

            ldn   r9                    ; set archve bit on file
            ori   ff_archive
            str   r9
            inc   r9

            sep   scall                 ; get current date/time
            dw    gettmdt


          ; Clear the file descriptor flags and point back to the start of
          ; the descriptor, then write the diretory sector back out.

            sep   scall                 ; clear flags and reset pointer
            dw    clearflg

            sep   scall                 ; write updated directory entry
            dw    rawwrite

            irx                         ; restore modified registers
            ldxa
            phi   r7
            ldxa
            plo   r7
            ldxa
            phi   r8
            ldxa
            plo   r8
            ldxa
            phi   r9
            ldx
            plo   r9

            sep   sret                  ; return result of rawrite


          ; RD points to the flags byte; clear it, reset RD to the start of
          ; the file descriptor, then return.

clearflg:   ldi   0
            str   rd

            glo   rd
            smi   8
            plo   rd
            ghi   rd
            smbi  0
            phi   rd

            sep   sret


; **********************************
; *** Get current sector, offset ***
; *** RD - file descriptor       ***
; *** Returns R8:R7 - sector     ***
; ***            R9 - offset     ***
; **********************************
getsecofs: inc     rd                  ; move to low word of offset
           inc     rd

           lda     rd                  ; get high byte
           ani     1                   ; strip upper bits
           phi     r9                  ; place into offset
           lda     rd                  ; get low byte
           plo     r9                  ; r9 now has offset

           glo     rd                  ; move pointer to current sector
           adi     11
           plo     rd
           ghi     rd
           adci    0
           phi     rd

           lda     rd                  ; retrieve current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7

           glo     rd                  ; restore descriptor pointer
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd

           sep     sret                ; return to caller

; *****************************************
; *** search directory for an entry     ***
; *** RD - file descriptor (dir)        ***
; *** RF - Where to put directory entry ***
; *** RB - filename (asciiz)            ***
; *** Returns: R8:R7 - Dir Sector       ***
; ***             R9 - Dir Offset       ***
; ***          DF=0  - entry found      ***
; ***          DF=1  - entry not found  ***
; *****************************************
searchdir: ghi     rf                  ; save buffer position
           phi     ra
           glo     rf
           plo     ra

           sep     scall
           dw      getdrive

searchlp:  sep     scall               ; get current sector and offset
           dw      getsecofs

           ghi     ra                  ; get buffer
           phi     rf
           glo     ra
           plo     rf

           ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc

           sep     scall               ; perform read
           dw      o_read

           glo     rc                  ; see if enough bytes were read
           smi     32
           lbnz    searchno            ; jump if end of dir was hit

           ghi     ra                  ; get buffer
           phi     rf
           glo     ra
           plo     rf

           lda     rf                  ; see if entry is valid
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lda     rf
           lbnz    entrygood

           lbr     searchlp            ; entry was no good, try again

entrygood: glo     ra                  ; get pointer to filename in the
           adi     12                  ;  directory entry
           plo     rf
           ghi     ra
           adci    0
           phi     rf

           glo     rb                  ; get copy of filename to match
           plo     rc
           ghi     rb
           phi     rc

cmploop:   lda     rf                  ; compare filenames until end
           lbz     cmpzero
           str     r2
           lda     rc
           xor
           lbz     cmploop

           lbr     searchlp            ; char mismatch, check next entry

cmpzero:   ldn     rc                  ; if length matches, its a find
           lbz     searchyes

           smi     '/'                 ; if length mismatch, keep looking
           lbnz    searchlp

           inc     rc                  ; if ends in slash then skip past it
           lbr     searchyes

searchno:  ldi     1                   ; match not found, return failure
           lbr     searchex

searchyes: ldi     0                   ; match was found, return success

searchex:  shr

           ghi     ra                  ; recover buffer
           phi     rf
           glo     ra
           plo     rf

           sep     sret                ; return to caller


          ; Setup new file descriptor
          ;
          ; Input:
          ;   R8:R7 - Directory entry sector
          ;   R9 - Directory entry offset
          ;   RD - File descriptor to setup
          ;   RF - Pointer to directory entry
          ;
          ; Output:
          ;   R7 - Modified
          ;   R8 - Modified
          ;   R9 - Modified
          ;   RA - Modified
          ;   RD - File descriptor unchanged
          ;   RF - Modified

setupfd:    glo   rd                    ; move pointer to fill downwards
            adi   18.0
            plo   rd
            ghi   rd
            adci  18.1
            phi   rd

            sex   rd                    ; to use stxd to fill

            ldi   -1                    ; clear loaded sector
            stxd
            stxd
            stxd
            stxd

            glo   r9                    ; set directory entry offset
            stxd
            ghi   r9
            stxd

            glo   r7                    ; set directory entry sector
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd

            inc   rf                    ; skip msbs in starting lump
            inc   rf

            lda   rf                    ; get 16-bit starting lump
            phi   ra
            lda   rf
            plo   ra

            lda   rf                    ; get eof from directory entry
            phi   r9
            lda   rf
            plo   r9

            sep   scall                 ; convert lump to starting sector
            dw    lumptosec

            sep   scall                 ; lookup next lump in file
            dw    readlump

            sex   rd                    ; set again since scall reset

            ghi   ra                    ; if not last lump set flags to 8
            smi   0feh
            lbnz  noteof

            glo   ra                    ; if last lump set flags to 8+4
            smi   0feh
            lbz   goteof

noteof:     ldi   4                     ; compute flags value into fd
goteof:     xri   4+8
            str   rd

            ldn   rf                    ; get flags from directory entry,
            shrc                        ;  move low 3 bits to high 3 bits
            shrc
            shrc
            shrc

            ani   0e0h                  ; mask high 3 bits and combine with
            or                          ;  bits already in fd flags
            stxd

            glo   r9                    ; save eof offset into fd
            stxd
            ghi   r9
            stxd

            dec   rd                    ; skip dta address
            dec   rd

            ldi   0                     ; set current offset to zero
            stxd
            stxd
            stxd
            str   rd

            sep   scall                 ; load first sector
            dw    rawread

            sep   sret                   ; return


; ***************************************
; *** Follow a directory tree         ***
; *** RD - Dir descriptor             ***
; *** RF - Pathname                   ***
; *** Returns: RD - final dir in path ***
; ***          DF=0 - success         ***
; ***          DF=1 - error           ***
; ***************************************

follow:    ghi     rf                  ; copy path to rb
           phi     rb
           glo     rf
           plo     rb

findseplp: lda     rf                  ; get byte from pathname
           lbz     founddir            ; jump if no more dirnames
           smi     '/'                 ; check for separator
           lbnz    findseplp           ; keep looping if not found

           ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf

           sep     scall               ; search for name
           dw      searchdir

           lbnf    finddir1            ; jump if entry was found

           ldi     errnoffnd           ; signal an error
           lbr     error

finddir1:  glo     rf                  ; point to flags
           adi     6
           plo     rb
           ghi     rf
           adci    0
           phi     rb

           ldn     rb                  ; get flags
           ani     1                   ; see if entry is a dir
           lbnz    finddir2            ; jump if so

           ldi     errinvdir           ; invalid directory error
           lbr     error

finddir2:  sep     scall               ; set fd to new directory
           dw      setupfd

           glo     rc
           plo     rf
           ghi     rc
           phi     rf

           lbr     follow              ; and get next

founddir:  glo     rb
           plo     rf
           ghi     rb
           phi     rf

           ldi     0                   ; signal success
           shr
           sep     sret                ; return to caller


; ***********************************************
; *** Find directory                          ***
; *** RF - filename                           ***
; *** Returns: RD - Dir descriptor            ***
; ***          RB - first char following dirs ***
; ***          DF=0 - dir was found           ***
; ***          DF=1 - nonexistant dir         ***
; ***********************************************

finddir:   ldn     rf                  ; get first byte of pathname
           smi     '/'                 ; check for absolute path
           lbz     findabs             ; jump if so


         ; We have a fully relative path so we need to find apply the current
         ; working directory before processing.

           glo     rf                  ; save path
           stxd
           ghi     rf
           stxd

           ldi     high path           ; point to current dir
           phi     rf
           ldi     low path
           plo     rf

findcont:  inc     rf                  ; move past leading slashes
           inc     rf

           sep     scall
           dw      openmd
           lbdf    finderr

           inc     rf

skpslabs:  sep     scall               ; follow path in current dir
           dw      follow

finderr:   irx                         ; recover original path
           ldxa
           phi     rf
           ldx
           plo     rf

           lbdf    error               ; jump on error
           lbr     findrel


        ;  We have some form of absolute path, need to see if it has a drive

findabs:   inc     rf                  ; move past first slash

           ldn     rf
           smi     '/'
           lbz     finddrv


         ; We have a drive-relative absolute path, so we need to process just
         ; the drive prefix part of the current directory.

           glo     rf                  ; save path
           stxd
           ghi     rf
           stxd

           ldi     high path           ; point to current dir
           phi     rf
           ldi     low path
           plo     rf

           inc     rf                  ; move past leading slashes
           inc     rf

           sep     scall
           dw      openmd
           lbdf    finderr

           irx                         ; recover original path
           ldxa
           phi     rf
           ldx
           plo     rf

           lbr     findrel


         ; We have a fully absolute path with drive specifier.

finddrv:   inc     rf

           sep     scall
           dw      openmd
           lbdf    error

           ldn     rf
           smi     '/'
           lbnz    findrel

           inc     rf


findrel:   sep     scall               ; follow dirs
           dw      follow
           lbdf    error               ; jump on error

           ghi     rf                  ; transfer name
           phi     rb
           glo     rf
           plo     rb

           ldi     0                   ; signal success
           shr
           sep     sret                ; return to caller


; *****************
; *** Open /BIN ***
; *****************

execdir:   glo     rf                  ; save path
           stxd
           ghi     rf
           stxd

           ldi     high defdir         ; point to default dir
           phi     rf
           ldi     low defdir
           plo     rf

           lbr     findcont            ; continue with normal find


; ***********************************************
; *** Find directory                          ***
; *** RF - filename                           ***
; *** Returns: RD - Dir descriptor            ***
; ***          RF - first char following dirs ***
; ***********************************************
opendir:   glo     rb                  ; save consumed register
           stxd
           ghi     rb
           stxd

           sep     scall               ; call find dir routine
           dw      finddir

           ghi     rb                  ; put end if dir back into rf
           phi     rf
           glo     rb
           plo     rf

           irx                         ; recover consumed register
           ldxa
           phi     rb
           ldx
           plo     rb

           sep     sret                ; return to caller


getdrive:  glo     rd
           adi     15
           plo     rd
           ghi     rd
           adci    0
           phi     rd

           ldn     rd
           phi     r8

           glo     rd
           smi     15
           plo     rd
           ghi     rd
           smbi    0
           phi     rd

           sep     sret


; **********************************
; *** Create a new file          ***
; *** RD - dir descriptor        ***
; *** RC - descriptor to fill in ***
; *** RF - filename              ***
; *** R7 - Flags                 ***
; ***      1-subdir              ***
; ***      2-executable          ***
; *** Returns: RD - new file     ***
; ***          RF - set if fail  ***
; **********************************

create:    glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r7
           stxd
           ghi     r7
           stxd

           glo     r7                  ; put copy of flags on stack
           stxd

           sep     scall
           dw      getdrive

           sep     scall               ; get a lump
           dw      freelump

           ldi     high scratch        ; get buffer address
           phi     r9
           ldi     low scratch
           plo     r9

           ldi     0                   ; setup starting lump
           str     r9
           inc     r9
           str     r9
           inc     r9

           ghi     ra
           str     r9
           inc     r9
           glo     ra
           str     r9
           inc     r9

           ldi     0                   ; set eof at zero
           str     r9
           inc     r9
           str     r9
           inc     r9

           irx                         ; recover create flags
           ldx
           str     r9                  ; and save
           inc     r9

           sep     scall
           dw      gettmdt

           ldi     0
           str     r9
           inc     r9

           sep     scall
           dw      copyname
           lbdf    createok

           smi     0
           lbr     creatert

createok:  sep     scall               ; get dir sector and offset
           dw      getsecofs

           ldi     high scratch        ; get buffer address
           phi     rf
           ldi     low scratch
           plo     rf

           glo     rc                  ; save destination descriptor
           stxd
           ghi     rc
           stxd

           ldi     0                   ; 32 bytes to write
           phi     rc
           ldi     32
           plo     rc

           sep     scall               ; write the dir entry
           dw      o_write

           sep     scall               ; close the directory
           dw      close

           irx                         ; recover new descriptor
           ldxa
           phi     rd
           ldx
           plo     rd

           ldi     9
           sep     scall
           dw      setfddwrd

           sep     scall               ; write dir offset
           dw      setfddrof

           ghi     r8
           stxd

           ldi     0                   ; need to set current offset to 0
           phi     r8
           plo     r8
           phi     r7
           plo     r7

           ldi     0
           sep     scall
           dw      setfddwrd

           ldi     0ffh                ; need to set current sector to -1
           phi     r8
           plo     r8
           phi     r7
           plo     r7

           ldi     15
           sep     scall
           dw      setfddwrd

           irx
           ldx
           phi     r8

           ldi     0ch                 ; set flags
           sep     scall
           dw      setfdflgs

           ldi     0                   ; need to set eof to 0
           phi     rf
           plo     rf
           sep     scall
           dw      setfdeof

           ldi     0feh                ; need to set end of chain
           phi     rf
           plo     rf
           sep     scall
           dw      writelump

           sep     scall               ; convert lump to sector
           dw      lumptosec

           sep     scall               ; read the sector
           dw      rawread

           adi     0

creatert:  irx                         ; recover consumed registers
           ldxa
           phi     r7
           ldxa
           plo     r7
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     ra
           ldx
           plo     ra

           sep     sret                ; return to caller

           
; *******************************************
; *** Get a free directory entry          ***
; *** RD - directory descriptor           ***
; *** Returns: RD - positioned descriptor ***
; ***          DF=0 - success             ***
; ***          DF=1 - Error               ***
; *******************************************
freedir:   ldi     0                   ; need to seek to 0
           phi     r8
           plo     r8
           phi     r7
           plo     r7

           plo     rc                  ; seek from start

           sep     scall               ; perform file seek
           dw      seek

           ldi     0                   ; offset
           phi     ra
           plo     ra
           phi     rb
           plo     rb

newfilelp: ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf

           ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc

           sep     scall               ; read next record
           dw      o_read

           glo     rc                  ; see if record was read
           smi     32
           lbnz    neweof              ; jump if eof hit

           ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf

           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lbr     neweof              ; found an entry

newnot:    lda     rd                  ; get current offset
           phi     rb
           lda     rd
           plo     rb
           lda     rd
           phi     ra
           ldn     rd
           plo     ra
           dec     rd                  ; restore pointer
           dec     rd
           dec     rd
           lbr     newfilelp           ; keep looking

neweof:    ghi     rb                  ; transfer offset for seek
           phi     r8
           glo     rb
           plo     r8
           ghi     ra
           phi     r7
           glo     ra
           plo     r7

           ldi     0                   ; seek from beginning
           plo     rc

           sep     scall               ; perform seek
           dw      seek

           ldi     0                   ; indicate no error
           sep     sret                ; and return to caller


; *************************************
; *** exec a file from /bin         ***
; *** RF - filename                 ***
; *** RA - pointer to arguments     ***
; *** Returns: RD - file descriptor ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************

execbin:   glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd

           sep     scall               ; find directory
           dw      execdir

           ldi     high scratch        ; setup scratch area
           phi     rf
           ldi     low scratch
           plo     rf

           sep     scall               ; perform directory search
           dw      searchdir
           lbdf    execfail            ; jump if failed to get dir

           sep     scall               ; close the directory
           dw      close

           ldi     high intfildes       ; point to internal fildes
           phi     rd
           ldi     low intfildes
           plo     rd

           sep     scall               ; setup the descriptor
           dw      setupfd

           ldi     0                   ; signal success
           shr

           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7

           lbr     opened

execfail:  ldi     1                   ; signal error
           shr

           ldi     errnoffnd
           lbr     openexit            ; then return


; *************************************
; *** open a file                   ***
; *** RF - filename                 ***
; *** RD - file descriptor          ***
; *** R7 - flags                    ***
; ***      1 - create if no exist   ***
; ***      2 - truncate on open     ***
; ***      4 - open for append      ***
; ***      8 - executables only     ***
; ***     16 - allow directories    ***
; *** Returns: RD - file descriptor ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************

open:      push    r7                  ; save consumed registers
           push    r8
           push    r9
           push    ra
           push    rb
           push    rc
           push    rd

           glo     r7                  ; get copy of flags
           stxd                        ; and save

           sep     scall               ; find directory
           dw      finddir
           lbnf    gotdir

           irx
           lbr     openerr

gotdir:    ldi     high scratch        ; setup scratch area
           phi     rf
           ldi     low scratch
           plo     rf

           sep     scall               ; perform directory search
           dw      searchdir
           lbdf    newfile             ; jump if file needs creation

           irx                         ; advance stack to open flags

           ldi     high (scratch+6)    ; get pointer to dirent flags
           phi     ra
           ldi     low (scratch+6)
           plo     ra

           ldn     ra                  ; check direct flags if a directory
           ani     1
           lbz     dirok

           ldx                         ; get flags, check if allow directory
           ani     16                  ; is set
           lbz     opencls

dirok:     ldx                         ; get flags
           stxd                        ; and keep on stack

           ani     2                   ; see if need to truncate file
           lbz     opencnt             ; jump if not

           glo     rf                  ; save buffer position
           stxd
           ghi     rf
           stxd

           inc     rf                  ; point to starting lump
           inc     rf

           lda     rf                  ; get starting lump
           phi     ra
           lda     rf
           plo     ra

           ldi     0                   ; need to zero eof
           str     rf
           inc     rf
           str     rf

           sep     scall               ; delete the files chain
           dw      delchain

           ldi     0feh                ; signal end of chain
           phi     rf
           plo     rf
           sep     scall               ; write lump value
           dw      writelump

           irx                         ; recover buffer position
           ldxa
           phi     rf
           ldx
           plo     rf

opencnt:   sep     scall               ; close the directory
           dw      close

           irx                         ; recover flags
           ldxa
           plo     re
           ldxa                        ; recover descriptr
           phi     rd
           ldx
           plo     rd

           glo     re                  ; save flags
           stxd

           sep     scall               ; setup the descriptor
           dw      setupfd

           irx                         ; recover flags
           ldx

           ani     4                   ; see if append mode
           lbz     opendone            ; jump if not

           sep     scall               ; seek to end
           dw      seekend

           sep     scall               ; load correct sector
           dw      loadsec

opendone:  ldi     0                   ; signal success
           shr

openexit:  irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller

newfile:   irx                         ; recover flags
           ldx
           plo     re                  ; keep a copy

           ani     1                   ; see if create is allowed
           lbnz    allow               ; allow the create

opencls:   sep     scall               ; close directory
           dw      close

openerr:   ldi     1                   ; need to signal an error
           shr

           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldx
           plo     rd

           lbr     openexit

allow:     ldi     0                   ; no file flags
           plo     r7
           glo     re

           ani     8                   ; see if executable file needs to be set
           lbz     allow2              ; jump if not

           ldi     2                   ; set flags for executable file
           plo     r7

allow2:    glo     rb                  ; save filename address
           stxd
           ghi     rb
           stxd

           glo     r7                  ; save flags
           stxd

           sep     scall               ; find a free dir entry
           dw      freedir
 
           irx                         ; recover flags
           ldxa
           plo     r7
           ldxa                        ; recover filename
           phi     rf
           ldxa
           plo     rf
           ldxa                        ; recover new descriptor
           phi     rc
           ldx
           plo     rc

           sep     scall               ; create the file
           dw      create

           ldi     0                   ; clear d and return
           lbr     openexit

           smi     0                   ; signal file not opened
           sep     sret                ; and return

           
; *************************************
; *** delete a file                 ***
; *** RF - filename                 ***
; *** Returns:                      ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
delete:
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd

           sep     scall               ; find directory
           dw      finddir

           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; perform directory search
           dw      searchdir
           lbnf    delfile             ; jump if file exists
           sep     scall               ; close the directory
           dw      close
delfail:   ldi     1                   ; signal an error
delexit:   shr                         ; shift result into DF
           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller
delfile:   sep     scall               ; close the directory
           dw      close
           sep     scall               ; read driectory sector for file
           dw      readsys
           ghi     r9                  ; get offset into sector
           adi     1 
           phi     r9 
           inc     r9                  ; point to flags
           inc     r9
           inc     r9
           inc     r9
           inc     r9
           inc     r9
           ldn     r9                  ; get flags
           ani     1                   ; see if directory
           lbnz    delfildir           ; jump if so
           dec     r9                  ; point to starting lump
           dec     r9
           dec     r9
           dec     r9
delgo:     ldn     r9                  ; retrieve it
           phi     ra
           ldi     0                   ; and zero in dir entry
           str     r9
           inc     r9
           ldn     r9
           plo     ra
           ldi     0
           str     r9
           sep     scall               ; write dir sector back
           dw      writesys
           sep     scall               ; delete the chain
           dw      delchain
           ldi     0                   ; signal success
           lbr     delexit
delfildir: ldi     1                   ; setup error code
           shr
           ldi     errisdir
           shlc
           lbr     delexit             ; and return
           
; *************************************
; *** rename a file                 ***
; *** RF - filename                 ***
; *** RC - new filename             ***
; *** Returns:                      ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
rename:    glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           glo     rc                  ; save copy of destination filename
           stxd
           ghi     rc
           stxd

           sep     scall               ; find directory
           dw      finddir

           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf

           sep     scall               ; perform directory search
           dw      searchdir
           lbnf    renfile             ; jump if file exists

           sep     scall               ; close the directory
           dw      close

           irx                         ; drop filename from stack and fail
           irx
           lbr     delfail

renfile:   sep     scall               ; close the directory
           dw      close

           sep     scall               ; read driectory sector for file
           dw      readsys

           glo     r9                  ; point to filename
           adi     12
           plo     r9
           ghi     r9                  ; get offset into sector
           adci    1 
           phi     r9 

           irx                         ; recover new name
           ldxa
           phi     rf
           ldx
           plo     rf

           sep     scall               ; copy filename from rf to r9
           dw      copyname
           lbnf    delfail

           sep     scall               ; write dir sector back
           dw      writesys

           ldi     0                   ; signal success
           lbr     delexit


; *************************
; *** Execute a program ***
; *** RF - command line ***
; *************************
exec:      sep      scall                ; move past any leading spaces
           dw       f_ltrim

           ldn      rf                   ; get first character
           lbz      err                  ; jump if nothing to exec

           ghi      rf                   ; transfer address to args register
           phi      ra
           glo      rf
           plo      ra

execlp:    lda      ra                   ; need to find first <= space
           smi      33
           lbdf     execlp

           plo      re                   ; save code

           dec      ra                   ; write a terminator
           ldi      0
           str      ra
           inc      ra

           glo      re                   ; recover byte

           adi      33                   ; check if it was the terminator
           lbnz     execgo1              ; jump if not

           dec      ra                   ; otherwise point args at terminator

execgo1:   ldi      high intfildes       ; point to internal fildes
           phi      rd
           ldi      low intfildes
           plo      rd

           ldi      0                    ; flags
           plo      r7

           sep      scall                ; attempt to open the file
           dw       open
           lbnf     opened               ; jump if it was opened

err:       ldi      9                    ; signal file not found error
           shr
           sep      sret

opened:    mov      rf,intflags          ; need to get flags

           ldn      rf                   ; retrieve them
           ani      040h                 ; is file executable
           lbz      notexec              ; jump if not exeuctable file

           ldi      high scratch         ; scratch space to read header
           phi      rf
           ldi      low scratch
           plo      rf

           ldi      0                    ; need to read 6 bytes
           phi      rc
           ldi      6
           plo      rc

           sep      scall                ; read header
           dw       o_read

           ldi      high scratch         ; point to load offset
           phi      r7
           ldi      low scratch
           plo      r7

           inc      r7                   ; lsb of load size
           inc      r7
           inc      r7
           ldn      r7                   ; retrieve it

           str      r2                   ; store for add

           dec      r7                   ; lsb of load addres
           dec      r7

           lda      r7                   ; retrieve it
           add                           ; add in size lsb
           plo      rf                   ; result in rf
           ldn      r7                   ; get msb of size
           str      r2                   ; store for add
           dec      r7                   ; point to msb of load address
           dec      r7
           ldn      r7                   ; retrieve it
           adc                           ; add in msb of size
           phi      rf                   ; rf now has highest address
           mov      rb,heap+1            ; now subtract heap address
           glo      rf                   ; lsb of high address
           str      r2                   ; store for subtract
           ldn      rb                   ; get lsb of heap address
           sm                            ; and subtract
           ghi      rf                   ; msb of high address
           str      r2                   ; store for subtract
           dec      rb                   ; msb of heap
           ldn      rb                   ; get heap address
           smb                           ; and subtract
           lbdf     opengood             ; jump if enough memory
           ldi      0bh                  ; signal memory low error
           shr
           sep      sret                 ; and return to caller

opengood:  lda      r7                   ; get load address
           phi      rf
           phi      rb                   ; and make a copy
           lda      r7
           plo      rf
           plo      rb
           lda      r7                   ; get size
           phi      rc
           lda      r7
           plo      rc
           push     rf
           mov      rf,lowmem
           ghi      rc
           adi      020h
           str      rf
           inc      rf
           glo      rc
           str      rf
           pop      rf
           sep      scall                ; read program block
           dw       o_read
;           dw       read
           ldi      high progaddr        ; point to destination of call
           phi      rf
           ldi      low progaddr
           plo      rf
           lda      r7                   ; get start address
           str      rf
           inc      rf
           lda      r7
           str      rf
           ghi      rb                   ; transfer load address to rf
           phi      rf
           glo      rb
           plo      rf
           sep      scall                ; call loaded program
progaddr:  dw       0
           plo     re                   ; save return value
           mov     r7,retval            ; point to retval
           glo     re                   ; write return value
           str     r7
           sep     scall                ; cull the heap
           dw      d_reapheap
           ldi     0                    ; signal no error
           shr
           sep      sret                 ; return to caller
notexec:   ldi      errnotexec           ; signal non-executable file
           lbr      error                ; and return

; *******************************
; *** Make directory          ***
; *** RF - pathname           ***
; *** Returns: DF=0 - success ***
; ***          DF=1 - Error   ***
; *******************************

mkdir:     glo     rf                  ; save pathname address
           stxd
           ghi     rf
           stxd
           glo     rd                  ; save pathname address
           stxd
           ghi     rd
           stxd
           glo     rb                  ; save pathname address
           stxd
           ghi     rb
           stxd
           glo     r7                  ; save pathname address
           stxd

           ghi     rf                  ; copy pathname address
           phi     rd
           glo     rf
           plo     rd

mkdirlp:   lda     rd                  ; look for terminator
           lbnz    mkdirlp

           dec     rd                  ; back to char before terminator
           dec     rd

           ldn     rd                  ; and retrieve it
           smi     '/'                 ; mkdir has no final slash
           lbnz    mkdir_go            ; jump if ok

           ldi     0                   ; remove final slash
           str     rd

mkdir_go:  ldi     high intfildes      ; temporariy fildes
           phi     rd
           ldi     low intfildes
           plo     rd

           ldi     16                  ; open diretories
           plo     r7

           glo     rf                  ; save pathname
           stxd
           ghi     rf
           stxd

           sep     scall               ; attempt to open the file
           dw      o_open

           irx                         ; recover pathname
           ldxa
           phi     rf
           ldx
           plo     rf

           lbdf    mkdir1              ; jump if it does not exist

           irx                         ; recover consumed registers
           ldxa
           plo     r7
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf

           ldi     errexists           ; signal entry exists error
           lbr     error

mkdir1:    sep     scall               ; open directory
           dw      finddir
           lbdf    mkdirer

           glo     rb                  ; save new dir name
           stxd
           ghi     rb
           stxd

           sep     scall               ; find a free dir entry
           dw      freedir

           irx                         ; recover pathname
           ldxa
           phi     rf
           ldx
           plo     rf

           ldi     high intfildes      ; temporariy fildes
           phi     rc
           ldi     low intfildes
           plo     rc

           ldi     1                   ; create as directory
           plo     r7

           sep     scall               ; create it
           dw      create
           lbnf    mkdirok

mkdirer:   smi     0
           lbr     mkdirrt

mkdirok:   sep     scall               ; close the new dir
           dw      close

           adi     0

mkdirrt:   irx                         ; recover consumed registers
           ldxa
           plo     r7
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf

           ldi     0                   ; signal success
           sep     sret                ; and return to caller

; ***************************************
; *** Set default execution directory ***
; *** RF - path                       ***
; *** Returns: DF=0 - success         ***
; ***          DF=1 - error           ***
; ***************************************
setdef:    ldn     rf                  ; get first byte
           lbz     getdef              ; jump if empty
           sep     scall               ; be sure name has a final slash
           dw      finalsl
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           sep     scall               ; attempt to open directory
           dw      opendir
           irx    
           ldxa
           phi     rf
           ldx
           plo     rf
           lbdf    setdefer            ; jump if it did not exist
           ldi     high defdir         ; point to default directory
           phi     rd
           ldi     low defdir
           plo     rd
setdeflp:  lda     rf                  ; copy byte from path
           str     rd                  ; to default directory
           inc     rd
           lbnz    setdeflp            ; loop back until all bytes copied
getdefex:  ldi     0                   ; signal success
           lskp
setdefer:  ldi     1                   ; need 1 for error code
setdefex:  shr                         ; shift result into df
           irx                         ; recover consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; and return to caller
getdef:    glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           ldi     high defdir         ; get address of default directory
           phi     rd
           ldi     low defdir
           plo     rd
getdeflp:  lda     rd                  ; read byte from default path
           str     rf                  ; store into users buffer
           inc     rf
           lbnz    getdeflp            ; loop until full path copied
           lbr     getdefex            ; return to caller

; *************************************
; *** Change/view current directory ***
; *** RF - pathname                 ***
; ***      first byte 0 to view     ***
; *** Returns: DF=0 - success       ***
; ***          DF=1 - error         ***
; *************************************
chdir:     ldn     rf                  ; get first byte of pathname
           lbz     viewdir             ; jump if to view

           sep     scall               ; check for final slash
           dw      finalsl

           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd

           sep     scall               ; find directory
           dw      finddir

           plo     re                  ; save result code

           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rb
           ldx
           plo     rb

           lbdf    chdirerr            ; jump on error

           glo     ra                  ; save consumed register
           stxd
           ghi     ra
           stxd

           ldi     high path           ; point to current dir storage
           phi     ra
           ldi     low path
           plo     ra

           ldn     rf                  ; get first byte of path
           smi     '/'                 ; check for absolute
           lbnz    chdirlp2            ; jump if not

           inc     rf
           inc     ra

           ldn     rf                  ; check if drive-absolute
           smi     '/'                 ; jump if so
           lbz     chdirlp

           inc     ra

chdirlp3:  lda     ra
           smi     '/'
           lbnz    chdirlp3

           lbr     chdirlp

chdirlp2:  lda     ra                  ; find way to end of path
           lbnz    chdirlp2

           dec     ra                  ; back up to terminator

chdirlp:   lda     rf                  ; get byte from path
           str     ra                  ; store into path
           inc     ra

           smi     33                  ; loof for terminators
           lbdf    chdirlp             ; loop until terminator found

           irx                         ; recover consumed register
           ldxa
           phi     ra
           ldx
           plo     ra

           ldi     0                   ; indicate success
           shr

           sep     sret                ; and return to caller

chdirerr:  glo     re                  ; recover error
           lbr     error               ; and return with error

viewdir:   glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd

           ldi     high path           ; get current dir
           phi     ra
           ldi     low path
           plo     ra

viewdirlp: lda     ra                  ; get byte from current dir
           str     rf                  ; write to output
           inc     rf

           lbnz    viewdirlp           ; loop until terminator found

           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rf
           ldx
           plo     rf

           ldi     0                   ; indicate success
           shr

           sep     sret                ; and return to caller
           

; *******************************
; *** Remove a directory      ***
; *** RF - Pathname           ***
; *** Returns: DF=0 - success ***
; ***          DF=1 - Error   ***
; *******************************
rmdir:     sep     scall               ; check for final slash
           dw      finalsl

           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd

           sep     scall               ; open the directory
           dw      o_opendir
           lbnf    rmdirlp             ; jump if dir opened

           ldi     errnoffnd           ; signal not found error
rmdirerr:  shl
           ori     1
           shr
           lbr     delexit             ; and return

rmdirlp:   ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc

           ldi     high scratch        ; where to put it
           phi     rf
           ldi     low scratch
           plo     rf

           sep     scall               ; read the bytes
           dw      o_read

           glo     rc                  ; see if eof was hit
           smi     32
           lbnz    rmdireof            ; jump if dir was empty

           ldi     high scratch        ; point to buffer
           phi     rf
           ldi     low scratch
           plo     rf

           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not

           lbr     rmdirlp             ; read rest of dir

rmdirno:   ldi     errdirnotempty      ; indicate not empty error
           lbr     rmdirerr            ; and error out

rmdireof:  ldi     9
           sep     scall
           dw      getfddwrd

           sep     scall               ; get direcotry info from descriptor
           dw      getfddrof

           sep     scall
           dw      readsys

           ghi     r9                  ; get offset into sector
           adi     1
           phi     r9

           inc     r9                  ; point to starting lump
           inc     r9

           lbr     delgo               ; and delete the dir


kinit:     ldi     high path           ; set path
           phi     rf
           ldi     low path
           plo     rf

           ldi     high defpath
           phi     rc
           ldi     low defpath
           plo     rc

pathlp:    lda     rc
           str     rf
           inc     rf
           lbnz    pathlp

           mov     rc,252              ; want to allocate 252 bytes on the heap
           mov     r7,00004            ; allocate as a permanent block
           sep     scall               ; allocate the memory
           dw      o_alloc
           mov     r7,stackaddr+1      ; point to allocation pointer
           ldi     1                   ; mark interrupts enabled
           lsie                        ; skip if interrupts are enabled
           ldi     0                   ; mark interrupts disabled
           plo     re                  ; save IE flag
           ldi     023h                ; setup for DIS
           str     r2
           dis                         ; disable interrupts
           dec     r2
           glo     rf                  ; SP needs to be end of heap block
           adi     251
           str     r7                  ; write to pointer
           dec     r7
           plo     r2                  ; and into R2
           ghi     rf                  ; process high byte
           adci    0
           str     r7
           phi     r2
           glo     re                  ; recover IE flag
           lbz     kinit2              ; jump if interrupts disabled
           ldi     023h                ; setup for RET
           str     r2
           ret                         ; re-enable interrupts
           dec     r2
kinit2:    dec     r2                  ; need 2 less
           dec     r2
           sep     sret                ; return to caller


; ************************************************
; *** Initialize all vectors and data pointers ***
; ************************************************

coldboot:  ldi     high start          ; get return address for setcall
           phi     r6
           ldi     low start
           plo     r6

           ldi     0                   ; set stack to 00ff temporarily
           plo     r2
           dec     r2
           phi     r2

           lbr     o_initcall          ; setup call and return

         #ifdef FIXED32K
start:     ldi     07fh
           phi     rf
           ldi     0ffh
           plo     rf
         #else
start:     sep     scall               ; get free memory
           dw      f_freemem
         #endif

           ldi     0                   ; put end of heap marker
           str     rf

           ldi     high heap
           phi     r7
           ldi     low heap
           plo     r7

           ghi     rf                  ; store highest memory address
           str     r7                  ; and store it
           inc     r7
           glo     rf
           str     r7

           ldi     low himem
           plo     r7

           dec     rf                  ; himem is heap-1
           ghi     rf                  ; store highest memory address
           str     r7                  ; and store it
           inc     r7
           glo     rf
           str     r7

           sep     scall               ; call rest of kernel setup
           dw      kinit

           ldi     high initprg        ; point to init program command line
           phi     rf
           ldi     low initprg
           plo     rf

           sep     scall               ; attempt to execute it
           dw      o_exec
           lbnf    welcome             ; jump if no error

           sep     scall               ; get terminal baud rate
           dw      o_setbd

welcome:   ldi     high bootmsg
           phi     rf
           ldi     low bootmsg
           plo     rf

           sep     scall
           dw      o_msg
     
warmboot:  plo     re                  ; save return value
           mov     rf,retval           ; point to retval
           glo     re                  ; write return value
           str     rf
           sex     r2                  ; be sure r2 points to stack
           ldi     1                   ; signal interrupts enabled
           lsie                        ; skip if interrupts are enabled
           ldi     0                   ; signal interupts are not enab led
           plo     re                  ; save interrupts flag
           ldi     023h                ; setup for DIS
           str     r2
           dis                         ; disable interrupts during change of R2
           dec     r2
           mov     rc,stackaddr        ; point to system stack address
           lda     rc                  ; and reset R2
           phi     r2
           lda     rc
           plo     r2
           glo     re                  ; recover interrupts flag
           lbz     warm2               ; jump if interrupts are not enabled
           ldi     023h                ; setup for RET
           str     r2
           ret                         ; re-enable interrupts
           dec     r2
           
;           ldi     high stack          ; reset the stack
;           phi     r2
;           ldi     low stack
;           plo     r2
warm2:     sep     scall               ; cull the heap
           dw      d_reapheap
           lbr     d_progend
warm3:     ldi     high shellprg       ; point to command shell name
           phi     rf
           ldi     low shellprg
           plo     rf
           sep     scall               ; and attempt to execute it
           dw      exec

; *************************
; *** Main command loop ***
; *************************
cmdlp:     ldi      high prompt          ; get address of prompt into R6
           phi      rf
           ldi      low prompt
           plo      rf

           sep      scall
           dw       o_msg                ; function to print a message

           ldi      high keybuf          ; place address of keybuffer in R6
           phi      rf
           ldi      low keybuf
           plo      rf

           ldi      07fh                 ; limit keyboard input to 127 bytes
           plo      rc
           ldi      0
           phi      rc

           sep      scall
           dw       o_inputl             ; function to get keyboard input
           lbnf     noctrlc

           sep      scall
           dw       o_inmsg
           db       "^C",13,10,0

         ; If control-c pressed at command prompt, flush the filedescriptor
         ; buffers so that a disk can be changed.

           ldi      high (sysfildes+15)
           phi      rc
           ldi      low (sysfildes+15)
           plo      rc

           ldi      255
           str      rc

           ldi      high (intfildes+15)
           phi      rc
           ldi      low (intfildes+15)
           plo      rc

           ldi      255
           str      rc

           lbr      cmdlp


noctrlc:   sep      scall
           dw       o_inmsg              ; function to print a message
           db       13,10,0

           ldi      high keybuf          ; place address of keybuffer in R6
           phi      rf
           ldi      low keybuf
           plo      rf

skipspc1:  lda      rf
           lbz      cmdlp
           sdi      ' '
           lbdf     skipspc1

           dec      rf

           sep      scall                ; call exec function
           dw       exec
           lbdf     curerr               ; jump on error

           lbr      cmdlp                ; loop back for next command
 
curerr:    ldi      high keybuf          ; place address of keybuffer in R6
           phi      rf
           ldi      low keybuf
           plo      rf

skipspc2:  lda      rf
           sdi      ' '
           lbdf     skipspc2

           dec      rf

           sep      scall                ; call exec function
           dw       execbin
           lbdf     loaderr              ; jump on error

           lbr      cmdlp                ; loop back for next command

loaderr:   ldi      high errnf           ; point to not found message
           phi      rf
           ldi      low errnf
           plo      rf

           sep      scall                ; display it
           dw       o_msg

           lbr      cmdlp                ; loop back for next command


; Copy filename from RF to R9
; Advances RF and R9 pointers
; Returns DF=0 if invalid name

copyname:  glo      rc
           stxd

           ldi      20
           plo      rc

           adi      0

namenext:  lda      rf
           str      r9
           inc      r9
           lbz      endname

           sep      scall
           dw       f_isalnum
           lbdf     goodchr

           smi      '_'
           lbz      goodchr

           smi      '.'-'_'
           lbz      goodchr

           smi      '-'-'.'
           lbnz     failchr

goodchr:   dec      rc
           glo      rc
           lbnz     namenext

failchr:   adi      0

endname:   irx
           ldx
           plo      rc

           sep      sret

           
; ****************************************
; *** Be sure a name has a final slash ***
; *** RF - pointer to filename         ***
; ****************************************
finalsl:   glo     rf                  ; save filename position
           stxd
           ghi     rf
           stxd
finalsllp: lda     rf                  ; look for terminator
           lbnz    finalsllp
           dec     rf                  ; move to char prior to terminator
           dec     rf
           lda     rf                  ; and retrieve it
           smi     '/'                 ; is it final slash
           lbz     finalgd             ; jump if so
           ldi     '/'                 ; add slash to name
           str     rf
           inc     rf
           ldi     0                   ; and new terminator
           str     rf
           inc     rf
finalgd:   irx                         ; recover filename position
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; and return

; *******************************************
; *** Get date and time                   ***
; *** Writes packed date and time into    ***
; *** memory at R9, which is advanced     ***
; *** four bytes                          ***
; *******************************************

gettmdt:   glo     rf                  ; save consumed register
           stxd
           ghi     rf
           stxd

           sep     scall               ; get devices
           dw      o_getdev

           glo     rf
           ani     010h                ; see if RTC is installed
           lbz     no_rtc              ; jump if no rtc

           ldi     high date_time      ; point to scratch area
           phi     rf
           ldi     low date_time
           plo     rf

           ghi     rc                  ; save due to bug in mbios
           stxd

           sep     scall               ; get time and date
           dw      o_gettod

           irx                         ; restore
           ldx
           phi     rc

no_rtc:    ldi     high date_time      ; point to scratch area
           phi     rf
           ldi     low date_time
           plo     rf

rtc_cont:  lda     rf                  ; get month, shift left 5 bits,
           shl                         ;  hold result on stack
           shl
           shl
           shl
           shl
           str     r2

           lda     rf                  ; get day, or with shifted month,
           or                          ;  save to result
           plo     re

           lda     rf                  ; get year, shift in high bit of
           shlc                        ;  month, save to result
           str     r9
           inc     r9

           glo     re
           str     r9
           inc     r9

           lda     rf                  ; get hours, shift left 3 bits,
           shl                         ;  hold result on stack
           shl
           shl
           str    r2

           ldn    rf                   ; get minutes, shift right 3 bits,
           shr                         ;  or with hours, save to result
           shr
           shr
           or
           str     r9
           inc     r9

           lda    rf                   ; get minutes again, shift right 5,
           shl                         ;  or with seconds, save to result
           shl
           shl
           shl
           shl
           sex    rf
           or
           str     r9
           inc     r9

gettm_dn:  inc     r2                  ; recover consumed register
           lda     r2
           phi     rf
           ldn     r2
           plo     rf

           sep     sret                ; and return


; *******************************************
; ***** Allocate memory                 *****
; ***** RC - requested size             *****
; ***** R7.0 - Flags                    *****
; *****      0 - Non-permanent block    *****
; *****      4 - Permanent block        *****
; ***** R7.1 - Alignment                *****
; *****      0 - no alignment           *****
; *****      1 - Even address           *****
; *****      3 - 4-byte boundary        *****
; *****      7 - 8-byte boundary        *****
; *****     15 - 16-byte boundary       *****
; *****     31 - 32-byte boundary       *****
; *****     63 - 64-byte boundary       *****
; *****    127 - 128-byte boundary      *****
; *****    255 - Page boundary          *****
; ***** Returns: RF - Address of memory *****
; *****          RC - Size of block     *****
; *******************************************
alloc:
            push    r9                  ; save consumed registers
            push    rd
            ldi     heap.0              ; get heap address
            plo     r9
            ldi     heap.1 
            phi     r9
            lda     r9
            phi     rd
            ldn     r9
            plo     rd
            dec     r9                  ; leave pointer at heap address
            ghi     r7
            lbnz    alloc_aln           ; jump if aligned block requested
alloc_1:    lda     rd                  ; get flags byte
            lbz     alloc_new           ; need new if end of table
            plo     re                  ; save flags
            lda     rd                  ; get block size
            phi     rf
            lda     rd
            plo     rf
            glo     re                  ; is block allocated?
            ani     2
            lbnz    alloc_nxt           ; jump if so
            glo     rc                  ; subtract size from block size
            str     r2
            glo     rf
            sm
            plo     rf
            ghi     rc
            str     r2
            ghi     rf
            smb
            phi     rf                  ; RF now has difference
            lbnf    alloc_nxt2          ; jumpt if block is too small
            ghi     rf                  ; see if need to split block
            lbnz    alloc_sp            ; jump if so
            glo     rf                  ; get low byte of difference
            ani     0f8h                ; want to see if at least 8 extra bytes
            lbnz    alloc_sp            ; jump if so
alloc_2:    glo     rd                  ; set address for return
            plo     rf
            ghi     rd
            phi     rf
            dec     rd                  ; move back to flags byte
            dec     rd
            dec     rd
            glo     r7                  ; get passed flags
            ori     2                   ; mark block as used
            str     rd
            inc     rd                  ; get allocated block size
            lda     rd
            phi     rc
            lda     rd
            plo     rc
            adi     0                   ; clear df
alloc_ext:
            pop     rd                  ; recover consumed registers
            pop     r9
            sep     sret                ; and return to caller
alloc_sp:   ghi     rd                  ; save this address
            stxd
            glo     rd
            stxd
            dec     rd                  ; move to lsb of block size
            glo     rc                  ; write requested size
            str     rd
            dec     rd
            ghi     rc                  ; write msb of size
            str     rd
            inc     rd                  ; move back to data
            inc     rd
            glo     rc                  ; now add size
            str     r2
            glo     rd
            add
            plo     rd
            ghi     rd
            str     r2
            ghi     rc
            adc
            phi     rd                  ; rd now points to new block
            ldi     1                   ; mark as a free block
            str     rd
            inc     rd
            dec     rf                  ; remove 3 bytes from block size
            dec     rf
            dec     rf
            ghi     rf                  ; and write into block header
            str     rd
            inc     rd
            glo     rf
            str     rd
            irx                         ; recover address
            ldxa
            plo     rd
            ldx
            phi     rd
            lbr     alloc_2             ; finish allocating
alloc_nxt2: glo     rc                  ; put rf back 
            str     r2
            glo     rf
            add
            plo     rf
            ghi     rc
            str     r2
            ghi     rf
            adc
            phi     rf
alloc_nxt:  glo     rf                  ; add block size to address
            str     r2
            glo     rd
            add
            plo     rd
            ghi     rf
            str     r2
            ghi     rd
            adc
            phi     rd
            lbr     alloc_1             ; check next cell
alloc_new:  lda     r9                  ; retrieve start of heap
            phi     rd
            ldn     r9
            plo     rd
            glo     rc                  ; subtract req. size from pointer
            str     r2
            glo     rd
            sm
            plo     rd
            ghi     rc
            str     r2
            ghi     rd
            smb
            phi     rd
            dec     rd
            dec     rd
            dec     rd
            sep     scall               ; check for out of memory
            dw      checkeom
            lbdf    alloc_ext           ; return to caller on error
            inc     rd                  ; point to lsb of block size
            inc     rd
            glo     rc                  ; write size
            str     rd
            dec     rd
            ghi     rc
            str     rd
            dec     rd
            glo     r7                  ; get passed flags
            ori     2                   ; mark as allocated block
            str     rd
            glo     rd                  ; set address
            plo     rf
            ghi     rd
            phi     rf
            inc     rf                  ; point to actual data space
            inc     rf
            inc     rf
            glo     rd                  ; write new heap address
            str     r9
            dec     r9
            ghi     rd
            str     r9
            lbr     sethimem
            sep     sret                ; return to caller
alloc_aln:  glo     rd                  ; keep copy of heap head in RF
            plo     rf
            ghi     rd
            phi     rf
            glo     rc                  ; subtract size from heap head
            str     r2
            glo     rd
            sm
            plo     rd
            ghi     rc
            str     r2
            ghi     rd
            smb
            phi     rd                  ; rd now pointing at head-size
            ghi     r7                  ; get alignement type
            xri     0ffh                ; invert the bits
            str     r2                  ; need to AND with address
            glo     rd
            and
            plo     rd                  ; RD now has aligned address
            str     r2                  ; now subtract new address from original to get block size
            glo     rf
            sm
            plo     rf
            ghi     rd
            str     r2
            ghi     rf
            smb
            phi     rf                  ; RF now holds new block size
            dec     rd
            dec     rd
            dec     rd
            sep     scall               ; check for out of memory
            dw      checkeom
            lbdf    return              ; return to caller on error
            inc     rd                  ; point to lsb of block size
            inc     rd
            glo     rf                  ; store block size in header
            str     rd
            dec     rd
            ghi     rf
            str     rd
            dec     rd                  ; rd now pointing to flags byte
            ldi     1                   ; mark as unallocated
            str     rd
            ghi     rd                  ; write new start of heap address
            str     r9
            inc     r9
            glo     rd
            str     r9
            dec     r9
            lbr     alloc_1             ; now allocate the block


; **************************************
; ***** Deallocate memory          *****
; ***** RF - address to deallocate *****
; **************************************
dealloc:    push    r9                  ; save consumed registers
            push    rd
            push    rf
            dec     rf                  ; move to flags byte
            dec     rf
            dec     rf
            ldi     1                   ; mark block as free
            str     rf
heapgc:     push    rc
            push    rd
            ldi     heap.0              ; need start of heap
            plo     r9
            ldi     heap.1     
            phi     r9
            lda     r9                  ; retrieve heap start address
            phi     rd
            ldn     r9
            plo     rd
heapgc_s:   dec     r9
            ldn     rd                  ; see if first block was freed
            lbz     heapgc_dn           ; jump if end of heap encountered
            smi     1
            lbnz    heapgc_1            ; jump on first allocated block
            inc     rd                  ; retrieve block size
            lda     rd
            plo     re
            lda     rd
            str     r2                  ; and add to block
            glo     rd
            add
            plo     rd
            glo     re
            str     r2
            ghi     rd
            adc
            phi     rd
            str     r9                  ; write new heap start
            inc     r9
            glo     rd
            str     r9
            lbr     heapgc_s            ; loop back to check for more leading empty blocks
heapgc_1:   lda     rd                  ; retrieve flags byte
            lbz     heapgc_dn           ; return if end of heap found
            plo     re                  ; save copy of flags
            lda     rd                  ; retrieve block size
            phi     rc
            lda     rd
            plo     rc
            glo     rd                  ; RF=RD+RC, point to next block
            str     r2
            glo     rc
            add
            plo     rf
            ghi     rd
            str     r2
            ghi     rc
            adc
            phi     rf
            lda     rf                  ; retrieve flags for next block
            lbz     heapgc_dn           ; return if on last block
            ani     2                   ; is block allocated?
            lbnz    heapgc_a            ; jump if so
            glo     re                  ; check flags of current block
            ani     2                   ; is it allocated
            lbnz    heapgc_a            ; jump if so
            lda     rf                  ; retrieve next block size into RF
            plo     re
            lda     rf
            plo     rf
            glo     re
            phi     rf
            inc     rf                  ; add 3 bytes for header
            inc     rf
            inc     rf
            glo     rf                  ; RC += RF, combine sizes
            str     r2
            glo     rc
            add
            plo     rc
            ghi     rf
            str     r2
            ghi     rc
            adc
            phi     rc
            dec     rd                  ; write size of combined blocks
            glo     rc
            str     rd
            dec     rd
            ghi     rc
            str     rd
            dec     rd                  ; move back to flags byte
            lbr     heapgc_1            ; keep checking for merges
heapgc_a:   glo     rf                  ; move pointer to next block
            plo     rd
            ghi     rf
            phi     rd
            dec     rd                  ; move back to flags byte
            lbr     heapgc_1            ; and check next block
heapgc_dn:  pop     rd
            pop     rc
            pop     rf
            lbr     sethimem

sethimem:   push    rf
            push    rd
            mov     rf,heap+1
            mov     rd,himem+1
            ldn     rf
            smi     1
            str     rd
            dec     rf
            dec     rd
            ldn     rf
            smbi    0
            str     rd
            pop     rd
            pop     rf
            adi     0                   ; signal no error
            lbr     alloc_ext           ; return to caller

; ****************************************************
; ***** Deallocate any non-permanent heap blocks *****
; ****************************************************
reapheap:   push    r9                  ; save consumed registers
            push    rd
            push    rf
            ldi     heap.0              ; need start of heap
            plo     rd
            ldi     heap.1    
            phi     rd
            lda     rd                  ; retrieve heap start address
            phi     rf
            ldn     rd
            plo     rf
hpcull_lp:  ldn     rf                  ; get flags byte
            lbz     heapgc              ; If end, garbage collect the heap
            ani     4                   ; check for permanent block
            lbnz    hpcull_nx           ; jump if allocated and permanent
            ldi     1                   ; mark block as free
            str     rf
hpcull_nx:  inc     rf                  ; get block size
            lda     rf
            plo     re
            lda     rf
            str     r2                  ; and add to pointer
            glo     rf
            add
            plo     rf
            glo     re
            str     r2
            ghi     rf
            adc
            phi     rf
            lbr     hpcull_lp           ; loop until end of heap



; ****************************************
; ***** Check for out of memory      *****
; ***** DF=1 if allocation too large *****
; ****************************************
checkeom:   push    rc
            push    r9
            ldi     lowmem.0            ; get lowmem
            plo     r9
            ldi     lowmem.1
            phi     r9
            lda     r9                  ; retrieve variable table end
            phi     rc
            lda     r9
            plo     rc
            ldi     heap.0              ; point to heap start
            plo     r9
            ldi     heap.1     
            phi     r9
            inc     r9                  ; point to lsb
            ldn     r9                  ; get heap
            str     r2
            glo     rc                  ; subtract from variable table end
            sm
            dec     r9                  ; point to msb
            ldn     r9                  ; retrieve it
            str     r2
            ghi     rc                  ; subtract from variable table end
            smb
            lbdf    oom                 ; jump of out of memory
            adi     0                   ; clear df
oomret:     pop     r9
            pop     rc
            sep     sret                ; and return to caller
oom:        smi     0                   ; set df 
            lbr     oomret



bootmsg:    db     'Elf/OS Classic 4.3.1',10,13
            db     'Copyright 2004-2021 by Michael H Riley',10,13,0
prompt:     db     10,13,'Ready',10,13,': ',0
errnf:      db     'File not found.',10,13,0
initprg:    db     '//0/bin/init',0
shellprg:   db     '//0/bin/shell',0
defdir:     db     '//0/bin/',0
defpath:    db     '//0/',0
            ds      40


         #if $>1be0h
         #error Kernel size overflow
         #endif

           org     1de0h

scratch:   ds      32
intdta:    ds      512

