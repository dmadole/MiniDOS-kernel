
;  Copyright 2024, David S. Madole <david@madole.net>
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <https://www.gnu.org/licenses/>.
;
;  This program is based on, and includes, prior work under these terms:
;
;     This software is copyright 2006 by Michael H Riley
;     You have permission to use, modify, copy, and distribute
;     this software so long as this copyright notice is retained.
;     This software may not be used in commercial applications
;     without express written permission from the author.


#include include/bios.inc

            org   300h

keybuf:     equ   080h
sysdta:     equ   100h


          ; New names for error codes that are a little more concise, self-
          ; explanitory, and that follow the ?_ type naming convention of
          ; other public kernel API constants. Also, keep length to 10
          ; characters maximum like other existing ?_ API constants.

e_exists:   equ   1       ; tried to create something that already exists
e_notfound: equ   2       ; could not find something being looked for
e_notdir:   equ   3       ; item in path that should be a directory is not
e_notfile:  equ   4       ; tried a file operation on something not a file
e_notempty: equ   5       ; tried to remove a directory that is not empty
e_notexec:  equ   6       ; tried to execute something not executable


          ; New error codes not previously defined but needed to cover more
          ; situations reasonably.

e_nospace:  equ   7       ; not enough space available to complete operation
e_deverror: equ   8       ; hardware failure reading or writing the device
e_readonly: equ   9       ; write operation tried on something read-only
e_invname:  equ   10      ; file name is not a valid length or format
e_notopen:  equ   11      ; tried operation on a descriptor that is not open


          ; Legacy error constants that were never widely implemented.

errexists:      equ   e_exists
errnoffnd:      equ   e_notfound
errinvdir:      equ   e_notdir
errisdir:       equ   e_notfile
errdirnotempty: equ   e_notempty
errnotexec:     equ   e_notexec

ff_dir:     equ   1
ff_exec:    equ   2
ff_write:   equ   4
ff_hide:    equ   8
ff_archive: equ   16

o_cdboot:   lbr   coldboot
o_wrmboot:  lbr   warmboot
o_open:     lbr   open
o_read:     lbr   read
o_write:    lbr   write
o_seek:     lbr   seek
o_close:    lbr   close
o_opendir:  lbr   opendir
o_delete:   lbr   delete
o_rename:   lbr   rename
o_exec:     lbr   exec
o_mkdir:    lbr   mkdir
o_chdir:    lbr   chdir
o_rmdir:    lbr   rmdir
o_rdlump:   lbr   readlump
o_wrtlump:  lbr   writelump
o_type:     lbr   f_tty
o_msg:      lbr   f_msg
o_readkey:  lbr   f_read
o_input:    lbr   f_input
o_prtstat:  lbr   return
o_print:    lbr   return
o_execdef:  lbr   execbin
o_setdef:   lbr   error
o_kinit:    lbr   kinit
o_inmsg:    lbr   f_inmsg
o_getdev:   lbr   f_getdev
o_gettod:   lbr   f_gettod
o_settod:   lbr   f_settod
o_inputl:   lbr   f_inputl
o_boot:     lbr   f_boot
o_tty:      lbr   f_tty
o_setbd:    lbr   f_setbd
o_initcall: lbr   f_initcall
o_brktest:  lbr   f_brktest
o_devctrl:  lbr   deverr
o_alloc:    lbr   alloc
o_dealloc:  lbr   dealloc
o_termctl:  lbr   error
o_nbread:   lbr   f_nbread
o_memctrl:  lbr   deverr

deverr:     ldi   0

error:      smi   0
            sep   sret

            org   3d0h                ; reserve some space for users
user:       db    0

            org   3f0h
intret:     sex   r2
            irx
            ldxa
            shr
            ldxa
            ret
iserve:     dec   r2
            sav
            dec   r2
            stxd
            shlc
            stxd

            db    0c0h
ivec:       dw    intret

            org   400h
version:    db    4,3,7

build:      dw    [build]

date:       db    [month],[day]
            dw    [year]

            db    0,0,0
o_sectolmp: db    0,0,0
            db    0,0,0,0,0,0,0,0,0
o_relsec:   db    0,0,0
            db    0

sysfildes:  db    0,0,0,0               ; current offset
            dw    sysdta                ; dta
            dw    0                     ; eof
            db    0                     ; flags
            db    0,0,0,0               ; dir sector
            dw    0                     ; dir offset
            db    255,255,255,255       ; current sector

intfildes:  db    0,0,0,0               ; current offset
            dw    intdta                ; dta
            dw    0                     ; eof
intflags:   db    0                     ; flags
            db    0,0,0,0               ; dir sector
            dw    0                     ; dir offset
            db    255,255,255,255       ; current sector

himem:      dw    0
d_idereset: lbr   f_idereset           ; jump to bios ide reset
d_ideread:  lbr   f_ideread            ; jump to bios ide read
d_idewrite: lbr   f_idewrite           ; jump to bios ide write
d_reapheap: lbr   reapheap             ; passthrough to heapreaper
d_progend:  lbr   warm3
d_lmpsize:  lbr   return               ; deprecated and unnecessary
            db    0,0,0,0
            db    0,0,0,0,0,0,0
shelladdr:  dw    0
stackaddr:  dw    0
lowmem:     dw    4000h
retval:     db    0
heap:       dw    0
d_incofs:   lbr   warm3               ; no longer supported
d_append:   lbr   warm3               ; no longer supported
clockfrq:   dw    4000

lmpshifx:   db    3
lmpmaskx:   db    0fh

curdrive:   db    0
datetime:   db    1,17,49,0,0,0
secnum:     dw    0
secden:     dw    0


path:       ds    128

            org   0500h

          ;---------------------------------------------------------
          ; LOADLUMP - Read a LAT sector and return pointer to entry
          ;
          ; Input:
          ;   R8.1 - Drive number
          ;   RA   - Lump number
          ;   RD   - Pointer to fildes
          ; Returns:
          ;   R7   - Sector of table entry
          ;   R8.0 - Sector of table entry
          ;   R9   - Points to lump entry

loadlump:   ghi   ra                    ; get sector of starting location
            adi   17
            plo   r7
            ldi   0
            plo   r8
            shlc
            phi   r7

            sep   scall                 ; read the sector
            dw    rawread

            glo   ra                    ; get starting offset in sector
            shl
            plo   r9
            ldi   0
            adci  sysdta.1
            phi   r9

            sep   sret


          ;---------------------------------------------------------
          ; SAVELUMP - Write new hint to table if less than current.
          ;
          ; Input:
          ;   R8.1 - Drive number
          ;   RA   - Lump number
          ; Returns:
          ;   R9   - Modified

savehint:   ghi   r8                    ; multiply by two bytes
            shl

            adi   lumphint.0            ; add to base of table
            plo   r9
            ldi   lumphint.1
            phi   r9

            glo   ra                    ; skip if not less than hint
            sex   r9
            inc   r9
            sm
            ghi   ra
            dec   r9
            smb
            sex   r2
            bdf   savedone

            ghi   ra                    ; update hint to freed lump
            str   r9
            inc   r9
            glo   ra
            str   r9

savedone:   sep   sret


          ;---------------------------------------------------------
          ; INITLUMP - Common setup for lump manipulation routines.
          ;
          ; Note: short call subroutine using br to avoid stack use.

initlump:   plo   re                    ; save return address

            glo   r7                    ; save consumed registers
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            glo   r9
            stxd
            ghi   r9
            stxd
            glo   rd
            stxd
            ghi   rd
            stxd

            ldi   sysfildes.1           ; get system dta pointer
            phi   rd
            ldi   sysfildes.0
            plo   rd

            glo   re                    ; return within same page
            adi   2
            plo   r3


          ;---------------------------------------------------------
          ; READLUMP - Read next lump in chain
          ; 
          ; Input:
          ;   R8.1 - Drive number
          ;   RA   - Lump number
          ; Returns:
          ;   RA   - Chained lump

readlump:   glo   r3                    ; common initialization code
            br    initlump

            sep   scall                 ; find and read the lat sector
            dw    loadlump

            lda   r9                    ; read the entry, fall through
            phi   ra
            ldn   r9
            plo   ra

            br    sretlump


          ;---------------------------------------------------------
          ; Write value to LAT
          ;
          ; Input:
          ;   R8.1 - Drive
          ;   RA - Lump
          ;   RF - Value

writelump:  glo   r3                    ; common initialization code
            br    initlump

            sep   scall                 ; find and read the lat sector
            dw    loadlump

            ghi   rf                    ; update value into entry
            str   r9
            inc   r9
            glo   rf
            str   r9

            sep   scall                 ; write sector back either way
            dw    rawrite

            glo   rf                     ; if we are freeing a lump
            bnz   sretlump
            ghi   rf
            bnz   sretlump

            sep   scall                 ; then update the hints table
            dw    savehint

            br    sretlump



          ;---------------------------------------------------------
          ; DELCHAIN - Delete an entire chain of lumps.
          ;
          ; Input:
          ;   R8.1 - Drive
          ;   RA   - Lump
          ; Returns:
          ;   RA   - Modified

delchain:   glo   r3                    ; common initialization code
            br    initlump

lumploop:   sep   scall
            dw    savehint

            sep   scall                 ; find and read the lat sector
            dw    loadlump

            lda   r9                    ; get next lump in chain
            phi   ra
            ldn   r9
            plo   ra

            glo   r8                    ; set value to zero to deallocate
            str   r9
            dec   r9
            str   r9

          ; Mark the sector as dirty so a load of a different sector will
          ; flush it out to disk.

            ldi   (sysfildes+8).0       ; get pointer to dta flags
            plo   r9
            ldi   (sysfildes+8).1
            phi   r9

            ldn   r9                    ; mark sector as dirty
            ori   1
            str   r9

            ghi   ra                    ; loop if not last lump
            smi   0feh
            bnz   lumploop
            glo   ra
            smi   0feh
            bnz   lumploop

            sep   scall                 ; write last sector to disk
            dw    rawrite

          ; br    sretlump              ; call through to return


          ;---------------------------------------------------------
          ; SRETLUMP - Restore lump registers and return.
          ;
          ; Note: not a subroutine, branched to and returns to caller.

sretlump:   irx                         ; recover consumed registers
            ldxa
            phi   rd
            ldxa
            plo   rd
            ldxa
            phi   r9
            ldxa
            plo   r9
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7

return:     sep   sret


         ; This is only used one place now so it's optimized for that.
         ; It destroys R8 and assumes the lowest bits of R7 are zero.

sec2lump:   glo   r8
            plo   re
            ghi   r7
            phi   ra
            glo   r7
            ani   248
            ori   4
            plo   ra
 
sec2lum1:   glo   re
            shr
            plo   re
            ghi   ra
            shrc
            phi   ra
            glo   ra
            shrc
            plo   ra
            lbnf  sec2lum1

            sep   sret

; *******************************
; *** Convert lump to sector  ***
; *** RA - lump               ***
; *** Returns: R8.0:R7 - Sector ***
; *******************************

lump2sec:   ldi   32                  ; set stop but for shift
            plo   r8

            glo   ra                  ; get allocation unit
            plo   r7
            ghi   ra
            phi   r7

sectolmp1:  glo   r7                  ; shift left to multiply
            shl
            plo   r7
            ghi   r7
            shlc
            phi   r7
            glo   r8
            shlc
            plo   r8

            lbnf  sectolmp1           ; continue 3x until stop bit

            sep   sret                ; return


          ; -------------------------------------------------------------------
          ; RAWRITE: Writes sector data from a file descriptor buffer.
          ;
          ;   R8:R7 -- Sector to write (unchanged)
          ;   RD    -- File descriptor (unchanged)
          ;   DF    -- Set at return if error
          ;
          ; Note that this writes the sector to disk regardless of whether it
          ; is marked as being modified in the flags byte. It does clear the
          ; flag if it is set, though.

rawrite:    glo   r9                    ; free register for fildes pointer
            stxd
            ghi   r9
            stxd

            glo   rf                    ; free register for buffer pointer
            stxd
            ghi   rf
            stxd

            glo   rd                    ; get pointer to buffer address
            adi   4
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            lda   r9                    ; get the data buffer address
            phi   rf
            lda   r9
            plo   rf

            ghi   r8                    ; set for backwards ide compatibility
            ori   255-31 
            phi   r8

            sep   scall                 ; write sector out to disk
            dw    d_idewrite

            ghi   r8                    ; restore original disk unit
            ani   31
            phi   r8

            lbdf  writret               ; do not update fildes if error

            inc   r9                    ; move to the flags byte
            inc   r9

            ldn   r9                    ; clear the modified data flag
            ani   255-1
            str   r9

            glo   rd                    ; point to sector address lsb
            adi   18
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            sex   r9                    ; update sector address in fildes
            glo   r7
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd

            sex   r2

writret:    irx                         ; restore buffer pointer register
            ldxa
            phi   rf
            ldxa
            plo   rf

            ldxa                        ; restore fildes pointer register
            phi   r9
            ldx
            plo   r9

            sep   sret                  ; return


          ; -------------------------------------------------------------------
          ; RAWREAD: Reads sector data into a file descriptor buffer.
          ;
          ;   R8:R7 -- Sector to read (unchanged)
          ;   RD    -- File descriptor (unchanged)
          ;   DF    -- Set at return if error
          ;
          ; If the same sector is already loaded, does not perform the read.
          ; If the sector in the buffer has been modified since it was loaded,
          ; write the modified data back first before loading the new sector.

rawread:    glo   r9                    ; free working pointer register
            stxd
            ghi   r9
            stxd

            glo   rd                    ; get copy of pointer to sector
            adi   18
            plo   r9
            ghi   rd
            adci  0
            phi   r9

          ; Note that the above clears DF since a file descriptor will never
          ; wrap around the end of memory. The code below all preserves DF
          ; clear by using XOR so that it is still clear if we LBR READRET.

            sex   r9                    ; do read if sector lsb different
            glo   r7
            xor
            lbnz  readsec

            dec   r9                    ; do read if sector middle different
            ghi   r7
            xor
            lbnz  readsec

            dec   r9                    ; do read if sector msb different
            glo   r8
            xor
            lbnz  readsec

            dec   r9                    ; if drive is the same, return success
            ghi   r8
            xor
            lbnz  readsec

            sex   r2                    ; reset stack index and return
            lbr   readret

          ; Requesting a different sector than already loaded, need to read.

readsec:    sex   r2                    ; reset sp

            glo   rf                    ; save current rf
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

          ; If the sector already in the buffer has been modified since it was
          ; loaded, write the modified data back to disk first.

            ldn   r9                    ; if not modified then don't write
            shr
            lbnf  nodirty

            glo   r7                    ; save sector that was requested
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd

            glo   rd                    ; move to loaded sector address
            adi   15
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            lda   r9                    ; get the loaded sector drive
            ori   255-31
            phi   r8

            lda   r9                    ; get the loaded sector address
            plo   r8
            lda   r9
            phi   r7
            ldn   r9
            plo   r7

            sep   scall                 ; write out the current sector
            dw    d_idewrite

            irx                         ; restore sector address to load
            ldxa
            phi   r8
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7

            lbdf  readerr               ; abort if a write error occurred

          ; Note that the data modified flag is only cleared if the write
          ; succeeded. It's possible it might succeed if tried again later.

            glo   rd                    ; get pointer to flags byte
            adi   8
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            ldn   r9                    ; clear the data modified flag
            ani   255-1
            str   r9

            ghi   rf                    ; reset buffer pointer to start
            smi   2
            phi   rf

          ; Finally, read the new sector data and update the drive and address
          ; of the loaded sector in the file descriptor.

nodirty:    ghi   r8                    ; set for backwards compatibility
            ori   255-31
            phi   r8

            sep   scall                 ; read data from disk to buffer
            dw    d_ideread

            ghi   r8
            ani   31
            phi   r8

            lbdf  readerr

            glo   rd                    ; get pointer to sector address
            adi   18
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            sex   r9                    ; update sector drive and address
            glo   r7
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd

            sex   r2

readerr:    irx                        ; restore from buffer pointer use
            ldxa
            phi   rf
            ldx
            plo   rf

readret:    irx
            ldxa                        ; restore from fildes pointer use
            phi   r9
            ldx
            plo   r9

            sep   sret                  ; return with status in df



seek:       glo   r9
            stxd
            ghi   r9
            stxd
            glo   ra
            stxd
            ghi   ra
            stxd
            glo   rb
            stxd
            ghi   rb
            stxd
            glo   rc
            stxd
            ghi   rc
            stxd
            glo   rf
            stxd
            ghi   rf
            stxd

            glo   rd                    ; get pointer to flags
            adi   8
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            ldn   r9                    ; fail if file is not open
            ani   8
            lbz   cantseek

            glo   rc                    ; if whence is zero
            lbz   seekzero

            smi   1                     ; if whence is one
            lbz   seekcurr

            smi   1                     ; if whence is two
            lbz   seeklast

cantseek:   smi   0                     ; return error
            lbr   seekrest


getcurau:   glo   rd                   ; point to current sector
            adi   15
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            lda   r9                   ; get drive number and sector
            phi   r8
            lda   r9
            plo   re
            lda   r9
            phi   ra

            ldn   r9                   ; set a stop bit in lsb
            ani   248
            ori   4
            plo   ra

secttoau:   glo   re                   ; divide by 8 to get lump
            shr
            plo   re
            ghi   ra
            shrc
            phi   ra
            glo   ra
            shrc
            plo   ra

            lbnf  secttoau             ; shift until stop bit

            sep   sret





seeklast:   ldn   r9                   ; optimize if in last au
            ani   4
            lbnz  lastlast

            ghi   r8                   ; save high byte of offset
            stxd

            sep   scall
            dw    getcurau

            ldi   -1                   ; set count to -1
            plo   rb
            phi   rb


skipend:    ghi   ra                   ; save current au
            phi   rc
            glo   ra
            plo   rc

            sep   scall                ; get next in chain
            dw    readlump

            inc   rb

            glo   ra                   ; loop until end of chain
            smi   0feh
            lbnz  skipend
            ghi   ra
            smi   0feh
            lbnz  skipend

            irx                        ; restore high byte of offset
            ldx
            phi   r8

            ldi   32                   ; set stop bit
            plo   re
 
au2sec:     glo   rc                   ; multiply by 8 to get sector
            shl
            plo   rc
            ghi   rc
            shlc
            phi   rc
            glo   re
            shlc
            plo   re

            lbnf  au2sec               ; loop until stop bit


            sex   r9                   ; update current sector
            glo   rc
            stxd
            ghi   rc
            stxd
            glo   re
            stxd



            ldi   16                   ; set stop bit
            plo   re

au2off:     glo   rb                   ; multiply count of aus by 4096/256
            shl
            plo   rb
            ghi   rb
            shlc
            phi   rb
            glo   re
            shlc
            plo   re
 
            lbnf  au2off               ; loop until stop bit


            glo   rd                   ; get pointer to eof offset
            adi   7
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            inc   rd                   ; move to lsb of current offset
            inc   rd
            inc   rd

            sex   rd

            ldn   r9                   ; copy eof low byte to offset
            dec   r9
            stxd

            glo   rb
            add
            ani   240

            sex   r9
            or
            sex   rd
            stxd

            ghi   rb
            adc
            stxd

            glo   re
            adc
            str   rd

            lbr   seekcurr


          ; If we are already in the last AU of the file we can optimize by
          ; quickly seeking to end of file and then seeking from current.

lastlast:   inc   rd                    ; move to lsb of offset
            inc   rd
            inc   rd

            dec   r9                    ; copy lsb of eof to lsb of offset
            ldn   r9
            str   rd

            dec   r9                    ; get msb of eof
            ldn   r9
            dec   rd

            sex   rd                    ; replace offset bits 3-0 with eof
            xor
            ani   15
            xor
            str   rd

            dec   rd
            dec   rd


          ; To seek relative to the current position, add the offset to the
          ; current position, then fall through to seek from start.

seekcurr:   inc   rd
            inc   rd
            inc   rd

            sex   rd

            glo   r7
            add
            plo   r7

            ghi   r7
            dec   rd
            adc
            phi   r7

            glo   r8
            dec   rd
            adc
            plo   r8

            ghi   r8
            dec   rd
            adc
            phi   r8


          ; Calculate the difference between the new and current offsets at
          ; allocation unit starts. This will tell us if we are still in the
          ; same AU, if we need to move backward, or we need to move forward,
          ; and for the latter, by how many allocation units. While doing
          ; this, update the file descriptor with the new offset value.

seekzero:   ghi   r8                    ; out of range including negative
            ani   240
            lbnz  cantseek

            inc   rd                    ; move to lsb of current offset
            inc   rd
            inc   rd

            sex   rd

            glo   r7                    ; just update the lowest byte
            stxd

            ghi   r7                    ; disregard bits 11-8 of offset
            ori   00fh
            sm
            ani   0f0h
            plo   rb

            ghi   r7                    ; update new into descriptor
            stxd

            glo   r8                    ; get difference of middle byte
            smb
            phi   rb

            glo   r8                    ; update new into descriptor
            stxd

            ghi   r8                    ; get difference of high byte
            smb
            plo   rc

            ghi   r8                    ; update new into descrptor
            str   rd

            sex   r2


          ; Depending on sign of the result, determine how to handle, whether
          ; seeking backwards or forwards of the current allocation unit.

            lbnf  seekback              ; if negative, seeking backward

            glo   rb                    ; if not zero, seeking forward
            lbnz  seekforw
            ghi   rb
            lbnz  seekforw
            glo   rc
            lbnz  seekforw


          ; Otherwise, if zero, then we are seeking to a location within the
          ; same AU as the current location. To get the new sector, we simply
          ; need to replace the low 3 bits of the current sector address with
          ; bits 11-9 of the new offset.

            glo   rd                    ; pointer to current sector address
            adi   15
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            lda   r9                    ; disk and high 21 bits stay same
            phi   r8
            lda   r9
            plo   r8
            lda   r9
            plo   re

            ghi   r7                    ; replace low 3 bits
            shr
            sex   r9
            xor
            ani   7
            xor
            plo   r7

            glo   re                    ; move stashed bits 15-8
            phi   r7

            lbr   seekread              ; load sector if needed and finish


          ; We can't directly seek to offsets prior to the current AU, so we
          ; instead seek forward from the beginning of the file.

seekback:   ghi   r8                    ; au count to seek forward * 16
            plo   rc
            glo   r8
            phi   rb
            ghi   r7
            plo   rb


          ; Need to get the first AU of the file to know where to seek from.

getfirst:   glo   rd                    ; get pointer to dir sector
            adi   9
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            lda   r9                    ; get directory sector address
            phi   r8
            lda   r9
            plo   r8
            lda   r9
            phi   r7
            lda   r9
            plo   r7
    
            glo   rd
            stxd
            ghi   rd
            stxd

            ldi   intfildes.1           ; get system file descriptor
            phi   rd
            ldi   intfildes.0
            plo   rd

            sep   scall                 ; read the sector
            dw    rawread

            irx                         ; restore consumed registers
            ldxa
            phi   rd
            ldx
            plo   rd

            lda   r9                    ; stash high byte of offset
            plo   re

            ldn   r9                    ; add dta address to offset
            adi   (intdta+2).0
            plo   r9
            glo   re
            adi   (intdta+2).1
            phi   r9

            lda   r9                    ; get starting au of file
            phi   ra
            ldn   r9
            plo   ra

            lbr   seekfrom



          ; Get the current AU by dividing the current sector address by 8.

seekforw:   sep   scall
            dw    getcurau


          ; We are seeking forward and have the amount by which in terms of
          ; the difference in bytes from the start of the allocation units.
          ; Divide by 16 to get the actual allocation unit count difference.

seekfrom:   ldi   4                     ; number of bits to shift
            plo   re

offstoau:   glo   rc                    ; divide by 16 to get au count
            shr
            plo   rc
            ghi   rb
            shrc
            phi   rb
            glo   rb
            shrc
            plo   rb

            dec   re                    ; shift until all bits done
            glo   re
            lbnz  offstoau

            glo   rd                    ; get pointer to flags
            adi   8
            plo   r9
            ghi   rd
            adci  0
            phi   r9

            ldn   r9
            ani   255-4
            str   r9


          ; Advance from the current AU by the count we need to move forward.

            inc   rb                    ; read one extra to detect eof

followau:   ghi   ra                    ; keep in case we need to extend
            phi   rc
            glo   ra
            plo   rc

            sep   scall                 ; get the next au after this one
            dw    readlump

            ghi   ra                    ; or is this one the last one
            smi   0feh
            lbnz  nolastau
            glo   ra
            smi   0feh
            lbz   atlastau

nolastau:   dec   rb                    ; decrement count
            glo   rb                    ; keep moving ahead until done
            lbnz  followau
            ghi   rb
            lbnz  followau

            lbr   seeklump


atlastau:   dec   rb
            glo   rb
            lbnz  extendau
            ghi   rb
            lbz   inlastau


extendau:   glo   rc
            stxd
            ghi   rc
            stxd

            ghi   rb
            phi   rc
            glo   rb
            plo   rc

            sep   scall
            dw    getchain

            ghi   rb
            phi   rc
            glo   rb
            plo   rc

            ghi   ra
            phi   rf
            glo   ra
            plo   rf

            irx
            ldxa
            phi   ra
            ldx
            plo   ra

            sep   scall
            dw    writelump


          ; Done except for sector

inlastau:   ldn   r9                    ; mark inside final lump
            ori   4
            str   r9


seeklump:   ghi   rc
            phi   ra
            glo   rc
            plo   ra

            sep   scall
            dw    lump2sec

            inc   rd
            inc   rd

            sex   rd

            glo   r7                    ; merge in low 3 bits from offset
            shlc
            xor
            ani   240
            xor
            shrc
            plo   r7

            dec   rd
            dec   rd


          ; Now we have the new sector in R8:R7, so read it in. If is the
          ; same sector already loaded, nothing will happen, and if the
          ; current sector is dirty, it will be written out first.

seekread:   sep   scall                 ; flush old sector, read new
            dw    rawread

            lda   rd                    ; load new offset into r8:r7
            phi   r8 
            lda   rd
            plo   r8
            lda   rd
            phi   r7
            ldn   rd
            plo   r7

            dec   rd                    ; reset to start of descriptor
            dec   rd
            dec   rd

            adi   0

seekrest:   irx
            ldxa
            phi   rf
            ldxa
            plo   rf
            ldxa
            phi   rc
            ldxa
            plo   rc
            ldxa
            phi   rb
            ldxa
            plo   rb
            ldxa
            phi   ra
            ldxa
            plo   ra
            ldxa
            phi   r9
            ldx
            plo   r9

            sep   sret                  ; return result



          ; Get a allocation unit chain
          ;
          ; Creates a chain of linked allocation units. The last one in the
          ; chain is marked with FEFE. Returns the start and end of the chain.
          ;
          ; Input:
          ;   R8.1 - drive number
          ;   RC   - number of lumps to allocate
          ; Returns:
          ;   RA   - first lump in chain
          ;   RB   - last lump in chain
          ;   DF   - set if error

getchain:   glo   r7
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            glo   r9
            stxd
            ghi   r9
            stxd
            glo   rc
            stxd
            ghi   rc
            stxd
            glo   rd
            stxd
            ghi   rd
            stxd
            glo   rf
            stxd
            ghi   rf
            stxd

            ldi   sysfildes.1           ; get system file descriptor
            phi   rd
            ldi   sysfildes.0
            plo   rd

            ldi   0                     ; clear high byte of lba
            plo   r8


          ; Check if the size of this disk has been cached yet. Leave RF
          ; pointing to the low byte of the cache entry for this drive.

            ghi   r8                    ; multiply drive by two bytes
            shl

            adi   disksize.0            ; add to base of table to index
            plo   rf
            ldi   disksize.1            ; get msb of index into table
            phi   rf

            lda   rf                    ; if not zero then we have it
            lbnz  havesiz2
            ldn   rf
            lbnz  havesiz2


          ; If the size has not yet been cached, look it up in the system
          ; sector and update the cache, leaving RF pointing to the entry.

            ldi   0                     ; system sector is address 0
            plo   r7
            phi   r7

            sep   scall                 ; load system sector
            dw    rawread

            ldi   (sysdta+10bh).1       ; point to disk size in aus
            phi   r7
            ldi   (sysdta+10bh).0
            plo   r7

            lda   r7                    ; update cache with disk size
            dec   rf
            str   rf
            ldn   r7
            inc   rf
            str   rf


          ; Load the hint for where to start looking for the next free
          ; allocation unit, and calculate the number of units to check.

havesiz2:   ghi   r8                    ; multiply by two bytes
            shl

            adi   lumphint.0            ; add to base of table
            plo   r9
            ldi   lumphint.1
            phi   r9

            lda   r9                    ; get the hint, check for zero
            phi   ra
            str   r2
            ldn   r9
            plo   ra
            or

            lbnz  havehin2              ; we have hint if not zero


          ; If there is no hint yet, calculate the first lump after the
          ; allocation table based on the disk size. This will be the ceiling
          ; of the disk size divided by 256, plus 23, then divided by 8.

            ldn   rf                    ; get the first usable data sector
            adi   255
            dec   rf
            lda   rf
            adci  18

            shrc                        ; divide by 8 to get allocation unit
            shr
            shr
            plo   ra


          ; Calculate the number of lumps to search by subtracting the
          ; starting lump from the disk size. If zero, the disk is full.

havehin2:   sex   rf
            glo   ra
            sd
            plo   rb

            dec   rf
            ghi   ra
            sdb
            phi   rb

            lbnz  dosearc2              ; if disk is full, give up now
            glo   rb
            lbz   foundla2


dosearc2:   ghi   ra                    ; get sector of starting location
            adi   17
            plo   r7
            ldi   0
            adci  0
            phi   r7

            glo   ra                    ; get starting offset in sector
            shl
            adi   sysdta.0
            plo   rf

            glo   ra                    ; carry from add plus high bit
            shlc
            ani   1
            adci  sysdta.1
            phi   rf


          ; Load a sector of the allocation table from disk, and check for
          ; the first non-zero entry from the current point.

            sex   r2

            glo   rc
            stxd
            ghi   rc
            stxd

            lbr   scanread

scanincr:   inc   rf                    ; adjust index pointer

scanloop:   inc   ra                    ; increment lump, decrement count
            dec   rb

            glo   rb                    ; keep looking if count not zero
            lbnz  scanmore
            ghi   rb
            lbz   scanfull

scanmore:   glo   ra                    ; if end of this sector
            lbnz  scansame

            ghi   rf                    ; then reset pointer to beginning
            smi   512.1
            phi   rf

            inc   r7                    ; and load next sector
scanread:   sep   scall
            dw    rawread

scansame:   lda   rf
            lbnz  scanincr
            lda   rf
            lbnz  scanloop

            dec   rc

            glo   rc
            lbnz  scanloop
            ghi   rc
            lbnz  scanloop




            irx
            ldxa
            phi   rc
            ldx
            plo   rc

            glo   ra
            stxd
            ghi   ra
            stxd

            ldi   0feh                 ; mark end of chain
            dec   rf
            str   rf
            dec   rf
            str   rf

            lbr   fillnext

fillloop:   ghi   ra                   ; save the last au
            phi   rb
            glo   ra
            plo   rb

fillskip:   glo   ra                   ; if at the start of sector
            lbnz  fillsame

            dec   r7                   ; then load next lower sector
            sep   scall
            dw    rawread

            ghi   rf                   ; reset data pointer
            adi   512.1
            phi   rf

fillsame:   dec   ra                   ; decrement au number

            dec   rf                   ; if au not free then skip
            ldn   rf
            dec   rf
            lbnz  fillskip
            ldn   rf
            lbnz  fillskip

            ghi   rb                   ; else link to last free au
            str   rf
            inc   rf
            glo   rb
            str   rf
            dec   rf

fillnext:   ldi   (sysfildes+8).1
            phi   rb
            ldi   (sysfildes+8).0
            plo   rb

            ldn   rb
            ori   1
            str   rb

            dec   rc                   ; repeat until all are filled
            glo   rc
            lbnz  fillloop
            ghi   rc
            lbnz  fillloop



            sep   scall
            dw    rawrite

            irx
            ldxa
            phi   rb
            ldx
            plo   rb
            



          ; Before returning, Update the hint to the lump that was found. If
          ; it actually gets used, the hint will be advanced by writelump.
          ;
          ; If none is found, it will updated to one past the last lump and
          ; searches won't happen any more until writelump sees one freed.

foundla2:   glo   rb
            str   r9
            dec   r9
            ghi   rb
            str   r9

geterror:   irx
            ldxa
            phi   rf
            ldxa
            plo   rf
            ldxa
            phi   rd
            ldxa
            plo   rd
            ldxa
            phi   rc
            ldxa
            plo   rc
            ldxa
            phi   r9
            ldxa
            plo   r9
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7
 
            sep   sret

scanfull:   smi   0
            lbr   geterror



          ; Open Master Directory File
          ;
          ; Parses the initial part of a fully-qualified pathname to find
          ; the relevant drive and opens a file descriptor to that drive's
          ; master directory.
          ;
          ; Input:
          ;   RF - Pointer to pathname
          ; Returns:
          ;   RD - File descriptor pointer
          ;   RF - Advanced to terminating character
          ;   DF - Set if error

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

            ldi   disksize.1            ; get pointer to disk table page
            phi   r9

            ldi   0                     ; system sector high address
            plo   r8


          ; Try to read the drive identifier as an ASCII decimal number.
          ; If that succeeds, use it, otherwise we'll treat is as a label.

            ghi   rf                    ; remember starting point
            phi   rb
            glo   rf
            plo   rb

            sep   scall                 ; get drive id if a number
            dw    f_atoi
            lbdf  nonumber

            ldn   rf                    ; number ends with zero or slash
            lbz   isnumber
            smi   '/'
            lbnz  nonumber


          ; It is for sure a number, so verify it is in the proper range
          ; and directly read the sector.

isnumber:   ghi   rd                    ; if 256 or more then error
            lbnz  mdoerror

            phi   r7                    ; set sector to zero
            plo   r7

            glo   rd                    ; set drive number
            phi   r8

            smi   32                    ; if 32 or more then error
            lbdf  mdreturn

            ldi   intfildes.1           ; get pointer to fildes
            phi   rd
            ldi   intfildes.0
            plo   rd

            sep   scall                 ; read system sector
            dw    rawread
            lbdf  mdreturn

            ghi   rf                    ; save pointer to terminator
            phi   rb
            glo   rf
            plo   rb

            lbr   opendisk              ; build open file descriptor


          ; Restore input string to beginning and return error.

mdoerror:   smi   0                     ; return error
            lbr   mdreturn


          ; Calculate Fletcher-16 checksum of the pathname up to a zero byte
          ; or a slash. This may not be the best algorithm to use but its fast
          ;  and it does mix the bits a bit better than a plain sum.

nonumber:   ghi   rb                    ; restore to start of path
            phi   rf
            glo   rb
            plo   rf

            ldi   0                     ; set drive to zero
            phi   r8

            str   r2                    ; initialize sum to zero
            phi   ra

            sm                          ; needs df set at start
            lbr   hashtest

hashnext:   adc                         ; modulo 255 add byte to lsb
            smbi  0
            str   r2

            ghi   ra                    ; modulo 255 add lsb to msb
            adc
            smbi  0
            phi   ra

hashtest:   lda   rb                    ; continue until null or slash
            lbz   hashdone
            xri   '/'
            lbnz  hashnext

hashdone:   ldn   r2                    ; get the lsb into result
            plo   ra


          ; Scan the table of label hashes and load and compare the label for
          ; any disk which matches the hash.

            ldi   intfildes.1           ; get pointer to fildes
            phi   rd
            ldi   intfildes.0
            plo   rd

            ldi   diskname.0
            plo   r9

finddisk:   sex   r9                    ; compare against table entry

            ghi   ra                    ; check if hash matches entry
            sm
            inc   r9
            lbnz  notmatch
            glo   ra
            sm
            lbnz  notmatch

            sep   scall                 ; and check if disk label matches
            dw    cmplabel
            lbz   opendisk

notmatch:   inc   r9                    ; else move to next table entry

            ghi   r8                    ; increment drive number
            adi   1
            ani   31
            phi   r8

            lbnz  finddisk              ; loop until 32 drives


          ; Since we couldn't find the disk using the hints table, now check
          ; all the other drives.

            ldi   diskname.0
            plo   r9

checkall:   sex   r9

            ghi   ra                    ; check if hash matches entry
            sm
            inc   r9
            lbnz  chekdisk
            glo   ra
            sm
            lbz   skipdisk

chekdisk:   sep   scall                 ; and check if disk label matches
            dw    cmplabel
            lbz   savename

skipdisk:   inc   r9

            ghi   r8                    ; increment drive number
            adi   1
            phi   r8

            smi   32                    ; loop until 32 drives
            lbnz  checkall

            lbr   mdreturn              ; else there is no match



savename:   glo   ra                    ; update entry that matched
            str   r9
            dec   r9
            ghi   ra
            str   r9


          ; Set the disk size cache entry, it is more or less just as cheap
          ; to set it every time rather than test if we already have it.

opendisk:   ghi   r8                    ; pointer to name table
            shl
            adci  disksize.0
            plo   r9

            ldi   (intdta+10bh).0       ; pointer to disk size
            plo   rf
            ldi   (intdta+10bh).1
            phi   rf

            lda   rf                    ; update table entry
            str   r9
            inc   r9
            ldn   rf
            str   r9


          ; Fill in the file descriptor with the master directory information
          ; and load the first data sector, the same as if open was called.

            ldi   0                     ; reset sector to zero
            phi   r7
            plo   r7

            ldi   12ch.0                ; dir offset in system data sector
            plo   r9 
            ldi   12ch.1
            phi   r9

            ldi   (intdta+12ch).0       ; move to directory entry
            plo   rf

            sep   scall                 ; read first sector
            dw    setupfd


          ; Set pointer to just after the drive specifier so the rest of the
          ; pathname is ready to be parsed.

            ghi   rb
            phi   rf
            glo   rb
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







cmplabel:   ghi   rf                    ; point to the input path
            phi   rb
            glo   rf
            plo   rb

            ldi   0
            phi   r7
            plo   r7

            sep   scall                 ; read system sector
            dw    rawread

            ldi   (intdta+138h).1       ; pointer to label
            phi   r7
            ldi   (intdta+138h).0
            plo   r7

            sex   rb                    ; for sm to compare

labelchr:   lda   r7                    ; get next, exit if end
            lbz   labelend

            sm                          ; get next, loop while match
            inc   rb
            lbz   labelchr

            sep   sret

labelend:   ldn   rb                    ; success if zero or slash
            lsz
            smi   '/'                

            sep   sret



          ; Get a free lump
          ;
          ; Input:
          ;   R8.1 - drive number
          ; Returns:
          ;   RA - free lump
          ;   DF - set if error

freelump:   glo   r7
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            glo   r9
            stxd
            ghi   r9
            stxd
            glo   rb
            stxd
            ghi   rb
            stxd
            glo   rd
            stxd
            ghi   rd
            stxd
            glo   rf
            stxd
            ghi   rf
            stxd

            ldi   sysfildes.1           ; get system file descriptor
            phi   rd
            ldi   sysfildes.0
            plo   rd

            ldi   0                     ; clear high byte of lba
            plo   r8


          ; Check if the size of this disk has been cached yet. Leave RF
          ; pointing to the low byte of the cache entry for this drive.

            ghi   r8                    ; multiply drive by two bytes
            shl

            adi   disksize.0            ; add to base of table to index
            plo   rf
            ldi   disksize.1            ; get msb of index into table
            phi   rf

            lda   rf                    ; if not zero then we have it
            lbnz  havesize
            ldn   rf
            lbnz  havesize


          ; If the size has not yet been cached, look it up in the system
          ; sector and update the cache, leaving RF pointing to the entry.

            ldi   0                     ; system sector is address 0
            plo   r7
            phi   r7

            sep   scall                 ; load system sector
            dw    rawread

            ldi   (sysdta+10bh).1       ; point to disk size in aus
            phi   r7
            ldi   (sysdta+10bh).0
            plo   r7

            lda   r7                    ; update cache with disk size
            dec   rf
            str   rf
            ldn   r7
            inc   rf
            str   rf


          ; Load the hint for where to start looking for the next free
          ; allocation unit, and calculate the number of units to check.

havesize:   ghi   r8                    ; multiply by two bytes
            shl

            adi   lumphint.0            ; add to base of table
            plo   r9
            ldi   lumphint.1
            phi   r9

            lda   r9                    ; get the hint, check for zero
            phi   ra
            str   r2
            ldn   r9
            plo   ra
            or

            lbnz  havehint              ; we have hint if not zero


          ; If there is no hint yet, calculate the first lump after the
          ; allocation table based on the disk size. This will be the ceiling
          ; of the disk size divided by 256, plus 23, then divided by 8.

            ldn   rf                    ; get the first usable data sector
            adi   255
            dec   rf
            lda   rf
            adci  18

            shrc                        ; divide by 8 to get allocation unit
            shr
            shr
            plo   ra


          ; Calculate the number of lumps to search by subtracting the
          ; starting lump from the disk size. If zero, the disk is full.

havehint:   sex   rf
            glo   ra
            sd
            plo   rb

            dec   rf
            ghi   ra
            sdb
            phi   rb

            lbnz  dosearch              ; if disk is full, give up now
            glo   rb
            lbz   foundlat


dosearch:   ghi   ra                    ; get sector of starting location
            adi   17
            plo   r7
            ldi   0
            adci  0
            phi   r7

            glo   ra                    ; get starting offset in sector
            shl
            adi   sysdta.0
            plo   rf

            glo   ra                    ; carry from add plus high bit
            shlc
            ani   1
            adci  sysdta.1
            phi   rf


          ; Load a sector of the allocation table from disk, and check for
          ; the first non-zero entry from the current point.

latloop2:   sep   scall                 ; load allocation table sector
            dw    rawread

latloop1:   lda   rf
            lbnz  notfree1
            lda   rf
            lbnz  notfree2

            adi   0                     ; found a free one, return success
            lbr   foundlat


          ; If not found, check if we have examined the whole table yet,
          ; if so the disk is full and there is nothing else we can do.

notfree1:   inc   rf                    ; adjust index pointer

notfree2:   inc   ra                    ; increment lump, decrement count
            dec   rb

            glo   rb                    ; keep looking if count not zero
            lbnz  notfull
            ghi   rb
            lbnz  notfull

            smi   0                     ; else none are left, return error
            lbr   foundlat


          ; Advance to the next AU to check. Every multiple of 256 we need
          ; to load the next sector and reset the buffer pointer.

notfull:    glo   ra                    ; if more in this sector, loop
            lbnz  latloop1

            ghi   rf                    ; reset buffer pointer to beginning
            smi   512.1
            phi   rf

            inc   r7                    ; load next sector, keep looking
            lbr   latloop2


          ; Before returning, Update the hint to the lump that was found. If
          ; it actually gets used, the hint will be advanced by writelump.
          ;
          ; If none is found, it will updated to one past the last lump and
          ; searches won't happen any more until writelump sees one freed.

foundlat:   glo   ra
            str   r9
            dec   r9
            ghi   ra
            str   r9

            irx
            ldxa
            phi   rf
            ldxa
            plo   rf
            ldxa
            phi   rd
            ldxa
            plo   rd
            ldxa
            phi   rb
            ldxa
            plo   rb
            ldxa
            phi   r9
            ldxa
            plo   r9
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7
 
            sep   sret


; *****************************************
; *** Increment current offset          ***
; *** RD - file descriptor              ***
; *** Returns: DF=1 - new sector loaded ***
; *****************************************

getnext:    glo   r7                    ; save consumed registers
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd
            glo   ra
            stxd
            ghi   ra
            stxd

            glo   rd                    ; get pointer to current sector
            adi   15
            plo   ra
            ghi   rd
            adci  0
            phi   ra

            lda   ra                    ; get drive
            phi   r8

            lda   ra                    ; get current sector
            plo   r8
            lda   ra
            phi   r7
            lda   ra
            plo   r7

            inc   r7                    ; increment sector

            glo   r7                    ; check if new lump
            ani   7
            lbnz  notlump

            dec   r7

            sep   scall
            dw    sec2lump

            sep   scall                 ; get next lump
            dw    readlump

            sep   scall                 ; get first sector of next lump
            dw    lump2sec

            sep   scall                 ; get next lump
            dw    readlump

            glo   ra                    ; is it the last one?
            smi   0feh
            lbnz  notlump
            ghi   ra
            smi   0feh
            lbnz  notlump

            glo   rd                    ; get pointer to flags
            adi   8
            plo   ra
            ghi   rd
            adci  0
            phi   ra

            ldn   ra                    ; set last lump flag
            ori   4
            str   ra

notlump:    sep   scall
            dw    rawread

            irx                         ; recover consumed registers
            ldxa
            phi   ra
            ldxa
            plo   ra
            ldxa
            phi   r8
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7
 
            sep   sret                  ; return to caller


getnext2:   glo   r7                    ; save consumed registers
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd
            glo   ra
            stxd
            ghi   ra
            stxd

            glo   rd                    ; get pointer to current sector
            adi   15
            plo   ra
            ghi   rd
            adci  0
            phi   ra

            lda   ra                    ; get drive
            phi   r8

            lda   ra                    ; get current sector
            plo   r8
            lda   ra
            phi   r7
            lda   ra
            plo   r7

            sep   scall
            dw    rawrite

            inc   r7                    ; increment sector

            glo   r7                    ; check if new lump
            ani   7
            lbnz  notlump2

            dec   r7

            sep   scall
            dw    sec2lump

            sep   scall                 ; get next lump
            dw    readlump

            sep   scall                 ; get first sector of next lump
            dw    lump2sec

            sep   scall                 ; get next lump
            dw    readlump

            glo   ra                    ; is it the last one?
            smi   0feh
            lbnz  notlump2
            ghi   ra
            smi   0feh
            lbnz  notlump2

            glo   rd                    ; get pointer to flags
            adi   8
            plo   ra
            ghi   rd
            adci  0
            phi   ra

            ldn   ra                    ; set last lump flag
            ori   4
            str   ra

notlump2:   glo   rd
            adi   15
            plo   ra
            ghi   rd
            adci   0
            phi   ra

            ghi   r8
            str   ra
            inc   ra
            glo   r8
            str   ra
            inc   ra
            ghi   r7
            str   ra
            inc   ra
            glo   r7
            str   ra

            irx                         ; recover consumed registers
            ldxa
            phi   ra
            ldxa
            plo   ra
            ldxa
            phi   r8
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7
 
            sep   sret                  ; return to caller


append:     glo   r7                    ; save consumed registers
            stxd
            ghi   r7
            stxd
            glo   r8
            stxd
            ghi   r8
            stxd
            glo   ra
            stxd
            ghi   ra
            stxd
            glo   rf
            stxd
            ghi   rf
            stxd

            glo   rd                    ; get pointer to current sector
            adi   15
            plo   ra
            ghi   rd
            adci  0
            phi   ra

            lda   ra                    ; get drive
            phi   r8

            lda   ra                    ; get current sector
            plo   r8
            lda   ra
            phi   r7
            lda   ra
            plo   r7

            sep   scall                 ; get a new lump
            dw    freelump

            ldi   0feh                  ; end of chain marker
            phi   rf
            plo   rf

            sep   scall                 ; set new lump as last
            dw    writelump

            ghi   ra                    ; new lump is value
            phi   rf
            glo   ra
            plo   rf

            sep   scall                 ; get current lump
            dw    sec2lump

            sep   scall                 ; chain new lump from it
            dw    writelump

            glo   rd                    ; get pointer to current sector
            adi   8
            plo   ra
            ghi   rd
            adci  0
            phi   ra

            ldn   ra                    ; current lump is no longer last
            ani   255-4
            str   ra

            irx                         ; recover consumed registers
            ldxa
            phi   rf
            ldxa
            plo   rf
            ldxa
            phi   ra
            ldxa
            plo   ra
            ldxa
            phi   r8
            ldxa
            plo   r8
            ldxa
            phi   r7
            ldx
            plo   r7
 
            sep   sret                  ; return to caller



; ***************************************
; *** Check for valid file descriptor ***
; *** RD - file descriptor            ***
; *** Returns: DF=0 - valid FILDES    ***
; ***          DF=1 - Invalid FILDES  ***
; ***************************************
chkvld:    glo     rd                  ; save file descriptor position
           stxd
           ghi     rd
           stxd
           glo     rd                  ; point to flags byte
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags byte
           plo     re                  ; save it for a moment
           irx                         ; recover file descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
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

read:       sep   scall
            dw    chkvld
            lbnf  rdvalid

            ldi   2<<1 + 1              ; return d=2, df=1, invalid fd
            lbr   reterror

          ; Check size of read request, if it's zero, declare success.

rdvalid:    glo   rc                    ; if there is nothing to do, return
            lbnz  nonzero
            ghi   rc
            lbz   reterror              ; return d=0, df=0, success

nonzero:    glo   r8                    ; save r8.0 to use for flags
            stxd

            glo   r9                    ; save r9 to use for dta pointer
            stxd
            ghi   r9
            stxd

            glo   ra                    ; save ra for bytes requested
            stxd
            ghi   ra
            stxd

            glo   rb                    ; save rb to use for loop counter
            stxd
            ghi   rb
            stxd

            glo   rc                    ; copy bytes requested to ra
            plo   ra
            ghi   rc
            phi   ra

            ldi   0
            plo   r8                    ; clear flags byte
            plo   rc                    ; clear bytes read counter
            phi   rc


          ; loops back to here

readloop:   inc   rd
            inc   rd                    ; rd = fd+2 (file offset nlsb)


          ; Check if we have already checked for an eof adjustment to 
          ; reduce the read bytes requested, if so, dont do it again.

            glo   r8
            ani   1
            lbnz  readdata


          ; The following checks if we are in the "final lump" which is the
          ; last allocation unit in the file, and if so, we are near eof.
          ; Its not actually easily possible to know how much data is
          ; remaining in the file until we get to this point, as eof is only
          ; stored relative to the start of this final allocation unit.

            glo   rd                    ; this way we dont have to fix the
            adi   6                     ; result back if the branch below not
            plo   rb                    ; taken, also the separate copy is
            ghi   rd                    ; used even if the branch is taken
            adci  0
            phi   rb                    ; rb = fd+8 (flags)

            ldn   rb                    ; check final lump flag
            ani   4
            lbz   readdata


          ; If we are in the final lump, then calculate how much data is
          ; remaining in the file and if more data has been requested than
          ; is in the file, reduce the request to match what is available.
          ; Since the request size is kept across loops, this adjustment
          ; only needs to be done once, and only can be done once.

            inc   r8                    ; remember weve already done this

            dec   rb                    ; rb = fd+7 (eof offset lsb)
            inc   rd                    ; rd = fd+3 (file offset lsb)

            ldn   rb                    ; get eof offset lsb and subtract file
            sex   rd                    ; offset lsb from it
            sm 
            plo   r9

            dec   rd                    ; rd = fd+2 (file offset nlsb)
            dec   rb                    ; rb = fd+6 (eof offset msb)

            ldi   0fh                   ; and lump mask msb with file offset
            and                         ; nlsb, then subtract from eof offset
            sex   rb                    ; msb
            sdb
            phi   r9                    ; r9 = bytes to eof
            sex   r2

            lbnz  readneof              ; if bytes remaining to eof are not
            glo   r9                    ; zero then continue reading
            lbz   readpopr

readneof:   glo   r9
            str   r2
            glo   ra                    ; compare bytes left in file to bytes
            sd                          ; requested to read (ra)
            ghi   r9
            str   r2
            ghi   ra
            sdb
            lbdf  readdata              ; if ra <= bytes left leave as-is

            ghi   r9                    ; else replace request count with
            phi   ra                    ; what is actually left in file
            glo   r9 
            plo   ra


          ; Setup the source copy pointer into the current sector in memory
          ; and determine how much data we are going to copy, which will be
          ; the lesser of whats left in the sector or what was requested.

readdata:   lda   rd                    ; get sector offset as low 9 bits of
            ani   1
            phi   rb
            lda   rd                    ; rd = fd+4 (dta msb)
            plo   rb                    ; rb = sector offset

            sex   rd                    ; add dta address to sector offset
            inc   rd                    ; in rb and put result into r9
            glo   rb                    ; as copy source pointer
            add
            plo   r9
            dec   rd
            ghi   rb
            adc
            phi   r9                    ; rd = fd+4 (dta msb)
            sex   r2

            glo   rb                    ; find what is left in sector by
            sdi   512.0                 ; subtracting sector offset from 512
            plo   rb                    ; overwrite original value
            ghi   rb
            sdbi  512.1
            phi   rb

            glo   rb                    ; compare bytes requested to bytes
            str   r2
            glo   ra                    ; left in sector
            sm 
            ghi   rb
            str   r2
            ghi   ra
            smb
            lbdf  readleft              ; if fewer in sector, read that many

            ghi   ra                    ; otherwise read what was requested
            phi   rb
            glo   ra
            plo   rb
            lbr   readupdt

readleft:   inc   r8                    ; set flag to load more data
            inc   r8

readupdt:   glo   rb
            str   r2
            glo   ra                    ; subtract bytes we are going to copy 
            sm                          ; from bytes requested and at the 
            plo   ra                    ; same time put into loop counter rb
            ghi   rb
            str   r2
            ghi   ra
            smb
            phi   ra

            glo   rb                    ; add bytes we are going to copy to rc
            str   r2
            glo   rc
            add
            plo   rc
            ghi   rb
            str   r2
            ghi   rc
            adc
            phi   rc

            dec   rd                    ; rd = fd+3 (file offset lsb)

            sex   rd                    ; add the amount we are going to copy
            glo   rb                    ; onto the current file offset
            add
            stxd
            ghi   rb
            adc
            stxd
            ldi   0
            adc
            stxd
            ldi   0
            adc
            str   rd                    ; rd = fd+0 (base)
            sex   r2

          ; Loop is unrolled by factor of two to increase speed. This also
          ; helps by making the loop counter into a byte value.

            ghi   rb                    ; halve the loop count
            shr
            glo   rb
            shrc
            plo   rb

            lbdf  halfread              ; if odd then do a half-loop

readcopy:   dec   rb                    ; here because of half-loop

            lda   r9                    ; copy from dta to user buffer
            str   rf
            inc   rf
halfread:   lda   r9                  
            str   rf
            inc   rf

            glo   rb                    ; copy until finished
            lbnz  readcopy

            glo   r8                    ; check if flag is set to read data
            ani   2
            lbz   readrest              ; if not, we are done

            dec   r8                    ; clear read data flag
            dec   r8

            sep   scall                 ; get another sector
            dw    getnext

            glo   ra
            lbnz  readloop
            ghi   ra
            lbnz  readloop              ; and finish satisfying request

            lbr   readrest

readpopr:   dec   rd
            dec   rd                    ; rd = fd+0 (start)

readrest:   inc   r2

            lda   r2                    ; restore saved rb
            phi   rb
            lda   r2
            plo   rb

            lda   r2                    ; restore saved ra
            phi   ra
            lda   r2
            plo   ra

            lda   r2                    ; restore saved r9
            phi   r9
            lda   r2
            plo   r9

            ldn   r2
            plo   r8
 
            ldi   0

reterror:   shr
            sep   sret


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

write:      sep   scall
            dw    chkvld
            lbnf  wrvalid

            ldi   2<<1 + 1              ; return d=2, df=1, invalid fd
            lbr   reterror

          ; Check size of read request, if it's zero, declare success.

wrvalid:    glo   rc                    ; if there is nothing to do, return
            lbnz  chkwrite
            ghi   rc
            lbz   reterror              ; return d=0, df=0, success


          ; Only if this is a write operation, check the read-only flag.

chkwrite:   glo   re                    ; check if fd is read-only
            ani   2
            lbz   nordonly

            ldi   1<<1 + 1              ; return d=1, df=1, read-only
            lbr   reterror


          ; Push the registers that are used that are common to both
          ; the read and write code paths and initialize some register
          ; values that are also common to both. Put the read or write
          ; indicator into RE.0 at this point to survive the pushes.

nordonly:   glo   r9                    ; save r9 to use for dta pointer
            stxd
            ghi   r9
            stxd

            glo   ra                    ; save ra for bytes requested
            stxd
            ghi   ra
            stxd

            glo   rb                    ; save rb to use for loop counter
            stxd
            ghi   rb
            stxd

            glo   rc                    ; copy bytes requested to ra
            plo   ra
            ghi   rc
            phi   ra

            ldi   0
            plo   rc                    ; clear bytes read counter
            phi   rc

            glo   r6                    ; save r9 to use for dta pointer
            stxd
            ghi   r6
            stxd

            glo   r7                    ; save r9 to use for dta pointer
            stxd
            ghi   r7
            stxd


          ; Processing of write operations loops back to here

writloop:   inc   rd                    ; move to fildes+2
            inc   rd

            lda   rd                    ; get sector offset from file offset
            ani   1
            phi   rb
            lda   rd
            plo   rb

            sex   rd                    ; add dta address to sector offset
            inc   rd
            glo   rb
            add
            plo   r9
            dec   rd
            ghi   rb
            adc
            phi   r9

            glo   rb                    ; get amount of space left in sector
            sdi   512.0
            plo   rb
            ghi   rb
            sdbi  512.1
            phi   rb

            sex   r2                    ; and compare with bytes to write
            glo   rb
            str   r2
            glo   ra
            plo   r7
            sm 
            plo   ra
            ghi   rb
            str   r2
            ghi   ra
            phi   r7
            smb
            phi   ra

            lbdf  writupdt              ; if free space less write that much

            glo   r7                    ; subtract bytes to copy from request
            plo   rb
            ghi   r7
            phi   rb

            ldi   0
            plo   ra
            phi   ra

writupdt:   glo   rb                    ; add bytes to copy to completed
            str   r2
            glo   rc
            add
            plo   rc
            ghi   rb
            str   r2
            ghi   rc
            adc
            phi   rc

            dec   rd                    ; move to fildes + 3

            sex   rd                    ; add bytes to copy to file offset
            glo   rb
            add
            stxd
            ghi   rb
            adc
            stxd
            ldi   0
            adc
            stxd
            ldi   0
            adc
            str   rd                    ;  rd = fd+0 (base)
            sex   r2

          ; Loop is unrolled by factor of two to increase speed by doing twice
          ; as much per loop overhead. This also reduces that overhead by 
          ; making the loop counter into a byte value.

            ghi   rb                    ; halve the loop count
            shr
            glo   rb
            shrc
            plo   rb

            lbdf  writhalf              ; if odd then do a half-loop

writcopy:   dec   rb                    ; here because of half-loop

            lda   rf                    ; copy from user buffer to dta
            str   r9
            inc   r9
writhalf:   lda   rf
            str   r9
            inc   r9

            glo   rb                    ; copy until finished
            lbnz  writcopy

          ; The following checks if we are in the "final lump" which is the
          ; last allocation unit in the file, and if so, we are near eof.
          ; Its not actually easily possible to know how much data is
          ; remaining in the file until we get to this point, as eof is only
          ; stored relative to the start of this final allocation unit.

            glo   rd                    ; get pointer to fildes flags
            adi   8
            plo   r7
            ghi   rd
            adci  0
            phi   r7

            ldn   r7                    ; mark sector and file as written to
            ori   16+1
            str   r7

            ani   4                     ; check if in final lump
            lbz   notlast

          ; If we are in the final lump, then find if the file offset is
          ; past the eof offset, if it is, then update the eof offset to
          ; match the file offset since we are extending the file.

            dec   r7                    ; r7 = fd+7 (eof offset lsb)

            inc   rd
            inc   rd
            inc   rd                    ; rd = fd+3 (file offset lsb)

            ldn   rd                    ; get file offset lsb and subtract eof
            plo   r6
            sex   r7                    ; offset lsb from it
            sd

            dec   rd                    ; rd = fd+2 (file offset nlsb)
            dec   r7                    ; r7 = fd+6 (eof offset msb)

            ldi   0fh                   ; and lump mask msb with file offset
            sex   rd
            and                         ; nlsb, then subtract eof offset from it
            phi   r6
            sex   r7                    ; msb
            sdb
            sex   r2

            dec   rd
            dec   rd                    ; rd = fd+0 (begin)

            lbnf  updateof

            glo   r6
            lbnz  notlast
            ghi   r6
            lbnz  notlast

            sep   scall                 ; append a new lump if eof offset
            dw    append                ; wrapped to zero

updateof:   ghi   r6
            str   r7
            inc   r7
            glo   r6
            str   r7
            dec   r7

            glo   rd
            adi   2
            plo   r7
            ghi   rd
            adci  0
            phi   r7

            lda   r7
            ani   1
            lbnz  writtest
            ldn   r7
            lbnz  writtest

            sep   scall                 ; get another sector
            dw    getnext2

            lbr   writtest

notlast:    glo   rd
            adi   2
            plo   r7
            ghi   rd
            adci  0
            phi   r7

            lda   r7
            ani   1
            lbnz  writtest
            ldn   r7
            lbnz  writtest

            sep   scall                 ; get another sector
            dw    getnext

writtest:   glo   ra
            lbnz  writloop
            ghi   ra
            lbnz  writloop              ; and finish satisfying request

            inc   r2

            lda   r2                    ; restore saved r9
            phi   r7
            lda   r2
            plo   r7

            lda   r2                    ; restore saved r9
            phi   r6
            ldn   r2
            plo   r6

            inc   r2

            lda   r2                    ; restore saved rb
            phi   rb
            lda   r2
            plo   rb

            lda   r2                    ; restore saved ra
            phi   ra
            lda   r2
            plo   ra

            lda   r2                    ; restore saved r9
            phi   r9
            ldn   r2
            plo   r9

            ldi   0

            shr
            sep   sret

          ; ------------------------------------------------------------------
          ; Close an open file
          ;
          ; Input:
          ;   RD - file descriptor
          ; Returns:
          ;   DF - set if error

close:      glo   rb                    ; save for fildes working pointer
            stxd
            ghi   rb
            stxd

            glo   rd                    ; get pointer to flag byte in fildes
            adi   8
            plo   rb
            ghi   rd
            adci  0
            phi   rb

          ; Need to do two pre-flight checks. If the file is not opened, then
          ; return an immediate error. If the file was not written to, return
          ; an immediate success.

            ldn   rb                    ; if not open return with df set
            ani   8
            sdi   0
            lbz   noclose

            lda   rb                    ; if not written return df cleared
            ani   16
            lbz   noclose

          ; In the remaining case, an opened file that was written to, flush
          ; the DTA if it has been modified, and update the directory entry.

            glo   r9                    ; save rest of registers we need
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

            lda   rb                    ; get sector of directory entry
            phi   r8
            lda   rb
            plo   r8
            lda   rb
            phi   r7
            lda   rb
            plo   r7

          ; To avoid flushing a system buffer unnecessarily, we reuse the
          ; file's DTA to buffer it's directory entry to modify it. After
          ; all, we know the file is done with it anyway.
          ;
          ; Note that before rawread loads the directory sector, it will
          ; automatically flush the buffer data first if it's dirty.

            sep   scall                 ; read in sector, abort if error
            dw    rawread
            lbdf  closerr

          ; R9 now points to the entry within the loaded directory sector.
          ; Update the flags, EOF, and date and time into the buffer.

            lda   rb                    ; get entry offset plus eof field
            phi   r9
            lda   rb
            adi   4
            plo   r9

            glo   rd                    ; adjust fildes pointer to dta lsb
            adi   5
            plo   rb
            ghi   rd
            adci  0
            phi   rb

            sex   rb

            glo   r9                   ; add offset to dta to get address
            add
            plo   r9
            dec   rb
            ghi   r9
            adc
            phi   r9

          ; Since the file is open and has been written to, update the EOF
          ; count and the date and time in it's directory entry.

            inc   rb                    ; move to eof size field in fildes
            inc   rb

            lda   rb                    ; update eof into directory entry
            str   r9
            inc   r9
            lda   rb
            str   r9
            inc   r9

            ldn   r9                    ; set archve bit in directory entry
            ori   ff_archive
            str   r9
            inc   r9

            sep   scall                 ; write timestamp to directory entry
            dw    gettmdt

          ; Write the modified sector back to disk to finish closing the file.
          ;
          ; If the write fails, the file will be left open, but rawread will
          ; have succeeded in flushing any modified data sector if needed, so
          ; close could safely be called again.

            sep   scall                 ; write updated directory entry
            dw    rawrite
            lbdf  closerr

            ldi   0                     ; if written ok then clear all flags
            str   rb

closerr:    irx                         ; restore over working registers
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

noclose:    irx                         ; restore over  working pointer
            ldxa
            phi   rb
            ldx
            plo   rb

            sep   sret                  ; return with status set in df


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
; *** RB - filename (asciiz)            ***
; *** Returns: R8:R7 - Dir Sector       ***
; ***             R9 - Dir Offset       ***
; ***             RF - Dir Entry        ***
; ***          DF=0  - entry found      ***
; ***          DF=1  - entry not found  ***
; *****************************************

searchdir: sep     scall               ; get current sector and offset
           dw      getsecofs

           ldi     dirent.1            ; setup buffer
           phi     rf
           ldi     dirent.0
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

           ldi     dirent.1         ; setup buffer
           phi     rf
           ldi     dirent.0
           plo     rf

           lda     rf                  ; see if entry is valid
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lda     rf
           lbnz    entrygood

           lbr     searchdir           ; entry was no good, try again

entrygood: ldi     (dirent+12).1       ; setup buffer
           phi     rf
           ldi     (dirent+12).0
           plo     rf

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

           lbr     searchdir           ; char mismatch, check next entry

cmpzero:   ldn     rc                  ; if length matches, its a find
           lbz     searchyes

           smi     '/'                 ; if length mismatch, keep looking
           lbnz    searchdir

           inc     rc                  ; if ends in slash then skip past it
           lbr     searchyes

searchno:  ldi     1                   ; match not found, return failure
           lbr     searchex

searchyes: ldi     0                   ; match was found, return success

searchex:  shr

           ldi     dirent.1            ; setup buffer
           phi     rf
           ldi     dirent.0
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
            dw    lump2sec

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

           ldi     path.1              ; point to current dir
           phi     rf
           ldi     path.0
           plo     rf

findcont:  inc     rf                  ; move past leading slashes
           inc     rf

           sep     scall
           dw      openmd
           lbdf    finderr

           inc     rf

           sep     scall               ; follow path in current dir
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

           ldi     path.1              ; point to current dir
           phi     rf
           ldi     path.0
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

           ldi     defdir.1            ; point to default dir
           phi     rf
           ldi     defdir.0
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

           ldi     dirent.1            ; get buffer address
           phi     r9
           ldi     dirent.0
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

           ldi     dirent.1            ; get buffer address
           phi     rf
           ldi     dirent.0
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

           glo     rd                  ; point to last of fildes
           adi     18
           plo     rf
           ghi     rd
           adci    0
           phi     rf

           sex     rf

           ldi     -1                  ; set current sector to -1
           stxd
           stxd
           stxd
           stxd

           glo     r9                  ; set directory offset
           stxd
           ghi     r9
           stxd

           glo     r7                  ; set directory sector
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd

           ldi     0ch                 ; set flags
           stxd

           ldi     0                   ; set eof to zero
           stxd
           stxd

           dec     rf                  ; skip dta
           dec     rf

           stxd                        ; zero offset
           stxd
           stxd
           stxd

           ldi     0feh                ; need to set end of chain
           phi     rf
           plo     rf
           sep     scall
           dw      writelump

           sep     scall               ; convert lump to sector
           dw      lump2sec

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

newfilelp: ldi     dirent.1            ; setup buffer
           phi     rf
           ldi     dirent.0
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

           ldi     dirent.1            ; setup buffer
           phi     rf
           ldi     dirent.0
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

           sep     scall               ; perform directory search
           dw      searchdir
           lbdf    execfail            ; jump if failed to get dir

           sep     scall               ; close the directory
           dw      close

           ldi     intfildes.1         ; point to internal fildes
           phi     rd
           ldi     intfildes.0
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

open:      glo     r7                  ; save consumed registers
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
           glo     ra
           stxd
           ghi     ra
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

           glo     r7                  ; get copy of flags
           stxd                        ; and save

           sep     scall               ; find directory
           dw      finddir
           lbnf    gotdir

           irx
           lbr     openerr

gotdir:    sep     scall               ; perform directory search
           dw      searchdir
           lbdf    newfile             ; jump if file needs creation

           irx                         ; advance stack to open flags

           ldi     (dirent+6).1        ; get pointer to dirent flags
           phi     ra
           ldi     (dirent+6).0
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

           sep     scall
           dw      readlump

           ghi     ra
           phi     rc
           glo     ra
           plo     rc

           glo     ra
           smi     0feh
           lbnz    opentrun
           ghi     ra
           smi     0feh
           lbz     openreco

           sep     scall
           dw      writelump

opentrun:  sep     scall               ; delete the files chain
           dw      delchain

           ghi     rc
           phi     ra
           glo     rc
           plo     ra

           ldi     0feh
           phi     rf
           plo     rf

           sep     scall
           dw      writelump

openreco:  irx                         ; recover buffer position
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

           ldi     0
           plo     r7
           phi     r7
           plo     r8
           phi     r8

           ldi     2
           plo     rc

           sep     scall
           dw      seek


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

           ldi     dirent.1            ; where to put it
           phi     rf
           ldi     dirent.0
           plo     rf

           sep     scall               ; read the bytes
           dw      o_read

           glo     rc                  ; see if eof was hit
           smi     32
           lbnz    rmdireof            ; jump if dir was empty

           ldi     dirent.1            ; point to buffer
           phi     rf
           ldi     dirent.0
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

rmdireof:  glo     rd
           adi     9
           plo     rd
           ghi     rd
           adci    0
           phi     rd

           lda     rd                  ; get sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7

           lda     rd                  ; get offset
           phi     r9
           lda     rd
           plo     r9

           glo     rd                  ; move pointer back to beginning
           smi     15
           plo     rd
           ghi     rd
           smbi    0
           phi     rd

           sep     scall
           dw      rawread

           ghi     r9                  ; get offset into sector
           adi     intdta.1
           phi     r9

           inc     r9                  ; point to starting lump
           inc     r9

           lbr     delgo               ; and delete the dir


; *************************************
; *** delete a file                 ***
; *** RF - filename                 ***
; *** Returns:                      ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************

deleinit:  plo     re

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
           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd

           glo     re
           adi     2
           plo     r3


delete:    glo     r3
           br      deleinit

           sep     scall               ; find directory
           dw      finddir

           sep     scall               ; perform directory search
           dw      searchdir
           lbnf    delfile             ; jump if file exists

delfail:   ldi     1                   ; signal an error
           lbr     delexit

delfile:   sep     scall               ; read directory sector for file
           dw      rawread

           ghi     r9                  ; get offset into sector
           adi     intdta.1
           phi     r9 

           inc     r9                  ; point to flags
           inc     r9
           inc     r9
           inc     r9
           inc     r9
           inc     r9

           ldn     r9                  ; get flags
           ani     1                   ; see if directory
           lbz     delnotdir           ; jump if so

           ldi     (errisdir<<1)+1
           lbr     delexit

delnotdir: dec     r9                  ; point to starting lump
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
           dw      rawrite

           sep     scall               ; delete the chain
           dw      delchain

           ldi     0                   ; signal success

           lbr     delexit

           
; *************************************
; *** rename a file                 ***
; *** RF - filename                 ***
; *** RC - new filename             ***
; *** Returns:                      ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
rename:    glo     r3
           br      deleinit

           glo     rc                  ; save copy of destination filename
           stxd
           ghi     rc
           stxd

           sep     scall               ; find directory
           dw      finddir

           sep     scall               ; perform directory search
           dw      searchdir
           lbnf    renfile             ; jump if file exists

           irx                         ; drop filename from stack and fail
           irx
           lbr     delfail

renfile:   sep     scall               ; read directory sector for file
           dw      rawread

           glo     r9                  ; point to filename
           adi     12
           plo     r9
           ghi     r9                  ; get offset into sector
           adci    intdta.1
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
           dw      rawrite

           ldi     0                   ; signal success

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

execgo1:   ldi      intfildes.1          ; point to internal fildes
           phi      rd
           ldi      intfildes.0
           plo      rd

           ldi      0                    ; flags
           plo      r7

           sep      scall                ; attempt to open the file
           dw       open
           lbnf     opened               ; jump if it was opened

err:       ldi      9                    ; signal file not found error
           shr
           sep      sret

opened:    ldi      intflags.0           ; need to get flags
           plo      rf
           ldi      intflags.1
           phi      rf

           ldn      rf                   ; retrieve them
           ani      040h                 ; is file executable
           lbz      notexec              ; jump if not exeuctable file

           ldi      dirent.1             ; scratch space to read header
           phi      rf
           ldi      dirent.0
           plo      rf

           ldi      0                    ; need to read 6 bytes
           phi      rc
           ldi      6
           plo      rc

           sep      scall                ; read header
           dw       o_read

           ldi      dirent.1             ; point to load offset
           phi      r7
           ldi      dirent.0
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

           ldi      (heap+1).0           ; now subtract heap address
           plo      rb
           ldi      (heap+1).1
           phi      rb

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
           glo      rf
           stxd
           ghi      rf
           stxd
           ldi      lowmem.0
           plo      rf
           ldi      lowmem.1
           phi      rf
           ghi      rc
           adi      020h
           str      rf
           inc      rf
           glo      rc
           str      rf
           irx
           ldxa
           phi      rf
           ldx
           plo      rf
           sep      scall                ; read program block
           dw       o_read
;           dw       read
           ldi      progaddr.1           ; point to destination of call
           phi      rf
           ldi      progaddr.0
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
           ldi     retval.0             ; point to retval
           plo     r7
           ldi     retval.1
           phi     r7
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

mkdir:      glo   rf
            stxd
            ghi   rf
            stxd
            glo   rd
            stxd
            ghi   rd
            stxd
            glo   rc
            stxd
            ghi   rc
            stxd
            glo   rb
            stxd
            ghi   rb
            stxd
            glo   ra
            stxd
            ghi   ra
            stxd
            glo   r9
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



            ldn   rf                    ; error if filename is null
            lbz   mkdirer

            ghi   rf                    ; get copy of filename pointer
            phi   rb
            glo   rf
            plo   rb

mkdirlp:    lda   rb                    ; find end of path
            lbnz  mkdirlp

            dec   rb                    ; back to last character of path
            dec   rb

            ldn   rb                    ; if not slash then proceed
            smi   '/'
            lbnz  mkdirgo

            ldi   0                     ; if slash then remove
            str   rb



mkdirgo:    sep   scall                 ; if parent not exist then error
            dw    finddir
            lbdf  mkdirer

            sep   scall                 ; if file exists then error
            dw    searchdir
            lbnf  mkdirer




            glo   rb                    ; save filename pointer
            stxd
            ghi   rb
            stxd

            ghi   r8
            stxd

            sep   scall                 ; find a free dir entry
            dw    freedir

            irx                         ; recover filename
            ldxa
            phi   r8

            ldxa
            phi   rb
            ldx
            plo   rb



            sep   scall
            dw    freelump

            ldi   0feh
            phi   rf
            plo   rf

            sep   scall
            dw    writelump




            ldi   dirent.1
            phi   r9
            ldi   dirent.0
            plo   r9

            ldi   0                     ; initial zero bytes
            str   r9
            inc   r9
            str   r9
            inc   r9

            ghi   ra                    ; allocation unit
            str   r9
            inc   r9
            glo   ra
            str   r9
            inc   r9

            ldi   0                     ; end of file
            str   r9
            inc   r9
            str   r9
            inc   r9

            ldi   1                     ; flags are directory
            str   r9
            inc   r9
 
            sep   scall                 ; get current date/time
            dw    gettmdt
 
            ldi   0                     ; aux flags
            str   r9
            inc   r9

copynam:    lda   rb                    ; copy name
            str   r9
            inc   r9
            lbnz  copynam




            ldi   dirent.1              ; pointer to new dirent
            phi   rf
            ldi   dirent.0
            plo   rf

            ldi   0                     ; length of direct
            phi   rc
            ldi   32
            plo   rc

            sep   scall                 ; write dirent
            dw    write

            sep   scall                 ; close parent directory
            dw    close



            adi   0
            lbr   mkdirrt





mkdirer:    smi   0

mkdirrt:    irx                         ; recover consumed registers
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
            ldxa
            plo   r9
            ldxa
            phi   ra
            ldxa
            plo   ra
            ldxa
            phi   rb
            ldxa
            plo   rb
            ldxa
            phi   rc
            ldxa
            plo   rc
            ldxa
            phi   rd
            ldxa
            plo   rd
            ldxa
            phi   rf
            ldx
            plo   rf

            sep   sret                  ; and return to caller


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

           ldi     path.1              ; point to current dir storage
           phi     ra
           ldi     path.0
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

           ldi     path.1              ; get current dir
           phi     ra
           ldi     path.0
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
           



strloop:   inc   rd

instrcpy:  lda   r6
           str   rd
           bnz   strloop

           sep   sret

         ; -------------------------------------------------------------------

         ; Start by building the default current directory location into the
         ; the PATH variable so it is the boot drive as saved by COLDBOOT.

kinit:     ldi     bootdrv.1           ; point to saved boot disk number
           phi     rf
           ldi     bootdrv.0
           plo     rf

           ldn     rf                  ; get boot disk and extend to 16 bits
           plo     rd
           ldi     0
           phi     rd

           ldi     path.1              ; get pointer to current directory
           phi     rf
           ldi     path.0
           plo     rf

           ldi     '/'                 ; start the path with '//'
           str     rf
           inc     rf
           str     rf
           inc     rf

           sep     scall               ; convert to decimal string
           dw      f_intout

           ldi     '/'                 ; add trailing slash
           str     rf
           inc     rf

           ldi     0                   ; and zero terminate
           str     rf

         ; Next set DEFDIR to the /bin/ directory path on the boot disk by
         ; copying the current directory path and appending to it.

           ldi     path.1              ; copy from the current path
           phi     rf
           ldi     path.0
           plo     rf

           ldi     defdir.1            ; copy into default directory
           phi     rd
           ldi     defdir.0
           plo     rd

           sep     scall               ; first copy the current path
           dw      f_strcpy

           sep     scall               ; then append directory to it
           dw      instrcpy
           db      'bin/',0

         ; Finally set INITPRG to /bin/init path under the boot disk by
         ; copying DEFDIR and appending to it.

           ldi     defdir.1            ; copy from the default exec directory
           phi     rf
           ldi     defdir.0
           plo     rf

           ldi     initprg.1           ; copy to the init program path
           phi     rd
           ldi     initprg.0
           plo     rd

           sep     scall               ; first copy the exec directory path
           dw      f_strcpy

           sep     scall               ; then append init name to it
           dw      instrcpy
           db      'init',0

         ; Initialize the disk data tables and flush the sector buffers.

           sep     scall
           dw      flush

         ; Allocate the stack on the heap. Not sure how this plays if KINIT
         ; is called again after the kernel is already initialized. I guess
         ; worst case, the old stack gets abandoned on the heap. We'll leave
         ; the existing behavior alone for now.

           ldi     252.0               ; want to allocate 252 bytes on the heap
           plo     rc
           ldi     252.1
           phi     rc

           ldi     4.0                 ; allocate as a permanent block
           plo     r7
           ldi     4.1
           phi     r7

           sep     scall               ; allocate the memory
           dw      o_alloc

           ldi     (stackaddr+1).0     ; point to allocation pointer
           plo     r7
           ldi     (stackaddr+1).1
           phi     r7

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


         ; Initialize the disk-related tables that hold the size of each
         ; disk as well as where to start the search for a free lump. Note
         ; these need to be at the end of a page for this to work properly.

flush:     ldi     diskname.1
           phi     rf
           ldi     diskname.0
           plo     rf

flushdsk:  ldi     0
           str     rf
           inc     rf

           glo     rf
           lbnz    flushdsk


         ; Initialize the internal fildescriptors by resetting the loaded
         ; sector field to FFFFFFFF indicating no sector is loaded.

           ldi     (sysfildes+18).1
           phi     rf
           ldi     (sysfildes+18).0
           plo     rf

           sep     scall
           dw      flushfds

           ldi     (intfildes+18).1
           phi     rf
           ldi     (intfildes+18).0
           plo     rf

flushfds:  sex     rf

           ldi     255
           stxd
           stxd
           stxd
           stxd

           sep     sret






; ************************************************
; *** Initialize all vectors and data pointers ***
; ************************************************

coldboot:  ldi     start.1             ; get return address for setcall
           phi     r6
           ldi     start.0
           plo     r6

           ldi     0                   ; set stack to 00ff temporarily
           plo     r2
           dec     r2
           phi     r2

           lbr     o_initcall          ; setup call and return pointers

         ; We can now boot from drives other than zero. To do this, we need
         ; to know which drive is the boot drive, so that we can set the
         ; initial working directory and other paths correctly. The drive
         ; is passed in R8.1 by boot loaders that know this convention.
         ;
         ; For legacy boot loaders, which only support booting from drive
         ; zero, R8.1 should be set to 0xE0 (drive zero) anyway, from the
         ; boot loader's call to F_IDEREAD to load the kernel to memory.
         ;
         ; So that it's possible to call KINIT again later, which resets the
         ; current directory, we will save the drive here for later use. But
         ; we only save it the first time COLDBOOT is called so that it too
         ; can be called again later without needing R8.1 set first.

start:     ldi     coldini.1            ; pointer to first cold boot flag
           phi     rf
           ldi     coldini.0
           plo     rf

           ldn     rf                   ; skip if we have already set drive
           lbnz    skipdrv

           ghi     rf                   ; mark that we've already done it
           str     rf
           inc     rf

           ghi     r8                   ; and store the boot drive number
           ani     %11111
           str     rf

         ; Get the end of memory from BIOS, create the empty heap under it,
         ; and set the HEAP and HIMEM pointers accordingly.

skipdrv:   sep     scall               ; get pointer to last byte of memory
           dw      f_freemem

           ldi     heap.1              ; pointer to start of heap variable
           phi     r7
           ldi     heap.0
           plo     r7

           ghi     rf                  ; set heap to highest memory address
           str     r7
           inc     r7
           glo     rf
           str     r7

           ldi     0                   ; put end of heap marker into heap
           str     rf
           dec     rf

           ldi     himem.0             ; pointer to end of static memory
           plo     r7

           ghi     rf                  ; initialize to just below the heap
           str     r7
           inc     r7
           glo     rf
           str     r7


           sep     scall               ; call rest of kernel setup
           dw      kinit

           ldi     initprg.1           ; point to init program command line
           phi     rf
           ldi     initprg.0
           plo     rf

           sep     scall               ; attempt to execute it
           dw      o_exec
           lbnf    welcome             ; jump if no error

           sep     scall               ; get terminal baud rate
           dw      o_setbd

welcome:   ldi     bootmsg.1
           phi     rf
           ldi     bootmsg.0
           plo     rf

           sep     scall
           dw      o_msg
     
warmboot:  plo     re                  ; save return value
           ldi     retval.0            ; point to retval
           plo     rf
           ldi     retval.1
           phi     rf
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
           ldi     stackaddr.0         ; point to system stack address
           plo     rc
           ldi     stackaddr.1
           phi     rc
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
           
warm2:     sep     scall               ; cull the heap
           dw      d_reapheap
           lbr     d_progend
warm3:

; *************************
; *** Main command loop ***
; *************************
cmdlp:     ldi      prompt.1             ; get address of prompt into R6
           phi      rf
           ldi      prompt.0
           plo      rf

           sep      scall
           dw       o_msg                ; function to print a message

           ldi      keybuf.1             ; place address of keybuffer in R6
           phi      rf
           ldi      keybuf.0
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

           sep      scall
           dw       flush

           lbr      cmdlp


noctrlc:   sep      scall
           dw       o_inmsg              ; function to print a message
           db       13,10,0

           ldi      keybuf.1            ; place address of keybuffer in R6
           phi      rf
           ldi      keybuf.0
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
 
curerr:    ldi      keybuf.1             ; place address of keybuffer in R6
           phi      rf
           ldi      keybuf.0
           plo      rf

skipspc2:  lda      rf
           sdi      ' '
           lbdf     skipspc2

           dec      rf

           sep      scall                ; call exec function
           dw       execbin
           lbdf     loaderr              ; jump on error

           lbr      cmdlp                ; loop back for next command

loaderr:   ldi      errnf.1              ; point to not found message
           phi      rf
           ldi      errnf.0
           plo      rf

           sep      scall                ; display it
           dw       o_msg

           lbr      cmdlp                ; loop back for next command


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

           ldi     datetime.1          ; point to scratch area
           phi     rf
           ldi     datetime.0
           plo     rf

           ghi     rc                  ; save due to bug in mbios
           stxd

           sep     scall               ; get time and date
           dw      o_gettod

           irx                         ; restore
           ldx
           phi     rc

no_rtc:    ldi     datetime.1          ; point to scratch area
           phi     rf
           ldi     datetime.0
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

alloc:      glo     r9                  ; save consumed registers
            stxd
            ghi     r9
            stxd
            glo     rd
            stxd
            ghi     rd
            stxd
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

alloc_ext:  irx                         ; recover consumed registers
            ldxa
            phi     rd
            ldx
            plo     rd
            irx
            ldxa
            phi     r9
            ldx
            plo     r9
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
dealloc:    glo     r9                  ; save consumed registers
            stxd
            ghi     r9
            stxd
            glo     rd
            stxd
            ghi     rd
            stxd
            glo      rf
            stxd
            ghi      rf
            stxd
            dec     rf                  ; move to flags byte
            dec     rf
            dec     rf
            ldi     1                   ; mark block as free
            str     rf
heapgc:     glo     rc
            stxd
            ghi     rc
            stxd
            glo     rd
            stxd
            ghi     rd
            stxd
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
heapgc_dn:  irx
            ldxa
            phi     rd
            ldx
            plo     rd
            irx
            ldxa
            phi     rc
            ldx
            plo     rc
            irx
            ldxa
            phi      rf
            ldx
            plo      rf
            lbr     sethimem

sethimem:   glo      rf
            stxd
            ghi      rf
            stxd
            glo     rd
            stxd
            ghi     rd
            stxd
            ldi     (heap+1).0
            plo     rf
            ldi     (heap+1).1
            phi     rf
            ldi     (himem+1).0
            plo     rd
            ldi     (himem+1).1
            phi     rd
            ldn     rf
            smi     1
            str     rd
            dec     rf
            dec     rd
            ldn     rf
            smbi    0
            str     rd
            irx
            ldxa
            phi     rd
            ldx
            plo     rd
            irx
            ldxa
            phi      rf
            ldx
            plo      rf
            adi     0                   ; signal no error
            lbr     alloc_ext           ; return to caller

; ****************************************************
; ***** Deallocate any non-permanent heap blocks *****
; ****************************************************
reapheap:   glo     r9                  ; save consumed registers
            stxd
            ghi     r9
            stxd
            glo     rd
            stxd
            ghi     rd
            stxd
            glo      rf
            stxd
            ghi      rf
            stxd
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
checkeom:   glo     rc
            stxd
            ghi     rc
            stxd
            glo     r9
            stxd
            ghi     r9
            stxd
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
oomret:     irx
            ldxa
            phi     r9
            ldx
            plo     r9
            irx
            ldxa
            phi     rc
            ldx
            plo     rc
            sep     sret                ; and return to caller
oom:        smi     0                   ; set df 
            lbr     oomret



bootmsg:    db     'Mini/DOS 4.3.7',10,13
            db     'Visit github.com/dmadole/MiniDOS',10,13,0
prompt:     db     10,13,'Ready',10,13,': ',0
errnf:      db     'File not found.',10,13,0

          ; These paths are overwritten by KINIT with the correct boot drive
          ; number. Include two digits here so enough space is allocated.

initprg:    db     '//31/bin/init',0
defdir:     db     '//31/bin/',0

          ; BOOTDRV holds the boot drive that is passed in R8.1 into COLDBOOT
          ; so KINIT can retrieve it later. Maybe this becomes a published
          ; variable at some point, but for now it is private.
          ;
          ; COLDINI is used to make note when we do this so that it only 
          ; happens on the first call to COLDBOOT for backwards compatibility.
          ; Keep the both of these variables adjacent and in this order.

coldini:    db     0
bootdrv:    db     0


         #if $>1d20h
         #error Kernel size overflow
         #endif

           org     1d20h

         ; Used for buffering directory entries.
         
dirent:    ds    32

           org     1d40h

         ; The tables that follow are for caching information about disks.
         ; These are all arrays of 16-bit words, one element per each disk.
         ; Because of optimization in code, they need to end at a page.

diskname:  ds    64                     ; hash of volume name
disksize:  ds    64                     ; size of disk
lumphint:  ds    64                     ; next lump to search from

         ; The DTA for the "internal" filedescriptor which is used for opening
         ; directories including the master one, and loading executables.

intdta:    ds    512

