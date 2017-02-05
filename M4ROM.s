			
			; M4 Board cpc z80 rom
			; Written by Duke, 2016
			; www.spinpoint.org
			
			.module cpc
			.area _HEADER (ABS)
			.org 0xC000
			.include "ff.i"	
			.include "firmware.i"
			.include "m4cmds.i"

rom_response					.equ	0xE800
rom_config					.equ rom_response+0xC00
sock_status					.equ	0xFE00
rom_table						.equ	0xFF00
UDIR_RAM_Address 				.equ 0xBEA3

DATAPORT						.equ 0xFE00
ACKPORT						.equ 0xFC00

			.db	0x01
			.db	2, 0, 0
	
			.dw	rsx_commands

			; RSX jump block
			
			jp 	init_rom		;			0xC006
			jp	patch_fio		; |SD 		0xC009
			jp	disc			; |DISC		0xC00C
			jp	change_dir	; |CD		0xC00F
			jp	copy_file		; |COPYF		0xC012
			jp	tape			; |TAPE		0xC015
			jp	httpget		; |HTTPGET	0xC018
			jp	httpgetmem	; |HTTPMEM	0xC01B
			jp	drvA			; |A			0xC01E
			jp	drvB			; |B			0xC021
			jp	drive		; |DRIVE		0xC024
			jp	user			; |USER		0xC027
			jp 	directory		; |DIR		0xC02A
			jp	erase_file	; |ERA		0xC02D
			jp	rename_file	; |REN		0xC030
			jp	set_message	; 0x81		0xC033
			jp	setup_disc	; 0x82		0xC036
			jp	select_format	; 0x83		0xC039
			jp	read_sector	; 0x84		0xC03C
			jp	write_sector	; 0x85		0xC03F
			jp	format_track	; 0x86		0xC042
			jp	move_track	; 0x87		0xC045
			jp	get_dr_status	; 0x88		0xC048
			jp	set_retry_cnt	; 0x89		0xC04B
			jp	m4off		; |M4ROMOFF	0xC04E
			jp	makedir		; |MKDIR		0xC051
			jp	setnetwork	; |NETSET		0xC054
			jp	netstat		; |NETSTAT	0xC057
			jp	gettime		; |TIME		0xC05A
			jp	upgrade		; |UPGRADE	0xC05D
			jp	version		; |VERSION	0xC060
			jp	rom_upload	; |ROMUP		0xC063
			jp	rom_set		; |ROMSET		0xC066
			jp	rom_update	; |ROMUPD		0xC069
			jp 	ls			; |ls		0xC06C
			jp	UDIR			; |UDIR		0xC06F
			jp	init_plus		;			0xC072
			jp	GETPATH		; |UDIR		0xC075
			jp	LongName		; |UDIR		0xC078
  			jp	wifi_power
  			jp	file_copy
rsx_commands:
			.ascis "M4 BOARD"	
			.ascis "SD"
			.ascis "DISC"
			.ascis "CD"
			.ascis "COPYF"
			.ascis "TAPE"
			.ascis "HTTPGET"
			.ascis "HTTPMEM"
			.ascis "A"
			.ascis "B"
			.ascis "DRIVE"
			.ascis "USER"
			.ascis "DIR"
			.ascis "ERA"
			.ascis "REN"
			.db 0x81	; Set message
			.db 0x82	; Drive speed
			.db 0x83	; Disc type
			.db 0x84	; Read sector
			.db 0x85	; Write sector
			.db 0x86	; Format track
			.db 0x87	; Seek track
			.db 0x88	; Test drive
			.db 0x89	; Set retry count
			.ascis "M4ROMOFF"
			.ascis "MKDIR"
			.ascis "NETSET"
			.ascis "NETSTAT"
			.ascis "TIME"
			.ascis "UPGRADE"
			.ascis "VERSION"
			.ascis "ROMUP"
			.ascis "ROMSET"
			.ascis "ROMUPD"
			.ascis "LS"
			.ascis "UDIR"
			.db	0x8A	; plus init
			.ascis "GETPATH"
			.ascis "LONGNAME"
			.ascis "WIFI"
			.ascis "FCP"
			.db 0

; work space map
; 000-073 : Amsdos openin header (if amsdos not present, otherwise use amsdos cas_in_header)
; 074-143 : Amsdos openout header	(if amsdos not present, otherwise use amsdos cas_out_header)
; 144-272	: actual work buffer

cas_out_isdirect	.equ	-5
cas_buf_l			.equ -4
cas_buf_h			.equ -3
cas_idx_l			.equ -2
cas_idx_h			.equ -1
cas_size_l 		.equ	19	; data len
cas_size_h 		.equ	20

; user bytes in use

cas_in_next_byte	.equ 0x23
cas_in_eof		.equ	0x24


init_rom:		push de
			push hl
			pop	iy
		
			; detect if amsdos present?
			ld	a,(0xBC77)
			cp	#0xDF			
			jr	z, use_amsdos
			
			ld	bc,#-276			; 144+128
			add	iy,bc
			
			
			jr	init_cnt
use_amsdos:
			ld	bc,#-128			; 128
			add	iy,bc
init_cnt:		push	iy				; workspace start
			
			ld	de, #fio_jvec
init_cont:			
			ld	(iy),#19+3			; config size+3 (to increase)
			ld	1(iy),#C_CONFIG
			ld	2(iy),#C_CONFIG>>8
			ld	3(iy),#0			; config offset (0..251)
			ld	6(iy),e			; 02 patch jump vector l
			ld	7(iy),d			; 03 patch jump vector h
			call #hi_kl_curr_selection
			ld	8(iy),a			; 04 current rom
			ld	9(iy),#0			; 05 init count.
			ld	a,#0x80
			cp	c
			jr	z,amsdos_buffers
			push	iy
			pop	hl
			
			ld	bc,#5
			add	hl,bc			; point to amsdos in header
			
			ld	4(iy),l			; 00 amsdos in header l
			ld	5(iy),h			; 01 amsdos in header  h
			ld	bc,#74
			add	hl,bc			
			ld	10(iy),l			; 06 amsdos out header l
			ld	11(iy),h			; 07 amsdos out header h
			ld	bc,#74-5
			add	hl,bc		
			ld	20(iy),#0
			ld	21(iy),#0
				
			jr	no_amsdos_buffers
amsdos_buffers:
			ld	hl,(0xBE7D)
			ld	bc,#0x55
			add	hl,bc			; point to amsdos in header
			
			ld	4(iy),l			; 00 amsdos in header l
			ld	5(iy),h			; 01 amsdos in header  h
			ld	bc,#74
			add	hl,bc			
			ld	10(iy),l			; 06 amsdos out header l
			ld	11(iy),h			; 07 amsdos out header h
			
			ld	hl,(0xBE7D)
			dec	hl
			dec	hl
			ld	a,(hl)			; amsdos rom number
			ld	c,a
			ld	21(iy),c
			call	#0xB915			; probe rom
			ld	20(iy),h			; amsdos version
			push	iy
			pop	hl
			inc	hl
no_amsdos_buffers:
			ld	12(iy),l			; 08 regular workspace for rom l
			ld	13(iy),h			; 09 regular workspace for rom h
			push	iy
			pop	hl
			ld	de,#14
			add	hl,de
			ex	de,hl
			ld	hl,#0xbb5a
			ldi
			ldi
			ldi
			ld	hl,#0xbc6e
			ldi
			ldi
			ldi
			ld	c,#0		; check basic rom ver
			call	#0xB915	
			ld	22(iy),h
			call	send_command_iy
			; save amsdos or tape functions
			; BCA7-BC77 = 48
			
			ld	(iy),#48+3		; config size+3 
			ld	1(iy),#C_CONFIG
			ld	2(iy),#C_CONFIG>>8
			ld	3(iy),#22			; config offset
			push	iy
			pop	de
			inc	de
			inc	de
			inc	de
			inc	de
			ld	hl,#0xBC77
			ld	bc,#48
			ldir
			call	send_command_iy
		
			call	patch_fio
			pop	hl
			pop	de
			and	a
			scf
			ret
			
init_plus:	ld	hl,#0
			jp	mc_start_program

init_msg:
			.ascii " M4 Board V2.0"
			.db 10, 13, 10, 13, 0

			; ------------------------- strlen
			; -- parameters:
			; -- HL = zero terminated string
			; -- return:
			; -- A = length

strlen:
			push	bc
			push	hl
			ld	b,#0
strlen_loop:
			ld	a,(hl)
			cp	#0
			jr	z, term
			inc	hl
			inc	b
			jr	strlen_loop
term:
			ld	a,b
			pop	hl
			pop	bc
			ret
temp:
			scf
			sbc	a,a
			ret
			
			; ------------------------- strcpy
			; -- parameters:
			; -- HL = string
			; -- DE = dest.
			; -- B = string len
			; -- return:
			; -- A = length

strcpy:
			push	bc
			push	hl
			push	de
	
strcpy_loop:
			ld	a,(hl)
			ld	(de),a
			inc	hl
			inc	de
			djnz	strcpy_loop
			xor	a
			ld	(de),a
			pop	de
			pop	hl
			pop	bc
			ld	a,b
			inc	a
			ret

			; same but remove spaces
strcpynz:
			push	bc
			push	hl
			push	de
			ld	c,#0
strcpy_loopnz:
			ld	a,(hl)
			cp	#32
			jr	z,skip_space
			ld	(de),a
			inc	de
			inc	c
skip_space:			
			inc	hl
			djnz	strcpy_loopnz
			xor	a
			ld	(de),a
			pop	de
			pop	hl
			ld	a,c
			pop	bc
			inc	a
			ret

upper_case:
			cp	#'a'
			ret	c
			cp	#'z'+1
			ret	nc
			and	#0xDF
			ret
			; ------------------------- strcpy83
			; -- parameters:
			; -- HL = string
			; -- DE = dest.
			; -- B = string len
			; -- return:
			; -- A = length

strcpy83:
			push	bc
			push	hl
			push	de
	
			; loop through first 8 characters, if we encounter '.' pad with zeros.
			
			ld	c,b	; in length
			ld	b,#8
			
copy8:
			ld	a,c
			cp	#0
			jr	z,space_pad
			ld	a,(hl)
			cp	#0x2E	; are we at extension yet?
			jr	z,space_pad
			dec	c			; decrease inlength
			inc	hl
			call	upper_case
			jr	cont_strcpy83
space_pad:
			ld	a,#32
cont_strcpy83:
			ld	(de),a
			inc	de
			djnz	copy8
			
			ld	b,#3
			ld	a,(hl)
			cp	#0x2E	; are we at extension yet?
			jr	z, has_ext
			ld	c,#1			; no (valid) extension
has_ext:
			inc	hl			
			dec	c
			
copy3:		ld	a,c
			cp	#0
			jr	z,space_pad2
			ld	a,(hl)
			inc	hl
			dec	c
			call	upper_case
			jr	cont_strcpy83_2
space_pad2:
			ld	a,#32
cont_strcpy83_2:
			ld	(de),a
			inc	de
			djnz	copy3
			ld	a,#0
			ld	(de),a
			pop	de
			pop	hl
			pop	bc
			ret
; ------------------------- fio jump vector
; AMSDOS 0xCD30
fio_jvec:		di
			ex	af,af'
			exx
			ld	a,c
			pop	de				; return address
			pop	bc				; workspace?
			pop	hl 				; 0x85 10000101 (disable upperrom)
			ex	(sp),hl			; get jump entry from stack
			push	bc				;
			push de				;
			ld	c,a				; 
			ld	b,#0x7f			
			ld	de,#cas_hook_table-0xbc77-3; offset from bc77
			add	hl,de			; add offset to jump table
			push hl				; save it on stack
			exx					; restore
			ex	af,af'
			ei
			ret
		
cas_hook_table:	
			jp _cas_in_open	; BC77
			jp _cas_in_close	; BC7A
			jp _cas_in_abandon	; BC7D
			jp _cas_in_char	; BC80
			jp _cas_in_direct	; BC83
			jp _cas_return		; BC86
			jp _cas_test_eof	; BC89
			jp _cas_out_open	; BC8C
			jp _cas_out_close	; BC8F
			jp _cas_out_abandon ; BC92
			jp _cas_out_char	; BC95
			jp _cas_out_direct	; BC98
			jp _cas_catalog	; BC9B

			; ------------------------- cas_in_open  replacement	BC77 
			; -- parameters
			; -- HL = filename
			; -- DE = 0 or 2Kbuffer
			; -- B = filename len
			; -- returns
			; -- carry true if valid
			; -- HL ptr to AMSDOS header
			; -- DE load address
			; -- BC filesize (-header)
			; -- A file type
			
_cas_in_open:	push	iy
			push	hl
			push	de
			push	bc
			ld	a,#FA_READ			; read mode
			call	fopen
			cp	#0xFF
			jr	nz, open_ok
			ld	a,b
			cp	#0x92	; file not found? set Z flag.
			jr	nz,other_open_error
			
			pop	bc	; len
			pop	de
			pop	hl	; filename
			
			push	hl
			push	de
			push	bc
			push	af
			ld	iy,(#rom_workspace)
			push	iy
			pop	de		; dest
			call strcpy83	; hl = filename, de =workspace, b = len
			ld	hl,#8
			add	hl,de	; +12
			ld	e,l
			ld	d,h
			push	hl
			inc	de
			ldi
			ldi
			ldi
			pop	hl
			ld	a,#'.'
			ld	(hl),a
			; de = workspace
			ld	hl,#text_not_found
			ld	bc,#13
			ldir
			push	iy
			pop	hl
			call	disp_msg
			pop	af
other_open_error:
			pop	bc
			pop	de
			pop	hl
			pop	iy
			scf
			ccf
			ret
open_ok:

			; read first 128 bytes and check if its using AMSDOS header
			
			ld	iy,(#amsdos_inheader)
			push	iy
			pop	de					; DE address =  ptr to amsdos header
			ld	hl,#69				; size of header
			ld	a,#1					; fd
			call	fread
			
				
			; DE still amsdos header ptr
			push	de
			; check checksum
			ld	b,#66
			ld	hl,#0
checksum_loop:
			push	bc
			ld	a,(de)
			ld	c,a
			ld	b,#0
			inc	de
			add	hl,bc
			pop	bc
			djnz	checksum_loop
			
			ld	cas_size_l(iy),#0			;	
			ld	cas_size_h(iy),#0			;	size
			; clear internal vars
			
			
			ld	cas_in_eof(iy),#0
			ld	cas_in_next_byte(iy),#0			; next char for test eof
		
			; compare with header checksum
			ld	a,l
			cp	67(iy)
			jr	nz, checksum_mismatch
			ld	a,h
			cp	68(iy)
			jr	z, checksum_ok
			
			; deal with headerless file
checksum_mismatch:
			; build "fake" header
			ld	hl,#0
			ld	a,#1
			call	fseek
			
			; clear header
			
			pop	hl			; header
			ld	b,#69
clear_loop:
			ld	(hl),#0
			inc	hl
			djnz	clear_loop			
			
			; copy filename into "fake" header
			pop	bc	; b = filename len
			pop	de	; 2k buffer or 0
			ld	21(iy),e
			ld	22(iy),d
			ld	cas_buf_l(iy),e
			ld	cas_buf_h(iy),d
			ld	cas_idx_l(iy),e
			ld	cas_idx_h(iy),d
			pop	hl	; filename
			push	iy
			pop	de
			inc	de
			call	strcpy83
			ld	18(iy),#0x16; set as ascii?
			ld	23(iy),#0xFF	; first block 0xFF
			ld	66(iy),#0x80
			;ld	de,#0;	x170			; load adr
			;ld	e,19(iy)
			;ld	d,20(iy)
			;ld	iy,(#rom_workspace)
			;ld	1(iy),#C_FSIZE		
			;ld	2(iy),#C_FSIZE>>8
			;ld	3(iy),#1			
			;ld	(iy),#3
			;call send_command_iy
			ld	bc,#0  ;(#rom_response+3)	; size
			;ld	iy,(#amsdos_inheader)
			ld	e,cas_buf_l(iy)
			ld	d,cas_buf_h(iy)
			push	iy
			pop	hl
			
				;or	a	; z = 0
			scf		; c = 1
			sbc	a,a
			ld	a,#0x16	; x2
			pop	iy
			ret
	
checksum_ok:	
			ld	hl,#128	; ignore rest of header (unused)
			ld	a,#1
			call	fseek
		
			pop	hl
			pop	de	; b =filename len
			pop	de	; 2k buffer or 0
			ld	cas_buf_l(iy),e
			ld	cas_buf_h(iy),d
			ld	cas_idx_l(iy),e
			ld	cas_idx_h(iy),d
		
			pop	de	; filename

			
			
			; DE = load address
			ld	e,21(iy)
			ld	d,22(iy)
			; BC = file size
			ld	c,24(iy)
			ld	b,25(iy)
			; A= file type
			
			scf	; set carry flag
			sbc	a,a	; clear z	
			ld	a,18(iy)
			
			pop	iy

			ret
open_fail:
			pop	de
			pop	iy

			call	_cas_in_close
			or	a	
			
			ret

; ------------------------- cas_in_close replacement BC7A

_cas_in_close:
			; detect
			
			ld	a,#1
			call	fclose
			cp	#0
			scf
			jr	nz,close_fail
			sbc	a,a
			ret
close_fail:
			ccf	
			ret
; ------------------------- cas_in_abandon replacement BC7D

_cas_in_abandon:
			ld	a,#1
			call	fclose
			scf
			sbc	a,a
			ret

C_SDEBUG .equ 0x43FF
debug:		push bc
			push af
			ld	bc,#DATAPORT				; data out port
			out (c),c
			ld	a,#C_SDEBUG
			out	(c),a						; command lo
			ld	a,#C_SDEBUG>>8
			out	(c),a						; command	hi
			pop	af
			out	(c),a	
			ld	bc,#ACKPORT
			out (c),c							
			pop bc
			ret			
; ------------------------- cas_in_char replacment BC80 
_cas_in_char:
			push	hl
			push	bc
			push de
			push	iy
			ld	iy,(#amsdos_inheader)
		
			; size > 0
			
			ld	e,cas_size_l(iy)			;	size
			ld	d,cas_size_h(iy)			;	
			xor	a
			cp	e
			jr	nz, no_buffer_fill
			cp	d
			jr	nz, no_buffer_fill
			
			; EOF flag set ?
			ld	b,#0xF			; set hard EOF
			ld	a,cas_in_eof(iy)			; EOF yet?
			cp	#0
			jp	nz, char_in_eof
			
			; re-fill buffer
	
			ld	bc,#DATAPORT				; data out port
			out (c),c
			ld	a,#C_READ2
			out	(c),a						; command lo
			ld	a,#C_READ2>>8
			out	(c),a						; command	hi
			ld	a,#1
			out	(c),a						; output char
			xor	a
			out	(c),a	
			ld	a,#8
			out	(c),a	
			ld	bc,#ACKPORT
			out (c),c							; tell M4 that command has been send
		
			; check rom response
				
			ld	a,(#rom_response+3)
			cp	#20				; eof ?
			jr	nz, not_eof_yet
			; Set EOF flag
			
			ld	a,#1
			ld	cas_in_eof(iy),a			; this is end of file
			; check if read size == 0
			ld	hl,(#rom_response+4)	; read size
			xor	a
			cp	h
			jr	nz, not_eof_yet
			cp	l
			jr	nz, not_eof_yet
			ld	b,#0xF			; set hard end
			jr	char_in_eof
not_eof_yet:			
			
			ld	hl,(#rom_response+4)	; read size
			ld	cas_size_l(iy),l			; size
			ld	cas_size_h(iy),h			;	
			;ld	hl,(#rom_response+6)
			ld	c,l
			ld	b,h
			ld	hl,#rom_response+8
			
			ld	e, cas_buf_l(iy)
			ld	d, cas_buf_h(iy)
			ld	cas_idx_l(iy),e			; index
			ld	cas_idx_h(iy),d			; index
			
			xor	a
			cp	e
			jr	nz, buf_is_set
			cp	d
			jr	z, no_buffer_fill
buf_is_set:			
			ldir
			
			
no_buffer_fill:
		
			;ld	hl,#rom_response+8
			
			ld	l,cas_idx_l(iy)			;	index
			ld	h,cas_idx_h(iy)			; 
			rst	#0x20
			ld	b,a
			inc	hl
			ld	cas_idx_l(iy),l			;	index
			ld	cas_idx_h(iy),h			; 
			rst	#0x20
			ld	l, cas_size_l(iy)			; size
			ld	h, cas_size_h(iy)
			dec	hl
			ld	cas_size_l(iy),l			; size
			ld	cas_size_h(iy),h			;	
		
			ld	cas_in_next_byte(iy),a
			
			ld	a,#26
			cp	b
			jr	z, char_in_eof
			or	a	; z = 0
			scf		; c = 1
			ld	a,b
			pop	iy
			pop	de
			pop	bc
			pop	hl
			ret


char_in_eof:	or	a	; z = 0
			scf
			ccf		; c = 0
			ld	a,b	; get either 0xF or 0x1A
			pop	iy
			pop	de
			pop	bc
			pop	hl
			ret
		
	
			; ------------------------- cas_in_direct replacement BC83
			; -- parameters
			; -- HL = load address
			; -- returns
			; -- HL = exec addr

_cas_in_direct:
			push iy
			ld	iy,(#amsdos_inheader)
			push	bc
	
			; A = fd
			ld	a,#1
			
			; DE = address
			ex	de,hl
			
			; HL = size
			ld	l,24(iy)
			ld	h,25(iy)
			call	fread
			cp	#0
			jr	nz,in_direct_error
			; get exec addr
			ld	l,26(iy)
			ld	h,27(iy)
			pop	bc
			pop	iy
			scf
			sbc	a,a
			ret
in_direct_error:
			pop	bc
			pop	iy
			or	a	; clear carry
			ret
; ------------------------- cas_return replacement BC86	
_cas_return:
			push	hl
			push	de
			push	bc
			push	af
			ld	hl,#ftell_cmd
			call	send_command
			ld	hl,(#rom_response+3)
			dec	hl
			ld	a,#1
			call	fseek
			pop	af
			pop	bc
			pop	de
			pop	hl
			ret
; ------------------------- cas_test_eof replacement BC89	
_cas_test_eof:	push	hl
			push	de
			push	iy
		
			ld	iy,(#amsdos_inheader)
			ld	a,cas_in_next_byte(iy)			; last char+1
			cp	#0x1A
			jr	z,is_eof

			ld	l,cas_size_l(iy)
			ld	h,cas_size_h(iy)
				
			; size > 0 ?
			
			xor	a
			cp	cas_size_l(iy)
			jr	nz, not_eof
			cp	cas_size_h(iy)
			jr	nz, not_eof
			
			; EOF flag set ?
			ld	a,cas_in_eof(iy)			; EOF yet?
			cp	#0
			jr	z, not_eof
			ld	a,#0xF
is_eof:		pop	iy
			pop	de
			pop	hl
			or	a	; z = 0
			scf		
			ccf		; c = 0
			ret	
			
not_eof:		
			pop	iy
			pop	de
			pop	hl
			ld	a,#0x20
			or	a	; z = 0
			scf		; c = 1
			ret			
			
; ------------------------- cas_out_close replacement BC8F
_cas_out_close:
			push	iy
			ld	iy,(#amsdos_outheader)
			ld	a, cas_out_isdirect(iy)
			cp	#1
			jr	z,no_header
			; refresh header
			
			ld	hl,#0
			ld	a,#2
			call fseek
			
			; calc checksum
			ld	b,#66
			ld	hl,#0
			; 	de point to amsdos header
			ld	de,(#amsdos_outheader)
calc_checksum_loop2:
			push	bc
			ld	a,(de)
			ld	c,a
			ld	b,#0
			inc	de
			add	hl,bc
			pop	bc
			djnz	calc_checksum_loop2
			; save checksum
			ld	67(iy), l
			ld	68(iy), h
			
			push	iy
			pop	de			; amsdos header
			ld	hl,#128	; size
			jr	do_cas_out_close
no_header:	
			; write out remaining buffer (if any)
			ld	l, cas_idx_l(iy)
			ld	h, cas_idx_h(iy)
			ld	e, cas_buf_l(iy)			
			ld	d, cas_buf_h(iy)		
			or	a
			push	de
			sbc	hl,de		; size
			pop	de			; addr
do_cas_out_close:
			ld	a,#2			; fd
			call	fwrite
			ld	a,#2
			call	fclose
			cp	#0
			scf
			jr	nz,close_out_fail
			sbc	a,a
			pop	iy
			ret
close_out_fail:
			ccf	
			pop	iy
			ret

; ------------------------- cas_out_abandon replacement BC92
_cas_out_abandon:
			ld	a,#2
			call	fclose
			scf
			sbc	a,a
			ret
; ------------------------- cas_out_open  replacement	BC8C
; -- parameters
; -- HL = filename
; -- DE = 2Kbuffer
; -- B = filename len
; -- returns
; -- HL holds the address of the buffer containing the file header data that will be written to each block.
; -- carry true if valid
; -- zero false

_cas_out_open:
			push	iy
			ld	a,#FA_WRITE | FA_CREATE_ALWAYS	; write mode
			call	fopen
			cp	#0xFF
			jr	nz, open_w_ok
			pop	iy
			or	a			; clear carry
			ret
open_w_ok:	push	bc
			ld	iy,(#amsdos_outheader)
			
			ld	cas_out_isdirect(iy),#1
			ld	cas_size_l(iy),#0			;	
			ld	cas_size_h(iy),#8			; size
			ld	cas_buf_l(iy),e			; 2k buffer
			ld	cas_buf_h(iy),d			; 
			ld	cas_idx_l(iy),e			; 
			ld	cas_idx_h(iy),d			; index
			
			
			; create	header
			push	iy
			pop	de
			ld	b, #69
clr_head:
			ld	(iy),#0
			inc	iy
			djnz	clr_head
			
			inc	de	; amsdos header +1
			pop	bc	; filename length
			; hl = filename
			call	strcpy83
			ex	de,hl
			dec	hl	; HL points to AMSDOS header
			pop	iy
			ld	a,#0xff
			or	a	; z = 0
			scf		; c = 1
			ret
; ------------------------- cas_out_char  replacement	BC95
; -- parameters
; -- A = char
_cas_out_char:	push	iy
			push	hl
			push	de
			push	bc
			push	af
			ld	iy,(#amsdos_outheader)
			ld	c, cas_buf_l(iy)
			ld	b, cas_buf_h(iy)
			ld	l, cas_idx_l(iy)
			ld	h, cas_idx_h(iy)
			or	a
			sbc	hl,bc			; index - buf = size
			ld	a, cas_size_l(iy)
			cp	l
			jr	nz,no_writeback
			ld	a, cas_size_h(iy)
			cp	h
			jr	nz,no_writeback
			ld	e, cas_buf_l(iy)			
			ld	d, cas_buf_h(iy)	
			ld	cas_idx_l(iy),e
			ld	cas_idx_h(iy),d
			ld	cas_size_l(iy),#0
			ld	cas_size_h(iy),#8
			;ld	hl,#0x800		; size
			ld	a,#2			; fd
			call	fwrite
			

no_writeback:	ld	l, cas_idx_l(iy)			
			ld	h, cas_idx_h(iy)		
			pop	af
			ld	(hl),a
			inc	hl
			ld	cas_idx_l(iy), l
			ld	cas_idx_h(iy), h
		
			pop	bc
			pop	de
			pop	hl
			pop	iy
			or	a					; z = 0
			scf						; c = 1
			ret


			; ------------------------- cas_out_open  replacement	BC98
			; -- parameters
			; -- HL = address of data
			; -- DE = size of data
			; -- BC = execution address
			; --  A = filetype
_cas_out_direct:
			push	iy
			ld	iy,(#amsdos_outheader)
			ld	cas_out_isdirect(iy),#2
			; fill in header details
			; HL load address
			ld	21(iy),l
			ld	22(iy),h
			; DE = size
			ld	24(iy),e
			ld	64(iy),e
			ld	25(iy),d
			ld	65(iy),d
			; BC = exec addr
			ld	26(iy),c
			ld	27(iy),b
			; A = type
			ld	18(iy),a
			; calc checksum
			ld	b,#66
			ld	hl,#0
			; 	de point to amsdos header
			push	iy
			pop	de
calc_checksum_loop:
			push	bc
			ld	a,(de)
			ld	c,a
			ld	b,#0
			inc	de
			add	hl,bc
			pop	bc
			djnz	calc_checksum_loop
			; save checksum
			ld	67(iy), l
			ld	68(iy), h
			
			push	iy
			pop	de			; amsdos header
			ld	hl,#128	; size
			ld	a,#2			; fd
			call	fwrite
			cp	#0
			jr	nz, out_direct_error
			
			; address
			ld	e,21(iy)
			ld	d,22(iy)
			; size
			ld	l, 24(iy)
			ld	h, 25(iy)
			; fd
			ld	a,#2			; fd
			call	fwrite
			cp	#0
			jr	nz, out_direct_error
			pop	iy
			scf
			sbc	a,a
			ret
out_direct_error:
			pop	iy
			or	a
			ret
			
; ------------------------- patch file I/O 
patch_fio:
				
			
			ld	hl,#jump_vec
			ld	de,#0xbca4	;	// overwrite cas check...
			push	de
			ldi
			ldi
			ldi
			ld	hl,#cas_in_open
			ld	(hl),#0xdf
			inc	hl
			pop	de
			ld	(hl),e
			inc	hl
			ld	(hl),d
			ld	hl,#cas_in_open
			ld	de,#cas_in_close
			ld	bc,#36
			ldir 
			ret
patch_fio_in:
			ld	hl,#jump_vec
			ld	de,#0xbca4	;	// overwrite cas check...
			push	de
			ldi
			ldi
			ldi
			ld	hl,#cas_in_open
			ld	(hl),#0xdf
			inc	hl
			pop	de
			ld	(hl),e
			inc	hl
			ld	(hl),d
			ld	hl,#cas_in_open
			ld	de,#cas_in_close
			ld	bc,#6*3
			ldir 
			ld	de,#cas_catalog
			ld	bc,#3
			ldir
			ret			
patch_fio_out:
			ld	hl,#jump_vec
			ld	de,#0xbca4	;	// overwrite cas check...
			push	de
			ldi
			ldi
			ldi
			ld	hl,#cas_out_open
			ld	(hl),#0xdf
			inc	hl
			pop	de
			ld	(hl),e
			inc	hl
			ld	(hl),d
			ld	hl,#cas_out_open
			ld	de,#cas_out_close
			ld	bc,#4*3
			ldir 
			ret			
autoexec_patch:
			ld	hl,#jump_vec2
			ld	de,#0xbc6e
			ldi
			ldi
			ld	hl,#rom_num
			ldi
			ld	hl,#0xbb5a
			ld	(hl),#0xdf
			inc	hl
			ld	(hl),#0x6e
			inc	hl
			ld	(hl),#0xbc
			ret
undo_patch2:
			ld	hl,#old_bb5a
			ld	de,#0xbb5a
			ldi
			ldi
			ldi
			ld	hl,#old_bc6e
			ld	de,#0xbc6e
			ldi
			ldi
			ldi
			ret
			
			; ------------------------- fopen
			; -- parameters: 
			; -- HL = filename
			; -- B = filename length
			; -- A = mode
			; -- return:
			; -- A = file fd (255 if error!)
			; -- B = error code
fopen:
			push	bc
			push	de
			push	hl
			push	iy
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_OPEN
			ld	2(iy),#C_OPEN>>8
			ld	3(iy),a			; mode
			ld	a,h
			cp	#0xC0			; is filename stored in screen?
			jr	c,filename_not_screen
			; lets copy it to our work ram
			push	bc
			ld	c,b			; filename len
			ld	b,#0
			push	hl			; save filename src addr
			push	bc			; filename len
	
			push	iy
			pop	hl			; dest
			ld	bc,#0x30
			add	hl,bc
			ex	de,hl		; de is dest addr
			pop	bc			; restore len
			pop	hl			; restore src addr
			push	de
			call	#0xB91B		; copy into 'readable' workram
			pop	hl			; new src for filename
			pop	bc			; b = filename len
filename_not_screen:
			push	iy
			pop	de
			inc	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	a, #3			; cmd (2) + mode (1) + filename
			ld	(iy),a			; packet length
			call send_command_iy
			
			ld	a,(#rom_response+4)	; check if open was OK?
			cp	#0
			jr	nz, fd_not_ok
			ld	a,(#rom_response+3)	; file descriptor 
			pop	iy
			pop	hl
			pop	de
			pop	bc
			ret
fd_not_ok:	
			; translate the error
			cp	#255
			jr	z, skip_err_lookup
			ld	e,a
			ld	d,#0
			ld	hl,#ff_error_map
			add	hl,de
			ld	a,(hl)
skip_err_lookup:
			pop	iy
			pop	hl
			pop	de
			pop	bc
			ld	b,a
			ld	a,#255
			or	a			; clear carry
			ret

			; ------------------------- fwrite
			; -- parameters: 
			; -- A = fd
			; -- HL = size
			; -- DE = addr
			; -- return:
			; -- A = 0 if OK
fwrite:
			push	iy
			push	hl
			push	de
			push	bc
			ld	iy,(#rom_workspace)
			ld	c,a				; fd
			
write_loop:
			ld	a,d
			cp	#0xC0			; is it screen, then we need to copy with rom disabled
			jr	c,not_screen
			; get chunk size (<=0x80)
	
			ld	a,h
			cp	a,#0
			jr	nz,scr_full_chunk
			ld	a,l
			cp	#0x80
			jr	c,scr_fwrite_cont
scr_full_chunk:
			ld	a,#0x80
scr_fwrite_cont:
			cp	a,#0
			jr	z,write_done		; size is 0?
	
			; A = size
			; HL = data
			; DE = COMMAND
			; C = fd
			push	hl				; total size
			ex	de,hl
			; HL = addr
			push	hl
			push	iy
			pop	de
			push bc
			ld	c,a
			ld	b,#0
			call	#0xB91B
			pop	bc
			push	iy
			pop	hl
			
			ld	de,#C_WRITE		; write cmd
			
			call send_command2
			
			pop	hl
			pop	de
			push	bc
			ld	b,#0
			ld	c,a				; size
			add	hl,bc			; increase address
			ex	de,hl			; DE = addr
			or	a				; clear carry
			sbc	hl,bc			; and substract chunksize
			pop	bc
			jr	write_loop
			
not_screen:

			; get chunk size (<=0xFC)
	
			ld	a,h
			cp	a,#0
			jr	nz,wfull_chunk
			ld	a,l
			cp	#0xFC
			jr	c,fwrite_cont
wfull_chunk:
			ld	a,#0xFC
fwrite_cont:
			cp	a,#0
			jr	z,write_done		; size is 0?
	
			; A = size
			; HL = data
			; DE = COMMAND
			; C = fd
			push	hl				; total size
			ex	de,hl
			; HL = addr
			
			ld	de,#C_WRITE		; write cmd
			
			call send_command2
			; todo, add error check!
			pop	de
			push	bc
			ld	b,#0
			ld	c,a				; size
			add	hl,bc			; increase address
			ex	de,hl			; DE = addr
			or	a				; clear carry
			sbc	hl,bc			; and substract chunksize
			pop	bc
			jr	write_loop
write_done:
			pop	bc
			pop	de
			pop	hl
			pop	iy
			ret

			; ------------------------- fread
			; -- parameters: 
			; -- A = fd
			; -- HL = size
			; -- DE = addr
			; -- return:
			; -- A = 0 if OK
fread:
			push	hl
			push	de
			push	bc
			push	iy
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_READ
			ld	2(iy),#C_READ>>8
			ld	3(iy),a				; fd
			ld	(iy),#5				; packet size, cmd (2), fd (1), size (2)

read_loop:
			; get chunk size (<=0x800)
			
			push	hl
			ld	bc,#-0x800
			add	hl,bc				; and substract chunksize
			jp	c, full_chunk
			pop 	hl
			ld	4(iy),l				; chunk size low
			ld	5(iy),h				; chunk size high
			jr	fread_cont
	
full_chunk:
			pop	hl
			ld	4(iy),#0x0			; chunk size low
			ld	5(iy),#0x8			; chunk size high
fread_cont:
			ld	a,#0
			cp	4(iy)
			jr	nz,not_done			; size is 0?
			cp	5(iy)
			jr	nz,not_done			; size is 0?
			pop	iy
			pop	bc
			pop	de
			pop	hl
			xor	a
			ret
not_done:
			push	hl
			call	send_command_iy	; send read command packet
			ld	c,4(iy)			; chunk size low
			ld	b,5(iy)			; chunk size high
			ld	hl,#rom_response+3	; src buffer
			
			ld	a,(hl)			; check result
			cp	#0
			jr	nz,read_error
			inc	hl
			push	bc				; store chunk size
			ldir					; copy data in place
			pop	bc				; restore chunk size
			pop	hl				; restore remaining size
			or	a				; clear carry
			sbc	hl,bc			; and substract chunksize
			jr	read_loop
read_error:
			pop	hl
			pop	iy
			pop	bc
			pop	de
			pop	hl
			ret

; ------------------------- fseek
; -- parameters:
; -- A = fd 
; -- HL = offset
fseek:
			push	iy
			push	bc
			push	hl
			push	de
			
			ld	iy,(#rom_workspace)
			ld	(iy),#7			; size.. cmd(2) + offset (4)
			ld	1(iy),#C_SEEK		; cmd seek
			ld	2(iy),#C_SEEK>>8	; cmd seek
			ld	3(iy),a			; fd
			ld	4(iy),l			; offset lo
			ld	5(iy),h			; offset hi
			ld	6(iy),#0			; 0
			ld	7(iy),#0			; 0
			call	send_command_iy
			
			pop	de
			pop	hl
			pop	bc
			pop	iy
			ret

; ------------------------- fclose
; -- parameters: 
; -- A = file fd
; -- return
; -- A = 0, good. A = 0xFF bad.
fclose:
			push	bc
			push	hl
			push	iy
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_CLOSE		; close cmd
			ld	2(iy),#C_CLOSE>>8	; close cmd
			ld	3(iy),a			; fd
			ld	(iy),#3	; size - cmd(2) + fd(1)
			call send_command_iy
			ld	a,(rom_response+3)
			cp	#255
			jp	nz,fclose_ok
			
			ld	a,(init_count)
			cp	#2	
			jp	z,past_autoexec
			inc	a
			ld	(iy),#4
			ld	1(iy),#C_CONFIG
			ld	2(iy),#C_CONFIG>>8
			ld	3(iy),#5			; config offset (0..251)
			ld	4(iy),a	
			call	send_command_iy
			ld	a,(init_count)
			cp	#2
			jp	nz, past_autoexec
			xor	a
			ld (UDIR_RAM_Address),a
			
			
			; run autoexec.bas if present

			ld	hl,#init_msg
			call	disp_msg
			
			call	autoexec_patch
			
past_autoexec:	ld	a,#255		
fclose_ok:	;xor	a
			pop	iy
			pop	hl
			pop	bc
			ret

load_autoexec:	
			di
			ex	af,af'
			exx
			ld	a,c
			pop	de
			pop	bc				
			pop	hl
			ex	(sp),hl
			push	bc	
			push de
			ld	c,a
			ld	b,#0x7f			
			ld	hl,#autoexec1
			push hl
			exx
			ex	af,af'
			ei
			ret
autoexec1:			
			push	af
			push	bc
			push	de
			push	hl
			push	iy
			call	undo_patch2
			ld	iy,(#rom_workspace)
			ld	hl, #runfile_ptr
			ld	e,(hl)
			inc	hl
			ld	d,(hl)
			push	de
			; reset filename ptr back to autoexec.bas, in case it was overwritten, for next softreset!
			ld	hl, #autoexec_fn
			ld	(iy),#3+2
			ld	1(iy),#C_CONFIG
			ld	2(iy),#C_CONFIG>>8
			ld	3(iy),#20			; config offset (0..251)
			ld	4(iy),l
			ld	5(iy),h
				
			call	send_command_iy
			pop	hl
			call	strlen
			add	#3
			ld	c,#0x80 | FA_READ
			
			
			ld	de, #C_OPEN
			call	send_command2	
			ld	hl,#rom_response+3
			ld	b,(hl)		; fd
			inc	hl
			ld	a,(hl)		; res
			cp	#0
			jp	nz, past_autoexec2
			
			; check if file size > 0 
			
			ld	1(iy),#C_FSIZE		
			ld	2(iy),#C_FSIZE>>8
			ld	3(iy),b			; fd
			ld	(iy),#3
			push	bc
			call send_command_iy
			pop	bc
			ld	hl,(#rom_response+3)
			xor	a
			cp	h
			jr	nz,autoexec_not0
			cp	l
			jr	nz,autoexec_not0
			ld	1(iy),#C_CLOSE		; close cmd
			ld	2(iy),#C_CLOSE>>8	; close cmd
			ld	3(iy),b			; fd
			ld	(iy),#3	; size - cmd(2) + fd(1)
			call send_command_iy
			jp	past_autoexec2
			
autoexec_not0:			
			; get header
			ld	a,b
			ld	de,(#amsdos_inheader)
			ld	hl, #69
			push	af
			call	fread
			pop	af
			ld	hl,#128	; ignore rest of header (unused)
			push	af
			call	fseek
			pop	af
			
			; load addr 
			ld	iy,(#amsdos_inheader)
			ld	e,21(iy)
			ld	d,22(iy)
			; HL = file size
			ld	l,24(iy)
			ld	h,25(iy)
	
			ld	iy,(#rom_workspace)
			push	hl
			push	af
			call	fread
			pop	af
			ld	1(iy),#C_CLOSE		; close cmd
			ld	2(iy),#C_CLOSE>>8	; close cmd
			ld	3(iy),a			; fd
			ld	(iy),#3	; size - cmd(2) + fd(1)
			call send_command_iy
			
			; check if binary file
			ld	a,18(iy)
			cp	#2
			jr	z,exec_binary
			
			;ld	c,#0
			;call	#0xB915	; probe rom
			ld	a,(basic_ver)	; version
			pop	hl
			ld	bc,#0x170
			add	hl,bc
	
			
			cp	#0		; is basic 1.0
			jr	z,basic10
			; basic 1.1
			ld (#0xAE66),hl
			ld (#0xAE68),hl
			ld (#0xAE6A),hl
			ld (#0xAE6C),hl
			jr	go_far
basic10:
			ld (#0xAE83),hl
			ld (#0xAE85),hl
			ld (#0xAE87),hl
			ld (#0xAE89),hl	
		
go_far:		cp	#0
			jr	z,is464
			cp	#1
			jr	z,is664
			.db	0xDF
			.dw far_addr6128
past_autoexec2:
			pop	iy
			pop	hl
			pop	de
			pop	bc
			pop	af
			jp	0xbb5a
			
is664:		.db	0xDF
			.dw far_addr664

is464:		.db	0xDF
			.dw far_addr464

far_addr464:	.dw	0xE9BD
			.db	0
far_addr664:	
			.dw	0xEA7D
			.db	0
far_addr6128:	
			.dw	0xEA78
			.db	0
exec_binary:	
			; get entry point
			ld	l,19(iy)
			ld	h,20(iy)
			pop	iy
			pop	de	; was hl
			pop	de
			pop	bc
			pop	af
			jp	(hl)
			
			; ------------------------- _cas_catalog replacement BC9B
			; input
			; DE = workbuf
			; return
			; DE = workbuf
_cas_catalog:
			push	bc
			push	de
			push	hl
			push	iy
		
			
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_DIRSETARGS
			ld	2(iy),#C_DIRSETARGS>>8
			
			; store workbuf and index (max 2k)
			ld	120(iy),e
			ld	121(iy),d
			ld	122(iy),#0
			ld	123(iy),#0
			
			call	dir_no_args
			pop	iy
			pop	hl
			pop	de
			pop	bc
			ret
			scf
			sbc	a,a
			ret	
directory:	ld	iy,(#rom_workspace)
			push	hl
			push	bc
			push	af
			
			; is it for amsdos?
			ld	b,#11
			ld	a,(0xBC78)
			cp	#0xA4
			jp	nz,pass_to_amsdos
			
			pop	af
			pop	bc
			pop	hl	
			
			; set no workbuf
			ld	120(iy),#0
			ld	121(iy),#0
			
			
			ld	1(iy),#C_DIRSETARGS
			ld	2(iy),#C_DIRSETARGS>>8
			cp	#1
			jp	nz, dir_no_args
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			push	iy
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	#2
			ld	(iy),a
			call	send_command_iy
			jr	directory_cont
dir_no_args:	
			ld	(iy), #3
			ld	3(iy),#0
			call	send_command_iy
directory_cont:			
			call	txt_get_window			; TXT GET WINDOW
			ld	a,d
			inc	a
			ld	c,#0
div1:
			inc	c
			sub	#20
			jp	pe, div_ovfl
			cp	#0
			
			jr	nz, div1
div_ovfl:			
			; c = number of columns
			push	bc
			ld	hl,#text_drive
			call	disp_msg
			; display current path
			ld	0(iy),#2
			ld	1(iy),#C_GETPATH
			ld	2(iy),#C_GETPATH>>8
			call	send_command_iy
			ld	hl,#rom_response+3
			call	disp_msg
			call	crlf
			call	crlf
			
			pop	bc
			ld	b,#0
dir_loop1:

			push	bc
			ld	hl,#sdir_cmd
			call	send_command
			ld	hl,#rom_response
			ld	a,(hl)
			cp	#2
			jr	nz, sdir_cont1
			ld	hl,#sfree_cmd
			call	send_command
			
			pop	bc
			ld	a,b
			cp	c
			jr	z,was_last_column1
			; add extra cr/lf, if last dir entry wasn't printed in last column
			ld	a,#13
			call	txt_output
			ld	a,#10
			call	txt_output
was_last_column1:	
			ld	hl,#rom_response+3
			call	disp_msg
			scf
			sbc	a,a
			ret	
sdir_cont1:	inc	hl
			inc	hl
			inc	hl
			call	direntry_workbuf
			ld	b,#17
disp_name_loop:
			ld	a,(hl)
			inc	hl
			call	txt_output
			djnz	disp_name_loop
			;call	disp_msg
			pop	bc
			inc	b
			ld	a,b
			cp	c
			jr	nz,next_column1
			ld	a,#13
			call	txt_output
			ld	a,#10
			call	txt_output
		
			jr	dir_loop1
next_column1:
			ld	a,#32
			call	txt_output
			call	txt_output
			call	txt_output
			; check for ESC
			call	check_esc_key
			cp	#0xFC	; pressed twice ? ok leave...
			jr	nz,dir_loop1
			ld	hl,#text_break
			call	disp_msg
			; exit
			scf
			sbc	a,a
			ret	
			
check_esc_key:	di
			push	bc
			call	km_read_char
			jr	nc, esc_exit			
			cp	#0xFC
			jr	nz, esc_exit
			; wait for release
esc_loop:		call	km_read_char
			jr	c, esc_loop
			
			
wait_key:		call	km_read_char
			jr	nc,wait_key
esc_exit:
			pop	bc
			ei
			ret
direntry_workbuf:
			push	hl
			push	de
			push	bc
			xor	a
			ld	e, 120(iy)
			ld	d, 121(iy)
			cp	d
			jr	nz, dir_buf_is_set
			cp	e
			jr	z,no_dir_buf
dir_buf_is_set:
			ld	c, 122(iy); get index
			ld	b, 123(iy)
			
			ld	a,#0xFC
			cp	c		; end of buf? (14*146=0x7FC)
			jr	nz, dir_buf_not_full
			ld	a,#0x7
			cp	b
			jr	z,no_dir_buf
dir_buf_not_full:
			; de = workbuf
			; hl = dir entry
			ex	de,hl	
			add	hl,bc	; workbuf + current entry 
			ld	a,#0xFF	; mark 
			ld	(hl),a
			inc	hl
			ex	de,hl	
			ld	bc,#8	; copy first 8 bytes
			ldir			; 1+8
			inc	hl		; skip the dot
			ld	bc,#3	; 1+8+3 = 12
			ldir			; copy the extension
			ld	bc,#6	; skip ascii file size + terminator
			add	hl,bc
			ldi			; copy file size in binary
			ldi			; 1+8+3+2 = 14
			xor	a
			ld	(de),a	; set next entry to 0 if this was last
			
			ld	hl,#14	; increase index
			ld	c, 122(iy); get index
			ld	b, 123(iy)
			add	hl,bc
			ld	122(iy),l	; get index
			ld	123(iy),h
			
			
no_dir_buf:	pop	bc
			pop	de
			pop	hl
			ret
			
			; ------------------------- LS command
			; displays directory with long filenames
			; mode 0 15 chars
			; mode 1 35 chars
			; mode 2 75 chars
			; +3 chars for folders
ls:
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_DIRSETARGS
			ld	2(iy),#C_DIRSETARGS>>8
			cp	#1
			jp	nz, ls_no_args
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			push	iy
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	#2
			ld	(iy),a
			call	send_command_iy
			jr	ls_cont
ls_no_args:	
			ld	(iy), #3
			ld	3(iy),#0
			call	send_command_iy
ls_cont:			
			ld	hl,#text_drive
			call	disp_msg
			; display current path
			ld	0(iy),#2
			ld	1(iy),#C_GETPATH
			ld	2(iy),#C_GETPATH>>8
			call	send_command_iy
			ld	hl,#rom_response+3
			call	disp_msg
			call	crlf
			call	crlf
			
			call	txt_get_window		; get max width
			ld	a,d
			sub	#4
			ld	d,a
						
ls_loop:		ld	a,#3
			ld	bc,#DATAPORT
			out	(c),a			; size cmd + maxfilenamelen
			ld	a,#C_READDIR
			out	(c),a
			ld	a,#C_READDIR>>8
			out	(c),a

			out	(c),d		; maxfilenamelen
			ld	b,#ACKPORT>>8
			out	(c),c
			
			ld	hl,#rom_response
			ld	a,(hl)
			cp	#2
			jr	z, ls_done
			; display entry
			ld	hl,#rom_response+3
			call	disp_msg
			ld	a,(rom_response+3)
			cp	#'>'
			jr	nz,isfile
			call	crlf
			jr	ls_cont1
isfile:		ld	a,d
			push	hl
			inc	a
			call	txt_set_column
			pop	hl
			; display size
			inc	hl
			
			call	disp_msg
ls_cont1:		
			call	check_esc_key
			cp	#0xFC	; pressed twice ? ok leave...
			jr	nz,ls_loop
			ld	hl,#text_break
			call	disp_msg
			; exit
			scf
			sbc	a,a
			ret	
			
			
ls_done:			
			ld	hl,#sfree_cmd
			call	send_command
			call	crlf			
			ld	hl,#rom_response+3
			call	disp_msg
			scf
			sbc	a,a
			ret	
; ------------------------- HTTP GET - download file from http to current path
httpget:
			ld	iy,(#rom_workspace)
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			push	iy
			ld	1(iy),#0x20
			ld	2(iy),#0x43
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	#2
			ld	(iy),a
			call	send_command_iy
			ld	hl,#rom_response+3
			call	disp_msg
			scf
			sbc	a,a
			ret

; ------------------------- setup wifi
setnetwork:
			cp	#1
			jp	nz, bad_args
			ld	iy,(#rom_workspace)
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			push	iy
			ld	1(iy),#C_SETNETWORK
			ld	2(iy),#C_SETNETWORK>>8
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	#2
			ld	(iy),a
			call	send_command_iy
			scf
			sbc	a,a
			ret
			
; ------------------------- get network status
netstat:
			ld	iy,(#rom_workspace)
			ld	(iy),#2
			ld	1(iy),#C_NETSTAT
			ld	2(iy),#C_NETSTAT>>8
			call	send_command_iy
			
			ld	hl,#rom_response
			ld	a,(rom_response)
			ld	e,a
			ld	d,#0
			add	hl,de
			ld	a,(hl)
			cp	#5
			jr	z,is_connected
			
			ld	hl,#rom_response+3
			call	disp_msg
			jp	skip_signal
is_connected:			
			ld	(iy),#2
			ld	1(iy),#C_NETRSSI
			ld	2(iy),#C_NETRSSI>>8
			call	send_command_iy
			ld	a,(rom_response+3)
			cp	#31
			jr	z,skip_signal
			
			ld	hl,#text_signal
			call	disp_msg
			ld	a,(rom_response+3)
			call	disp_hex
			call	crlf
			ld	(iy),#2
			ld	1(iy),#C_GETNETWORK
			ld	2(iy),#C_GETNETWORK>>8
			call	send_command_iy
			ld	hl,#text_ip
			call	disp_msg
			ld	hl,#rom_response+3+112
			call	disp_ip		
			ld	hl,#text_nm
			call	disp_msg
			ld	hl,#rom_response+3+116
			call	disp_ip		
			ld	hl,#text_gw
			call	disp_msg
			ld	hl,#rom_response+3+120
			call	disp_ip		
			ld	hl,#text_dns1
			call	disp_msg
			ld	hl,#rom_response+3+124
			call	disp_ip
			ld	hl,#text_dns2
			call	disp_msg
			ld	hl,#rom_response+3+128
			call	disp_ip
			ld	hl,#text_mac
			call	disp_msg
			ld	hl,#rom_response+3+190
			call	disp_mac
			
skip_signal:
			scf
			sbc	a,a
			ret
disp_mac:		ld	b,#5
disp_mac_loop:
			push	hl
			push bc
			ld	a,(hl)
			call	disp_hex
			pop	bc
			pop	hl
			inc	hl
			ld	a,#":"
			call	txt_output
			djnz	disp_mac_loop
			ld	a,(hl)
			call	disp_hex
			jp	crlf
			
disp_ip:		ld	b,#3
disp_ip_loop:
			push	hl
			push	bc
			call	dispdec
			pop	bc
			pop	hl
			inc	hl
			ld	a,#0x2e
			call	txt_output
			djnz	disp_ip_loop
			; last digit
			call	dispdec
			jp	crlf
			
			
; ------------------------- get time and date
gettime:
			ld	iy,(#rom_workspace)
			ld	(iy),#2
			ld	1(iy),#C_TIME
			ld	2(iy),#C_TIME>>8
			call	send_command_iy
			
			ld	hl,#rom_response+3
			call	disp_msg
			scf
			sbc	a,a
			ret
; ------------------------- get version
version:
			ld	iy,(#rom_workspace)
			ld	(iy),#2
			ld	1(iy),#C_VERSION
			ld	2(iy),#C_VERSION>>8
			call	send_command_iy
			
			ld	hl,#rom_response+3
			call	disp_msg
			scf
			sbc	a,a
			ret
; ------------------------- get upgrades if available
upgrade:
			ld	iy,(#rom_workspace)
			ld	(iy),#2
			ld	1(iy),#C_UPGRADE
			ld	2(iy),#C_UPGRADE>>8
			call	send_command_iy
			
			ld	hl,#rom_response+3
			call	disp_msg
			scf
			sbc	a,a
			ret
; ------------------------- get upgrades if available
httpgetmem:
			cp	#3			; 2 arguments?
			jp	nz, bad_args
			ld	iy,(#rom_workspace)
			; command
			ld	1(iy),#C_HTTPGETMEM
			ld	2(iy),#C_HTTPGETMEM>>8
			
			; get size
			ld	c,(ix)
			ld	b,1(ix)
			ld	3(iy),c
			ld	4(iy),b
			
			; get address
			ld	e,2(ix)
			ld	d,3(ix)
			push	de				; store destination address
			ld	l,4(ix)
			ld	h,5(ix)
			ld	b,(hl)			; string len
			inc	hl
			ld	e,(hl)			; string ptr lo
			inc	hl
			ld	d,(hl)			; string ptr hi
			; de string ptr
			push	iy
			pop	hl
			push	bc
			ld	bc,#5
			add	hl,bc
			; hl dest
			ex	de,hl
			pop	bc
			call	strcpy
			add	#2+2+2
			ld	(iy),a
			call	send_command_iy
			ld	hl, #rom_response+3
			ld	c,(hl)
			inc	hl
			ld	b,(hl)
			inc	hl
			; prepare next packet
			ld	0(iy),#6
			ld	1(iy),#C_COPYBUF
			ld	2(iy),#C_COPYBUF>>8
			ld	3(iy),#0			; offset
			ld	4(iy),#0			; offset
			push	bc
			; hl = total size
			pop	hl
			; de = dest addr
			pop	de
			
http_recv_loop:
			ld	a,#0
			cp	h
			jr	nz,cont_http_recv
			cp	l
			jr	nz,cont_http_recv
			; nothing left, exit
			scf
			sbc	a,a
			ret

cont_http_recv:
			push	hl
			push	hl
			ld	bc,#-0x200
			add	hl,bc			; and substract chunksize
			jp	c, recv_full_chunk
			pop 	hl
			ld	5(iy),l			; chunk size low
			ld	6(iy),h			; chunk size high
			jr	cont_http_recv2
	
recv_full_chunk:
			pop	hl
			ld	5(iy),#0x0			; chunk size low
			ld	6(iy),#0x2			; chunk size high
cont_http_recv2:
			call	send_command_iy
			ld	hl,#rom_response+3
									; de contains dest
			ld	c,5(iy)				; chunk size
			ld	b,6(iy)
			push	bc
			ldir					; de will increase
			pop	bc
			pop	hl				; total size 
			or	a				; clear carry
			sbc	hl,bc			; and substract chunksize
			push	hl
			ld	l,3(iy)			; get copy from offset
			ld	h,4(iy)
			add	hl,bc			; increase it.
			ld	3(iy),l
			ld	4(iy),h
			pop	hl
			jr	http_recv_loop

; ------------------------- ERA - erase file replacement
erase_file:
			push	hl
			push	bc
			push	af
			
			; is it for amsdos?
			ld	b,#12
			ld	a,(0xBC78)
			cp	#0xA4
			jp	nz,pass_to_amsdos
			
			pop	af
			pop	bc
			pop	hl	
			
			cp	#0
			jp	z,bad_args
			
			ld	iy,(#rom_workspace)
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			
			push	iy
			ld	1(iy),#C_ERASEFILE
			ld	2(iy),#C_ERASEFILE>>8
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	#2
			ld	(iy),a
			call	send_command_iy
			ld	hl,#rom_response+3
			ld	a,(hl)
			cp	#0
			jr	z,erase_ok
			; show error message
			ld	hl,#rom_response+4
			call	disp_msg
erase_ok:	scf
			sbc	a,a
			ret

; ------------------------- REN - rename file replacement
rename_file:
			push	hl
			push	bc
			push	af
			
			; is it for amsdos?
			ld	b,#13
			ld	a,(0xBC78)
			cp	#0xA4
			jp	nz,pass_to_amsdos
			
			pop	af
			pop	bc
			pop	hl	
			cp	#2			; 2 arguments?
			jr	nz, bad_args
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_RENAME
			ld	2(iy),#C_RENAME>>8
			
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			push	iy
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			
			ex	de,hl
			ld	c,a
			ld	b,#0
			push	bc				; save size
			add	hl,bc			; add len to dest
			push	hl				; save dest
			
			; get 2nd string
			ld	l,2(ix)
			ld	h,3(ix)
			ld	b,(hl)			; string len
			inc	hl
			ld	e,(hl)			; string ptr lo
			inc	hl
			ld	d,(hl)			; string ptr hi
			ex	de,hl
			pop	de
			call	strcpy
			pop	bc				; restore size
			add	c				; add the two string lens together
			add	#2				; add 2 for command hi/lo
			ld	(iy),a
			call	send_command_iy
			ld	hl,#rom_response+3
			ld	a,(hl)
			cp	#0
			jr	z,ren_ok
			; show error message
			ld	hl,#rom_response+4
			call	disp_msg
ren_ok:		scf
			sbc	a,a
			ret
bad_args:
			ld	hl,#miss_arg
			call	disp_msg
			scf
			sbc	a,a
			ret
; ------------------------- copy file 
copy_file:
			cp	#2			; 2 arguments?
			jr	nz, bad_args
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_COPYFILE
			ld	2(iy),#C_COPYFILE>>8
			
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			push	iy
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			
			ex	de,hl
			ld	c,a
			ld	b,#0
			push	bc			; save size
			add	hl,bc	; add len to dest
			push	hl			; save dest
			
			; get 2nd string
			ld	l,2(ix)
			ld	h,3(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			pop	de
			call	strcpy
			pop	bc			; restore size
			add	c			; add the two string lens together
			add	#2			; add 2 for command hi/lo
			ld	(iy),a
			call	send_command_iy
			ld	hl,#rom_response+3
			ld	a,(hl)
			inc	hl
			cp	#0
			call	nz, disp_msg
			scf
			sbc	a,a
			ret

; ------------------------- MKDIR - make directory
makedir:
			cp	#0
			jp	z,bad_args
			
			ld	iy,(#rom_workspace)
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			
			push	iy
			ld	1(iy),#C_MAKEDIR
			ld	2(iy),#C_MAKEDIR>>8
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	#2
			ld	(iy),a
			call	send_command_iy
			ld	hl,#rom_response+3
			ld	a,(hl)
			cp	#0
			jr	z,makedir_ok
			; show error message
			ld	hl,#rom_response+4
			call	disp_msg
makedir_ok:	
			scf
			sbc	a,a
			ret
			
; ------------------------- CD - Change directory on SD card
change_dir:
			ld	iy,(#rom_workspace)
			cp	#0
			jr	nz,cd_has_args
			call	txt_get_window			; TXT GET WINDOW ( D = max column )
			ld	(iy),#0		; offset 0 = init
			inc	d
			ld	1(iy),d		; offset 1 = max column
			ld	2(iy),#0		; offset 2 = filename len
							; offset 3 = filename	
			call	get_path
			ld	a,2(iy)
			add	#2
			ld	(iy),a		; size
			ld	1(iy),#C_CD
			ld	2(iy),#C_CD>>8
			jr	send_cd_cmd
			
cd_has_args:			
			; get string
			ld	l,(ix)
			ld	h,1(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			
			push	iy
			ld	1(iy),#0x8
			ld	2(iy),#0x43
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	#2
			ld	(iy),a
send_cd_cmd:
			call	send_command_iy
			ld	hl,#rom_response+3
			ld	a,(hl)
			cp	#0xFF
			ret	nz
			ld	hl,#text_unkdir
			call	disp_msg
			scf
			sbc	a,a
			ret

send_command:
			ld	bc,#DATAPORT				; FE data out port
			ld	d,(hl)						; size
			inc	d
sendloop:		inc	b
			outi
			dec	d
			jr	nz, sendloop
			
			; tell M4 that command has been send
		
			ld	bc,#ACKPORT
			out (c),c
			xor	a
			ret
			
send_command_iy:
			push	iy
			pop	hl
			ld	bc,#DATAPORT	;0xFE00			; FE data out port
			ld	a,(hl)						; size
			inc	a
sendloop_iy:
			inc	b
			outi
			dec	a
			jr	nz, sendloop_iy
			
			; tell M4 that command has been send
		
			ld	bc,#ACKPORT
			out (c),c
			ret

			; DE = COMMAND			
			; A = size 
			; HL = DATA
			; C = fd
send_command2:
			push	af
			push	hl
			push	de
			push	bc
			add	#3
			ld	bc,#DATAPORT					; data out port
			out	(c),a						; size
			out	(c),e						; command lo
			out	(c),d						; command	hi
			pop	de
			push	de
			out	(c),e						; fd
			sub	#3
			; send actual data
			
sendloop2:
			ld	d,(hl)
			out	(c),d
			inc	hl
			dec	a
			jr	nz, sendloop2
			
			; tell M4 that command has been send
			ld	bc,#ACKPORT
			out (c),c
			pop	bc
			pop	de
			pop	hl
			pop	af
			ret




m4off:		push	iy
			push	hl
			ld	iy,(#rom_workspace)
			ld	(iy), #0x2
			ld	1(iy), #C_M4OFF
			ld	2(iy), #C_M4OFF>>8
			call	send_command_iy	; will never return, m4 will force a reset with the M4 rom disabled
			pop	hl
			pop	iy
			scf
			sbc	a,a
			ret			
;cpm:
;			call hi_kl_curr_selection
;			ld	c,a
;			ld	hl,#cpm_boot
;			jp	mc_start_program
;cpm_boot:
;			ld	sp, #0xC000
;			ld	c, #0x41
;			ld	de, #0
;			ld	hl, #0x100
;			call	read_sector
;			ld	sp, #0xAD33
;			ld	bc, bios jump block ?
;			jp	(hl)
			
			
; -------------- BIOS disc I/O

; ------------------------- bios read sector replacement (cmd 0x84)
; -- parameters
; -- HL = dest address of data 
; -- E  = drive number
; -- D  = track number
; -- C  = sector number
read_sector:
			push	hl
			push	bc
			push	af
			
			; is it for amsdos?
			ld	b,#17
			ld	a,(0xBC78)
			cp	#0xA4
			jp	nz,pass_to_amsdos
			
			pop	af
			pop	bc
			pop	hl	
			
			push	iy
			push	hl
			ld	iy,(#rom_workspace)
			ld	(iy), #0x5
			ld	1(iy), #C_READSECTOR
			ld	2(iy), #C_READSECTOR>>8
			ld	3(iy), d			; track
			ld	4(iy), c			; sector
			ld	5(iy), e			; drive
			push	hl
			call	send_command_iy
			pop	de
			ld	hl,#rom_response+4	; src buffer
			ld	bc,#512
			ldir
			pop	iy
			pop	hl
			scf
			sbc	a,a
			ret			
; ------------------------- bios write sector replacement (cmd 0x85)
; -- parameters
; -- HL = src address of data 
; -- E  = drive number
; -- D  = track number
; -- C  = sector number
write_sector:
			push	hl
			push	bc
			push	af
			
			; is it for amsdos?
			ld	b,#18
			ld	a,(0xBC78)
			cp	#0xA4
			jp	nz,pass_to_amsdos
			
			pop	af
			pop	bc
			pop	hl	
			
			push	hl
			push	bc
			ld	bc,#DATAPORT
			out	(c),c
			ld	a,#C_WRITESECTOR
			out	(c),a						
			ld	a, #C_WRITESECTOR>>8
			out	(c),a						
			out	(c),d			; track
			pop	de
			out	(c),e			; sector
			out	(c),d			; drive
			ld	de,#512
sec_data_loop:
			ld	a,(hl)			; rst &20 or add >= &c000 check later....
			out	(c),a
			inc	hl
			dec	de
			xor	a
			cp	d
			jr	nz,sec_data_loop
			cp	e
			jr	nz,sec_data_loop
			ld	bc,#ACKPORT
			out (c),c
			pop	hl
			scf
			sbc	a,a
			ret						
			
disp_msg:		ld 	a, (hl)
			or	a
			ret	z
			call txt_output
			inc	hl
			jr	disp_msg
			
			; cursor copy function for basic 1.0, may remove later if space needed now you can replace lowerrom and use basic 1.1
			
get_path:		call	txt_get_cursor	; get cursor pos
			push	hl	; real cursor pos
			pop	bc
			ld	a,#25
			cp	c
			jr	nc,not_last_line
			ld	c,#25	; no scrolling, please
not_last_line:
			call	txt_place_cursor
inputloop:	
			push	hl
			call	mc_wait_flyback
			call	km_read_char
			pop	hl
			push	hl
			cp	#0xF4
			call	z,cursor_up
			cp	#0xF5
			call	z,cursor_down
			cp	#0xF6
			call	z,cursor_left
			cp	#0xF7
			call	z,cursor_right
			cp	#0xE0
			jr	nz, not_copykey
			call	copy_char
			pop	de
			ld	d,h
			ld	e,l
			jr	inputloop

not_copykey:	
			cp	#0x7F
			jr	nz,not_delkey
			call	del_char
			pop	de
			ld	d,h
			ld	e,l
			jr	inputloop
not_delkey:	
			cp	#13
			jr	z,enterkey
			cp	#32
			jr	c,not_valid_char
			cp	#0x7e
			jr	nc,not_valid_char
			call	key_press
not_valid_char:
			pop	de
			ld	a,d
			cp	h
			call	nz, update_cursor	; txt set cursor
			ld	a,e
			cp	l
			call	nz, update_cursor
			jr	inputloop

enterkey:	
			; add zero terminator
			ld	e,2(iy)	; filename len (pos)
			ld	d,#0
			push	iy		
			add	iy,de
			ld	3(iy),#0	; terminator
			pop	iy
			inc	e
			ld	2(iy),e	; filename len++
			; remove copy cursor
			pop	de
			push	hl
			call	txt_remove_cursor
			pop	hl
			ld	a,h
			cp	b
			jr	nz,not_same_pos
			ld	a,l
			cp	c
			jr	z,same_pos
not_same_pos:	ld	h,b
			ld	l,c
			call	txt_set_cursor
			call	txt_remove_cursor	;remove real cursor

same_pos:
			ld	a,#10
			call	txt_output
			ld	a,#13
			call	txt_output
			ret

cursor_up:	push	af
			ld	a,l
			cp	#1
			jr	z,top_line
			dec	l
top_line:		pop	af
			ret

cursor_down:	push	af
			ld	a,l
			cp	#25
			jr	nc,bottom_line
			inc	l
bottom_line:	pop	af
			ret
cursor_left:	push	af
			ld	a,h
			cp	#1
			jr	z,cur1
			dec	h
cur1:		pop	af
			ret
cursor_right:	push	af
			ld	a,1(iy)	; max column
			cp	h	
			jr	z,max_col
			inc	h
max_col:		pop	af
			ret
update_cursor:
			push	hl
			ld	a,(iy)		; do not remove real cursor if same pos as copy cursor (first run)
			cp	#1
			call	z, txt_remove_cursor
			ld	(iy),#1
	
			call	txt_set_cursor	; set cursor
			call	txt_place_cursor
			pop	hl
			ret

copy_char:	push	af
			push	hl	; copy cursor position
	
			call	txt_remove_cursor	; remove copy cursor
			call	txt_rd_char	; read char current cursor pos
			push	af
	
			ld	a,2(iy)	; filename len (pos)
			cp	#0xFC
			jr	nc, fndir_max
			
			ld	e,a
			inc	a
			ld	2(iy),a	; filename len++
			ld	d,#0
			pop	af		
			push	iy		
			add	iy,de
			ld	3(iy),a
			pop	iy
			push	af
fndir_max:	
			; set real cursor pos
			ld	h,b
			ld	l,c
			call	txt_set_cursor
			call	txt_remove_cursor	; remove cursor
			pop	af
			push	bc
			call	txt_wr_char	; print 'copy' char
			pop	bc
			; set new real cursor position
			inc	b
			ld	h,b
			ld	l,c
			call	txt_set_cursor	
			call	txt_place_cursor	; place cursor
	
			pop	hl
			; set back to copy cursor pos
			inc	h	; new pos
			push	hl
			call	txt_set_cursor	; 
			call	txt_place_cursor	; place cursor
			pop	hl
			
			pop	af
			ret
key_press:	
			push	hl
			push	af
			; set real cursor pos
			ld	h,b
			ld	l,c
			call	txt_set_cursor
			call	txt_remove_cursor	; remove cursor
			
	
			
			ld	a,2(iy)	; filename len (pos)
			cp	#0xFC
			jr	nc, fndir_max1
			ld	e,a
			inc	a
			ld	2(iy),a	; filename len++
			ld	d,#0
			pop	af		; character	
			push	iy		
			add	iy,de
			ld	3(iy),a
			pop	iy
			push	af

fndir_max1:	pop	af

			call	txt_output	; print char
			; set new real cursor position
			inc	b
			ld	h,b
			ld	l,c
			call	txt_set_cursor	
			call	txt_place_cursor	; place cursor
	
			pop	hl
			; set back to copy cursor pos
			push	hl
			call	txt_set_cursor
			pop	hl
			ret


del_char:		push	af
			push	hl
			; set real cursor pos
			ld	h,b
			ld	l,c
			call	txt_set_cursor
			call	txt_remove_cursor	; remove cursor
			ld	a,b
			cp	#1
			jr	z,at_start_pos
			dec	b
			ld	h,b
			ld	l,c
			call	txt_set_cursor	; update real cursor pos
			
			ld	a,2(iy)	; filename len (pos)
			cp	#0
			jr	z, at_start_pos
			dec	a
			ld	2(iy),a
			
at_start_pos:
			ld	a,#32
			call	txt_output	; overwrite the char with a space
			; set cursor back
			ld	h,b
			ld	l,c
			call	txt_set_cursor	; update real cursor pos
			call	txt_place_cursor
			pop	hl
			; set back to copy cursor pos
			push	hl
			call	txt_set_cursor	
			pop	hl
	
			pop	af
			ret

mul16:		ld	hl,#0
			ld	a,#16
mul16Loop:	add	hl,hl
			rl	e
			rl	d
			jp	nc,nomul16
			add	hl,bc
			jp	nc,nomul16
			inc	de
nomul16:
			dec	a
			jp	nz,mul16Loop
			ret

rom_upload:
			cp	#2			; 2 arguments?
			jp	nz, bad_args
			ld	iy,(#rom_workspace)
				
			; get filename
			
			ld	l,2(ix)
			ld	h,3(ix)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			
			; open rom file
			
			ld	a,#FA_READ
			call	fopen	; hl = filename, b = len, a = mode
			ld	-1(iy),a
			cp	#0xFF
			jp	z, romupload_fail
			
			; check if file has amsdos header
			
			ld	hl,#128			; size of header
			call	fread
			ld	b,#66
			ld	hl,#0
			ld	de,#rom_response+4
rom_checksum_loop:
			push	bc
			ld	a,(de)
			ld	c,a
			ld	b,#0
			inc	de
			add	hl,bc
			pop	bc
			djnz	rom_checksum_loop
			; compare with header checksum
			ld	a,(#rom_response+4+67)
			cp	l
			jr	nz,rom_checksum_mismatch
			ld	a,(#rom_response+4+68)
			cp	h
			jr	z,rom_checksum_ok
rom_checksum_mismatch:
			; no amsdos header, seek back to offset 0
			ld	a, -1(iy)
			ld	hl,#0
			call fseek		
			; otherwise skip the header (128 bytes)
			xor	a
			jr	rom_store_start_offset
			
rom_checksum_ok:
			ld	a,#128
rom_store_start_offset:			
			ld	-3(iy),a		; store skip offset
			; open m4/romslots.bin... cannot use regular fopen, as it does not allow filename in rom (think its screen ram)
			
			ld	hl, #romslots_fn
			ld	c,#0x80 | FA_READ|FA_WRITE
			ld	a,#17
			
			ld	de, #C_OPEN
			call	send_command2	; will do cmd(2, DE), size(1, A), mode (1, C) followed by data in HL with A size.
			ld	hl,#rom_response+3
			ld	b,(hl)		; fd
			inc	hl
			ld	a,(hl)		; res
			
			cp	#0
			jp	nz, romupload_fail_close2
			
			ld	-2(iy),b
			; calculate seek offset

			ld	bc,#0x4000	; rom size
			ld	e,(ix)		; rom slot
			ld	d,#0
			call	mul16		; performs DEHL = BC*DE
			
			; perform fseek (32 bit) offset into m4/romslots.bin
			
			ld	(iy),#7			; size.. cmd(2) + fd (1) + offset (4)
			ld	1(iy),#C_SEEK		; cmd seek
			ld	2(iy),#C_SEEK>>8	; cmd seek
			ld	a,-2(iy)			; file handle
			ld	3(iy),a			; 
			ld	4(iy),l			; offset
			ld	5(iy),h			; offset
			ld	6(iy),e			; offset
			ld	7(iy),d			; offset
			
			call	send_command_iy
			
			ld	a,(#rom_response+3)	; check if seek was OK?
			or	a
			jp	nz, romupload_fail_close1

			
			; get rom file size
			ld	(iy),#3			; size, cmd(2) + fd (1)
			ld	1(iy),#C_FSIZE		; cmd size
			ld	2(iy),#C_FSIZE>>8	; cmd size
			ld	a,-1(iy)			; file handle
			ld	3(iy),a
			call	send_command_iy
			
			ld	a,(#rom_response+3)
			ld	l,a
			ld	a,(#rom_response+4)
			ld	h,a
			ld	c,-3(iy)			; offset into file (past header or not)
			ld	b,#0
			or	a
			sbc	hl,bc
			
			; should really check if rom size > 0x4000....
			
			; write loop
rom_write_loop:
			
			
			; check if remaining size less than 0xFC
				
			ld	a,h
			cp	a,#0
			jr	nz,romw_full_chunk
			ld	a,l
			cp	#0xFC
			jr	c,romw_cont
romw_full_chunk:
			ld	a,#0xFC
romw_cont:
			
			ld	e,a
			
			ld	b,#0
			ld	c,a
			or	a
			sbc	hl,bc	; substract chunk size from remaining size
			push	hl
			
			; read chunk size from input file (rom file)
			
			
			ld	1(iy),#C_READ
			ld	2(iy),#C_READ>>8
			ld	a, -1(iy)
			ld	3(iy),a			; fd
			ld	4(iy),e			; chunk size
			ld	5(iy),#0x0		; chunk size
			ld	(iy),#5			; packet size, cmd (2), fd (1), size (2)
			call	send_command_iy
			
			ld	a,(#rom_response+3)
			or	a
			jr	nz,romupload_fail_close1
			
			; write chunk size to outputfile (romslots.bin)
			ld	a,e
			ld	de, #C_WRITE
			ld	hl, #rom_response+4	; data read earlier
			ld	c, -2(iy)
			call	send_command2	; will do cmd(2, DE), size(1, A), fd (1, C) followed by data in HL with A size.
			pop	hl
			
			; check if there is more data left
			ld	a,h
			or	a
			jr	nz, rom_write_loop
			ld	a,l
			or	a
			jr	nz, rom_write_loop
			
			; rom written to m4/romslots.bin
			
			ld	a,-1(iy)			; file handle "rom file"
			call	fclose
			ld	a,-2(iy)			; file handle "m4/romslots.bin"
			call	fclose
			
			; now update m4/romconfig.bin
			
			ld	hl, #romconfig_fn
			ld	c,#0x80 | FA_READ|FA_WRITE
			ld	a,#18
			ld	de, #C_OPEN
			call	send_command2	; will do cmd(2, DE), size(1, A), mode (1, C) followed by data in HL with A size.
			ld	hl,#rom_response+3
			ld	b,(hl)		; fd
			inc	hl
			ld	a,(hl)		; res
			
			cp	#0xFF
			jp	z, romupload_fail
		
			ld	-1(iy),b
		
			ld	bc,#33		; rom name (32) + updateflag (1)
			ld	e,(ix)		; rom slot
			ld	d,#0
			call	mul16		; performs DEHL = BC*DE
			ld	de,#32		; skip header (8*4)
			add	hl,de		; size is less than 16 bit, no worries..
			
			ld	a, -1(iy)
			call fseek		; we are now pointing at the updateflag for current rom slot
				
			; set update flag to 2 and name to "rom".
			
			ld	de, #C_WRITE
			ld	hl, #rom_update_slot	; data read earlier
			ld	c, -1(iy)
			ld	a, #5
			call	send_command2	; will do cmd(2, DE), size(1, A), fd (1, C) followed by data in HL with A size.
			
			ld	a, -1(iy)
			call	fclose
			
			scf
			sbc	a,a
			ret			
			
		
romupload_fail_close0:
			pop	hl			
romupload_fail_close1:
			ld	a,-2(iy)			; file handle "m4/romslots.bin"
			call	fclose
romupload_fail_close2:			
			ld	a,-1(iy)			; file handle "rom file"
			call	fclose
romupload_fail:
			; disp some error message
			ld	hl,#fail_msg
			call	disp_msg
			or	a
			ret	
rom_update_slot:
			.db  2
			.ascii "ROM"
			.db	0

rom_set:
			cp	#2			; 2 arguments?
			jp	nz, bad_args
			ld	iy,(#rom_workspace)
				
			; get rom status
			
			; get rom slot
			
			ld	hl, #romconfig_fn
			ld	c,#0x80 | FA_READ|FA_WRITE
			ld	a,#18
			ld	de, #C_OPEN
			call	send_command2	; will do cmd(2, DE), size(1, A), mode (1, C) followed by data in HL with A size.
			ld	hl,#rom_response+3
			ld	b,(hl)		; fd
			inc	hl
			ld	a,(hl)		; res
			
			cp	#0xFF
			jp	z, romset_fail
		
			ld	-1(iy),b
		
			ld	bc,#33		; rom name (32) + updateflag (1)
			ld	e,2(ix)		; rom slot
			ld	d,#0
			call	mul16		; performs DEHL = BC*DE
			ld	de,#32		; skip header (8*4)
			add	hl,de		; size is less than 16 bit, no worries..
			
			ld	a, -1(iy)
			call fseek		; we are now pointing at the updateflag for current rom slot
				
			; set update flag to 0 or 1
			
			ld	de, #C_WRITE
			ld	hl, #data_0	
			ld	c, 0(ix)		; status
			ld	b, #0
			add	hl,bc
			ld	c, -1(iy)
			ld	a, #1
			call	send_command2	; will do cmd(2, DE), size(1, A), fd (1, C) followed by data in HL with A size.
			
			ld	a, -1(iy)
			call	fclose
			
			scf
			sbc	a,a
			ret			
romset_fail:
			or	a
			ret
rom_update:
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_ROMSUPDATE
			ld	2(iy),#C_ROMSUPDATE>>8
			ld	(iy),#2			; packet size, cmd (2)
			call	send_command_iy
			scf
			sbc	a,a
			ret	
wifi_power:	ld	iy,(#rom_workspace)
			ld	a, 0(ix)		; status
			ld	1(iy),#C_WIFIPOW
			ld	2(iy),#C_WIFIPOW>>8
			ld	3(iy),a
			ld	(iy),#3			; packet size, cmd (2), 0=off, 1 = on
			call	send_command_iy
			ret

catalog_buffer	.equ	0x8000
inbuffer		.equ	0x8800
outbuffer		.equ	0x9000
fileheadin	.equ	0x9800
fileheadout	.equ	0x9802
filesize		.equ	0x9804
filename		.equ	0x9906
filename2		.equ	0x9986
header		.equ	0x9A06
drive_vectors	.equ	0x9A86	; to 0x9AB6
file_copy:		
			cp	#2			; 2 arguments?	
			jr	z,got_args
			ld	hl,#txt_copy_err
			jp	disp_msg
got_args:			
			; get 1st string (dest filename)
			ld	l,(ix)
			ld	h,1(ix)
			ld	c,(hl)	; string len
			ld	b,#0
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			ld	de,#filename2
			ldir
			xor	a
			ld	(de),a
			; get 2nd string (src filename)
		
			ld	l,2(ix)
			ld	h,3(ix)
			ld	c,(hl)
			ld	b,#0
			inc	hl
			ld	e,(hl)
			inc	hl
			ld	d,(hl)
			ex	de,hl
			ld	de,#filename
			ldir
			xor	a
			ld	(de),a
			push	iy
			
			ld	hl,(#amsdos_inheader)
			ld	de,#-0x51
			add	hl,de
			ld	a,(hl)	; amsdos drive
			push	hl
			push	af
			ld	hl,#0xBC77
			ld	de,#drive_vectors
			ld	bc,#48
			ldir
			
			call	do_copy
			ld	hl,#drive_vectors
			ld	de,#0xBC77
			ld	bc,#48
			ldir
			pop	af
			pop	hl
			ld	(hl),a
			pop	iy
			xor	a
			ret
do_copy:
			ld	hl,#filename2
			call	get_drive
			sla	a
			sla 	a
			ld	c,a
			
			; check if there is a destination filename
			push	hl
			call	strlen
			cp	#2
			jr	nz, got_dest_fn
			inc	hl
			ld	a,(hl)
			cp	#':'		;  is it just a drive letter?
			jr	nz, got_dest_fn
			inc	hl
			ex	de,hl	
			
			ld	hl,#filename
			inc	hl
			ld	a,(hl)
			dec	hl
			cp	#':'
			jr	nz, copy_fn
			inc	hl
			inc	hl
copy_fn:
			call	strlen
			push	bc
			inc	a
			ld	c,a
			ld	b,#0
			ldir				; filename1 past ?: to filename2 past ?:
			pop	bc			; c contains 'dest drive'
got_dest_fn:	pop	de			; filename2
			ld	hl,#filename
			call	get_drive
			or	c
			call	set_drives
			; check if wildcard in src file name
			ld	hl,#filename
			inc	hl
			ld	a,(hl)
			dec	hl
			cp	#':'
			jr	nz,no_drv_letter
			inc	hl
			inc	hl
no_drv_letter:	
			ld	a,(hl)
			cp	#'*'
			jp	nz,no_wildcard
			push	hl			; filename1
			;ld	a,#1
			;call	bios_set_message
			ld	de,#catalog_buffer
			push	de			; cas buffer
			call	cas_catalog
			pop	hl			; cas buffer
			pop	de			; filename1
			;jp	c, copy_error
			
copy_files:	push	hl		; catalog buffer
			ld	a,(hl)
			cp	#0xFF
			jr	z, valid_file
			pop	hl
			ret	
valid_file:			
			inc	hl
			ld	bc,#8
			push	de		; filename1
			ldir
			ld	a,#0x2e
			ld	(de),a
			inc	de
			ld	bc,#3
			ldir
			xor	a
			ld	(de),a
			pop	de		; filename 1
			ld	hl,#filename2
			inc	hl
			ld	a,(hl)
			dec	hl
			cp	#':'
			jr	nz,no_drvl
			inc	hl
			inc	hl
no_drvl:		ex	de,hl
			ld	bc,#14
			push	hl
			ldir			; copy filename1+?: to filename2+?:
			ld	hl,#filename
			ld	de,#filename2
			call	copy_file2
			pop	de		; filename1+?:
			pop	hl		; ptr cas_catalog buffer
			ld	bc,#14
			add	hl,bc
			jp	copy_files
no_wildcard:
			ld	hl,#filename
			ld	de,#filename2
			call	copy_file2
			ret

;	input 
;	HL = filename
; 	output
;	A = drive 0/1/2
;    HL = filename (after T if stated)


get_drive:	push	bc
			ld	c,#0			; drive 'sd'
			inc	hl
			ld	a,(hl)
			dec	hl
			cp	#':'
			jr	nz, get_drive_exit
			ld	a,(hl)
			and	#0xDF 
			cp	#'B'
			jr	nz, not_b
			ld	c,#2			; drive b
			jr	get_drive_exit
not_b:		cp	#'A'
			jr	nz, not_a
			ld	c,#1			; drive a
			jr	get_drive_exit
not_a:		cp	#'C'
			jr	nz, not_c		; drive C (SD)
			ld	c,#0
			jr 	get_drive_exit
not_c:		cp	#'T'			; drive T (TAPE)
			jr	nz, get_drive_exit
			ld	c,#3
get_drive_exit:	
		
			ld	a,c
			pop	bc
			ret
			; input A :
			; 0000 = SD->SD
			; 0001 A->SD
			; 0010 B->SD
			; 0011 TAPE->SD 
			; 0100  SD->A
			; 0101  A->A
			; 0110  B->A
			; 0111 TAPE->A  (not supported)
			; 1000  SD->B
			; 1001  A->B
			; 1010  B->B
			; 1011  TAPE->B  (not supported)
			; 1100  SD->TAPE  
			; 1101  A->TAPE  (not supported)
			; 1110  B->TAPE  (not supported)
			; 1111  TAPE->TAPE  (not supported)
set_drives:	cp	#0
			jp	z, patch_fio
			cp	#1
			jr	nz, not_ASD
			call	set_amsdos_functions
			call	set_drvA
			jp	patch_fio_out
not_ASD:		
			cp	#2
			jr	nz,not_BSD
			call	set_amsdos_functions
			call	set_drvB
			jp	patch_fio_out

not_BSD:		cp	#3
			jr	nz,not_TSD
			call	tape
			jp	patch_fio_out
not_TSD:		cp	#4
			jr	nz, not_SDA
			call	set_amsdos_functions
			call	set_drvA
			jp	patch_fio_in
not_SDA:		cp	#5
			jr	nz, not_AA
			call	set_amsdos_functions
			jp	drvA
not_AA:		cp	#6
			jp	nz, not_BA
			call	set_amsdos_functions
			jp	drvB
not_BA:		cp	#7
			jr	nz, not_TA
			call	set_amsdos_functions
			call	set_drvA
			jp	tape		; _in
not_TA:		cp	#8
			jr	nz, notSDB
			call	set_amsdos_functions
			call	set_drvB
			jp	patch_fio_in
notSDB:		cp	#9
			jr	nz, not_AB
			call	set_amsdos_functions
			jp	drvA
not_AB:		cp	#10
			jr	nz, not_BB
			call	set_amsdos_functions
			jp	drvB
not_BB:		cp	#11
			jr	nz, not_TB
			call	set_amsdos_functions
			call	set_drvB
			jp	tape		;_in
not_TB:		cp	#12			
			jr	nz, not_SDT
			call	patch_fio_in
			jp	tape		; _out
not_SDT:		cp	#13
			jr	nz, notAT
			call	set_amsdos_functions
			call	set_drvA
			jp	tape		; _out
notAT:		cp	#14
			jr	nz,notBT
			call	set_amsdos_functions
			call	set_drvB
			jp	tape		;_out
notBT:		cp	#15
			jp	z,tape
			ret
			
			; hl = src filename
			; de = dest filename
copy_file2:	push	hl
			ld	hl,#txt_copying
			call	disp_msg
			ld	hl,#filename
			call	disp_msg
			ld	hl,#txt_to
			call	disp_msg
			ld	hl,#filename2
			call	disp_msg
			call	crlf
			pop	hl
			push	de
			call	strlen
			ld	b,a
			ld	de,#inbuffer
			
			call cas_in_open
			jr	c,cas_in_ok
			pop	de
			jp	copy_error
cas_in_ok:			
			push	bc
			
			push	hl
			ld	de,#header		
			ld	bc,#128
			ldir				
			pop	hl
			ld	de,#-5
			add	hl,de
			ld	(#fileheadin),hl
			
			pop	hl
			ld	(#filesize),hl
			pop	hl			; dest filename
			push	af			; filetype
			call	strlen
			ld	b,a
			ld	de,#outbuffer
			call	cas_out_open
			jr	c,openout_ok
			pop	af
			jp	copy_error		
openout_ok:
			ld	de,#-5
			add	hl,de
			ld (#fileheadout),hl
			
			pop	af
		
			cp	#0x16
			jr	nz, has_header
headerless:			
			call	cas_in_char
			jp	c, copy_more
			cp	#0xf
			jp	z,copy_done
copy_more:	call	cas_out_char
			jr	headerless
has_header:			
			call	cas_in_char		; fill 2k buffer
			
			ld	hl,#header
			ld	a,(hl)
			call cas_out_char
			ld	de,#outbuffer
			ld	bc,#128
			ldir
			ld	hl,#inbuffer
			ld	bc,#2048-128
			ldir
		
			; check if remains of file is less than 2k - 128
			ld	hl,(filesize)
			ld	de,#128

			add	hl,de
			ld	bc,#0xF800			; -#0x800
			push	hl
			add	hl,bc				; and substract chunksize
			pop	de
			jr	c, cfull_chunk
			ld	c,e
			ld	b,d
			jr	cont1
			
cfull_chunk:	ld	bc,#0x800
			jr	cont1

cont1:		ld	(filesize),hl
						
			; increase ptr to write out 2k buffer (or filesize) at once
			
			ld	iy,(fileheadout)
			ld	(iy),#1
			
			ld	l,1(iy)		; get buffer
			ld	h,2(iy)
			add	hl,bc
			ld	3(iy),l		; current pos is end of buffer
			ld	4(iy),h
			ld	24(iy),c		; size is 2k too
			ld	25(iy),b
			; write 2k block
			call cas_out_char
			ld	a,#8
			cp	b			; was it 2k
			jp	nz, copy_done
			
			; copy remaining bytes of input buffer to output buffer
copy_loop:		
			ld	hl,#inbuffer+2048-128
			ld	de,#outbuffer
			ld	bc,#128
			ldir
			ld	iy,(#fileheadin)
			
			ld	hl,(#filesize)
			ld	bc,#0xF800			; -#0x800
			push	hl
			add	hl,bc			; and substract chunksize
			pop	de
			jr	c, cfull_chunk1
			ld	c,e
			ld	b,d
			jr	cont2
			
cfull_chunk1:	ld	bc,#0x800

		
			; re-fill input buffer
		
cont2:		ld	(filesize),hl
			
			ld	l,1(iy)
			ld	h,2(iy)
			
			add	hl,bc
			ld	3(iy),l		; adjust current pos to end of buffer
			ld	4(iy),h
			ld	24(iy),#0	; clear buffer remains
			ld	25(iy),#0
			call	cas_in_char		; fill 2k buffer
			jr	c,read_in_ok
			cp	#0x1A
			jr	z,read_in_ok
			;jp	copy_error
read_in_ok:
			push	bc
			ld	hl,#inbuffer
			ld	de,#outbuffer+128
			ld	bc,#2048-128
			ldir
			pop	bc
			
			; write 2k buf
			ld	iy,(fileheadout)
			ld	(iy),#1
			
			ld	l,1(iy)		; get buffer
			ld	h,2(iy)
			add	hl,bc
			ld	3(iy),l		; current pos is end of buffer
			ld	4(iy),h
			ld	24(iy),c		; size is 2k too
			ld	25(iy),b
			
			call cas_out_char
			;jr	nc, copy_error
			ld	a,#8
			cp	b			; was it 2k
			jr	z,copy_loop
			ld	l,3(iy)		; get buffer
			ld	h,4(iy)
			dec	hl			; get rid of extra char
			ld	3(iy),l		
			ld	4(iy),h		 
			
			
copy_done:			
			call cas_in_close
			call cas_out_close
			ret
copy_error:	ld	hl,#txt_copy_err
			call	disp_msg
			jp	copy_done

disp_hex:		ld	b,a
			srl	a
			srl	a
			srl	a
			srl	a
			add	a,#0x90
			daa
			adc	a,#0x40
			daa
			call	txt_output
			ld	a,b
			and	#0x0f
			add	a,#0x90
			daa
			adc	a,#0x40
			daa
			jp	txt_output

;---------------------------------------
; Helper functions


; -- added Prodatron
			
hsend:        		;A=source bank, HL=source address, D-1,E=length, IYL=network daemon bank, IX=return address, BC=#7F00
    			out	(c),a			;switch to application bank
    			ld	b,#0xfe
hsend_loop:
			inc	b
			outi				;copy data from application memory to m4 dataport
			dec	e
			jr	nz,hsend_loop
			dec	d
			jr	nz,hsend_loop
			ld	b,#0x7f
			.db #0xfd
			ld	a,l
			out	(c),a			;switch back to network daemon bank
			jp	(ix)			;return to network daemon

hreceive:     	;A=destination bank, DE=destination address, IYH,C=length, HL=M4 buffer, IYL=network daemon bank, IX=return address, B=#7F 
			out	(c),a			;switch to application bank
			.db	#0xfd
			ld	b,h
			ldir				;copy data from m4 buffer to application memory
			ld	b,#0x7f
			.db	#0xfd
			ld	a,l
			out	(c),a			;switch back to network daemon bank
			jp	(ix)		;return to network daemon 			


; --- added SOS


UDIR:		ld a,(#UDIR_RAM_Address)
			cp #0
			ret z
			; reset dir count
			ld	iy,(#rom_workspace)
			ld	1(iy),#C_DIRSETARGS
			ld	2(iy),#C_DIRSETARGS>>8
			ld	(iy), #3
			ld	3(iy),#0
			call	send_command_iy
NextGetEntry:
			ld	iy,(#rom_workspace)
			ld	(iy),#2
			ld	1(iy),#C_READDIR
			ld	2(iy),#C_READDIR>>8
			call	send_command_iy
		
			ld	hl,#rom_response
			ld	a,(hl)
			cp	#2
			jp	z,finished

	
			inc hl
			inc hl
			inc hl
			ld a,(hl)
			cp #0x3E ;">"
			jr nz,FileFound
			inc hl
			ld bc,#16
			jr CopyFileDir
;--------------------------------------
FileFound:
			ld bc,#12
CopyFileDir:	
	; RAM:
	; 464     	   664/6128
	; aca4-ada5    ac8a-ad8b        *** ASCII-Puffer *** (INPUT, LIST)
			ld de,#0xAC8B
			ldir
			push af
			ld a,#0
			ld (de),a
			pop af
			cp #0x3E ;">"
			jp z,directoryfound
			push hl
			pop ix
			ld hl,#0	
			ld a,1(ix)
			cp #32 ; " "
			jr z,Space_Det1
			sub #48 ;sub "0"
			ld b,#0
			ld c,a
			ld de,#100
			call mul16 ; This routine performs the operation DEHL=BC*DE
Space_Det1:	
			push hl
			ld a,2(ix)
			cp #32 ; " "
			jr z,Space_Det2
			sub #48 ;sub "0"
			ld b,#0
			ld c,a
			ld de,#10
			call mul16 ; This routine performs the operation DEHL=BC*DE

Space_Det2:	
			pop de
			add hl,de
			
			ld a,3(ix)
			cp #32 ; " "
			jr z,Space_Det3
			sub #48 ;sub "0"
			ld b,#0
			ld c,a
			add hl,bc
			ex de,hl
Space_Det3:	
	
; Convert KB-Value to Bytes (10* Shift right) or *1024
		ld bc,#1024
			call mul16 ; performs DEHL = BC*DE
			ex de,hl
			ld ix,#0xAC8A + #0x100 - #4   ; Firmware 1.1
			ld a,h
			ld 3(ix),a
			ld a,l
			ld 2(ix),a
			ld a,d
			ld 1(ix),a
			ld a,e
			ld (ix),a


			ld b,#0
			jr goon
directoryfound:
			ld ix,#0xAC8A + #0x100 - #4   ; Firmware 1.1
			ld 3(ix),#0
			ld 2(ix),#0	
			ld 1(ix),#0
			ld (ix),#0
			ld b,#1
	
goon:
			; * HL = Location of null terminated file/folder name string
			; *  B = File flag (1 = directory, 0 = file)
			; At the same time, if you need it, you can get the size in bytes of the file. This is located in:
			; * FILESIZE_CACHE_LSW          EQU BASIC_INPUT_AREA + $100 - 4
			; * FILESIZE_CACHE_MSW          EQU BASIC_INPUT_AREA + $100 - 2 
			; The only bad thing is BASIC_INPUT_AREA is in $AC8A in firmware 1.1, but it's in $ACA4 in firmware 1.0 (CPC 464 with original rom).
			ld hl,#0xAC8B
			call UDIR_RAM_Address
			jp NextGetEntry
	
finished:
			; ClearMemory
			ld de,#0xAC8B
			push de
			pop hl
			inc de
			ld a,#0
			ld (hl),a
			ld bc,#12
			ldir
	
			scf
			sbc	a,a
			ret

GETPATH:
			; IN: Normal behavour of RSX, OR A=255->DE=Buffferadress for Path
			push af
			cp #0xFF
			jr z,GetPath2
			ld de,#0xAC8B   ; ACMEDOS-Bug, uses &AC8B for BASIC 1.0
GetPath2:	
			push de		
	
			ld	iy,(#rom_workspace)
			ld	0(iy),#2
			ld	1(iy),#C_GETPATH
			ld	2(iy),#C_GETPATH>>8
			call	send_command_iy
			
			ld	hl,#rom_response+#3			
			ld a,(#rom_response)
			sub #3 
	
			
			; RAM:
			; 464     	   664/6128
			; ac80-ac91    ac66-ac77        EVERY/AFTER ,2 GOSUB
			; ac92-aca3    ac78-ac89        EVERY/AFTER ,3 GOSUB
			; aca4-ada5    ac8a-ad8b        *** ASCII-Puffer *** (INPUT, LIST)
			
			pop de
	
			;	ld de,0xAC8B   ; ACMEDOS-Bug, uses &AC8B for BASIC 1.0
			ld b,#0
			ld c,a
	
			; ignore first "/"
			inc hl
			dec bc
			push de
			ld a,c
			cp #0
			jr z,GetPath3
			ldir
GetPath3:
			
			
			ld a,#00
			ld (de),a
			
			pop hl
			pop af
			cp #0xFF
			jr z,finished_GETPATH ; not called from Basic, so don't print path

PrintPath:
			ld a,(hl)
			cp #0
			jr z,finished_GETPATH
			inc hl
			call txt_output
			jr PrintPath
finished_GETPATH:

			scf
			sbc	a,a
			ret
GetPathEnd:

; ----------LONGNAME
LongName:
			; IN: Normal behavour of RSX, OR A=255->DE=Buffferadress for Path
			cp	#0
			jp	z,bad_args
			push af
			push de
			ld	iy,(#rom_workspace)
			; get string
			ld	l,(ix)
			ld	h,1(IX)
			ld	b,(hl)	; string len
			inc	hl
			ld	e,(hl)	; string ptr lo
			inc	hl
			ld	d,(hl)	; string ptr hi
			ex	de,hl
			
			push	iy
			ld	1(iy),#C_FSTAT
			ld	2(iy),#C_FSTAT>>8
			pop	de
			inc	de
			inc	de
			inc	de
			call	strcpy
			add	a,#2
			ld	(iy),a
			call	send_command_iy
			
			ld	hl,#rom_response+3
			ld	a,(hl)
			cp	#0
			jr	z,LongName_ok
			; show error message
			pop de
			pop af
			cp #0xff
			jr z,LongNameExit
			ld	hl,#rom_response+4
			call	disp_msg
LongNameExit:   			
   			scf
			sbc	a,a
			ret
;a4e8
;af95 nein
	
LongName_ok:
			pop de
			pop af
			ld hl,#rom_response+23+3
			cp #0xFF
			jr nz,PrintFileDirLongname
LongName_CopyName:	
			ld a,(hl)
			ld (de),a
			cp #0
			jr z,LongNameExit
			inc hl
			inc de
			jr LongName_CopyName
			
	
PrintFileDirLongname:
			ld a,(hl)
			cp #0
			jr z,LongNameExit
			inc hl
			call txt_output
			jr PrintFileDirLongname

; --- EOF added by SOS
dispdec:		ld	e,#0
			ld	a,(hl)
			ld	l,a
			ld	h,#0
			ld	bc,#-100
			call	Num1
			cp	#'0'
			jr	nz,notlead0
			ld	e,#1
notlead0:		call	nz,txt_output
			ld	c,#-10
			call	Num1
			cp	#'0'
			jr	z, lead0_2
			call	txt_output
lead0_2_cont:	ld	c,b
			call	Num1
			jp	txt_output
			
Num1:		ld	a,#'0'-1
Num2:		inc	a
			add	hl,bc
			jr	c,Num2
			sbc	hl,bc
			ret
lead0_2:
			ld	d,a
			xor	a
			cp	e
			ld	a,d
			call	z,txt_output
			jr	lead0_2_cont
						
			

crlf:		ld	a,#10
			call	txt_output
			ld	a,#13
			jp	txt_output	

			; get amsdos table
			
			; -- hardcoded for AMSDOS v0.5 / v0.7 or PARADOS for now
			
			; b = func num
get_amsdos_ptr:
			ld	a,(amsdos_ver)
			ld	hl,#amsdos_table05
			cp	#5
			jr	z,isv05
			cp	#7
			jr	nz,no_amsdos
			ld	hl,#amsdos_table07
isv05:		
funcloop:		inc	hl
			inc	hl
			djnz	funcloop
			ld	a,(hl)
			inc	hl
			ld	h,(hl)
			ld	l,a
			ld	a,h
			ret
no_amsdos:	xor	a
			ret
; |DISC command

			
disc:		push	hl
			push	bc
			push	af
			ld	b,#1			; function 

pass_to_amsdos:
			call	get_amsdos_ptr
			cp	#0
			jp	nz,jumper
			
			; check if amsdos present at all, if not |disc is same as |sd
			ld	a,(amsdos_ver)
			cp	#0
			jr	nz, m4pass
			call	patch_fio
			
m4pass:		pop	af
			pop	bc
			pop	hl
			ret

			; |TAPE

tape:		push	hl
			push	bc
			push	af
			
			; SD mode?
			ld	a,(0xBC78)
			cp	#0xA4
			jr	nz,amsdos_mode
			
			; only copy vectors if not present amsdos, otherwise let amsdos copy the vectors
			ld	a,(amsdos_ver)
			cp	#0
			jr	nz, amsdos_mode
			ld	hl,#tape_functions			
			ld	de,#0xbc77
			ld	bc,#48
			ldir
			jp	m4pass
amsdos_mode:			
			ld	b,#4
			jp	pass_to_amsdos


			; |A
			
drvA:		push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass
			
			ld	b,#7
			jp	pass_to_amsdos

			; |B
			
drvB:		push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass
			
			ld	b,#8
			jp	pass_to_amsdos

drive:		push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass
			
			ld	b,#9
			jp	pass_to_amsdos

user:		push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass	; todo
			
			ld	b,#10
			jp	pass_to_amsdos
						

set_message:	push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass
			
			ld	b,#14
			jp	pass_to_amsdos

setup_disc:	push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass	; todo
			
			ld	b,#15
			jp	pass_to_amsdos

select_format:	push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass	; todo
			
			ld	b,#16
			jp	pass_to_amsdos
										
format_track:	push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass	; todo
			
			ld	b,#19
			jp	pass_to_amsdos

move_track:	push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass	; todo
			
			ld	b,#20
			jp	pass_to_amsdos		

get_dr_status:	push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass	; todo
			
			ld	b,#21
			jp	pass_to_amsdos
set_retry_cnt:	push	hl
			push	bc
			push	af
			
			; if SD mode ignore
			ld	a,(0xBC78)
			cp	#0xA4
			jp	z,m4pass	; todo
			
			ld	b,#22
			jp	pass_to_amsdos
												
jumper:		di
			ld	a,(basic_ver)	; version
			cp	#0
			jr	nz, not_basic10
			ld	a,(amsdos_rom_num)
			ld	(#0xB1A8),a
			jr	jumper_cont
not_basic10:
			ld	a,(amsdos_rom_num)
			ld	(#0xB8D6),a
jumper_cont:			
			ld	(iy),#0xED	; out (c),a
			ld	1(iy),#0x79
			ld	2(iy),#0xF1	; pop af
			ld	3(iy),#0xC1	; pop bc
			ld	4(iy),#0xE1	; pop hl
			ld	5(iy),#0xFB	; ei
			ld	6(iy),#0xc3	; jump
			ld	7(iy),l		; addr
			ld	8(iy),h		; addr
			push	iy
			pop	hl
			ld	iy,(0xBE7D)	; Amsdos workspace
			ld	bc,#0xDF00
			jp	(hl)			; jump to ram
set_amsdos_functions:
			push	hl
			push	de
			push	bc
			ld	hl,#tape_functions			
			ld	de,#0xbc77
			ld	bc,#48
			ldir
			pop	bc
			pop	de
			pop	hl
			ret
set_drvA:		push	hl
			push	bc
			ld	hl,(0xBE7D)
			ld	bc,#4
			add	hl,bc
			ld	(hl),#0
			pop	bc
			pop	hl
			ret			
set_drvB:		push	hl
			push	bc
			ld	hl,(0xBE7D)
			ld	bc,#4
			add	hl,bc
			ld	(hl),#1
			pop	bc
			pop	hl
			ret						
data_0:		.db	0,1		
romslots_fn:
			.ascii "/m4/romslots.bin"
			.db	0
romconfig_fn:
			.ascii "/m4/romconfig.bin"
			.db	0
autoexec_fn:	.ascii "/AUTOEXEC.BAS"
			.db	0
			
sdir_cmd:
			.db	2			; size
			.dw	C_READDIR	; command C_sdir
sfree_cmd:
			.db	2			; size
			.dw	C_FREE	; command C_sdir

seek_cmd:
			.db	2			; size
			.dw	C_SEEK	; command C_sdir

eof_cmd:
			.db	2
			.dw	C_EOF

ftell_cmd:
			.db	3
			.dw	C_FTELL
			.db	1		; read fd


fail_msg:
			.ascii "File not found or other error."
			.db 10, 13, 0
	
miss_arg:
			.ascii "Missing arguments."
			.db 10, 13, 0
txt_copying:	.ascii	"Copy: "
			.db	0
txt_to:		.ascii	" -> "
			.db	0
txt_copy_err:	.ascii	"Error occurred."
			.db	10,13,0

text_unkdir:
			.ascii "Unknown directory."
			.db 10, 13, 0
text_ip:		.ascii "IP: "
			.db 0
text_nm:		.ascii "Netmask: "
			.db 0
text_gw:		.ascii "Gateway: "
			.db 0
text_dns1:	.ascii "DNS1: "
			.db 0
text_dns2:	.ascii "DNS2: "
			.db 0
text_mac:		.ascii "MAC: "
			.db 0
						
text_drive:
			.db 10, 13
			.ascii "Drive A:"
			.db 0	; 10, 13, 10, 13, 0

text_signal:	.ascii "Signal: 0x"
			.db	0
text_not_found:
			.ascii " not found"
			.db	10,13,0
text_break:	.db	10,13
			.ascii "*Break*"
			.db	10,13,0
ff_error_map:
			.db 0x0	;FR_OK				0
			.db 0xFF	;FR_DISK_ERR			1
			.db 0xFF	;FR_INT_ERR			2
			.db 0xFF	;FR_NOT_READY			3
			.db 0x92	;FR_NO_FILE			4
			.db 0x92	;FR_NO_PATH			5
			.db 0x92	;FR_INVALID_NAME		6
			.db 0xFF	;FR_DENIED			7
			.db 0x91	;FR_EXIST				8	128+17 File already exists
			.db 0xFF	;FR_INVALID_OBJECT		9
			.db 0xFF	;FR_WRITE_PROTECTED		10
			.db 0xFF	;FR_INVALID_DRIVE		11
			.db 0xFF	;FR_NOT_ENABLED			12
			.db 0xFF	;FR_NO_FILESYSTEM		13
			.db 0xFF	;FR_MKFS_ABORTED		14
			.db 0xFF	;FR_TIMEOUT			15
			.db 0xFF	;FR_LOCKED				16
			.db 0xFF	;FR_NOT_ENOUGH_CORE		17
			.db 0xFF	;FR_TOO_MANY_OPEN_FILES	18
			.db 0xFF	;FR_INVALID_PARAMETER	19
			.db 0xE	; already open			20

amsdos_table05:
			.dw	0xC1B2		; CPM
			.dw	0xCCD1		; DISC
			.dw	0xCCD5		; DISC.IN
			.dw	0xCCE4		; DISC.OUT
			.dw	0xCCFD		; TAPE
			.dw	0xCD01		; TAPE.IN
			.dw	0xCD18		; TAPE.OUT
			.dw	0xCDDA		; A
			.dw	0xCDDD		; B
			.dw	0xCDE4		; DRIVE 
			.dw	0xCDFE		; USER
			.dw	0xD42E		; DIR
			.dw	0xD48A		; ERA
			.dw 	0xD4C4		; REN
			.dw	0xCA72		; 81 SetMessage
			.dw	0xC60D		; 82 SetupDisc
			.dw	0xC581		; 83 SelectFormat
			.dw	0xC666		; 84 ReadSector
			.dw	0xC64E		; 85 WriteSector
			.dw	0xC652		; 86 FormatTrack
			.dw	0xC763		; 87 MoveTrack
			.dw	0xC630		; 88 GetDrStatus
			.dw	0xC603		; 89 SetRetryCount
amsdos_table07:
			.dw	0xC1A9		; CPM
			.dw	0xCD35		; DISC
			.dw	0			; DISC.IN
			.dw	0			; DISC.OUT
			.dw	0xCD61		; TAPE
			.dw	0			; TAPE.IN
			.dw	0			; TAPE.OUT
			.dw	0xCED1		; A
			.dw	0xCED4		; B
			.dw	0xCEDB		; DRIVE 
			.dw	0xCEF5		; USER
			.dw	0xD525		; DIR
			.dw	0xD581		; ERA
			.dw 	0xD5BB		; REN
			.dw	0xCAD8		; 81 SetMessage
			.dw	0xC706		; 82 SetupDisc
			.dw	0xC581		; 83 SelectFormat
			.dw	0xC666		; 84 ReadSector
			.dw	0xC64E		; 85 WriteSector
			.dw	0xC652		; 86 FormatTrack
			.dw	0xC792		; 87 MoveTrack
			.dw	0xC630		; 88 GetDrStatus
			.dw	0xC603		; 89 SetRetryCount			
			
jump_vec2:	.dw	load_autoexec	; 10
			
helper_functions:
				.dw hsend
				.dw hreceive
.org rom_response-0x100
run_filename:
				.ds 256 			; (256-1) max file+path depth
					
.org rom_response
				.ds	0xC00
.org	rom_config
amsdos_inheader:	.dw	0	; 0
jump_vec:			.dw	0	; 2
rom_num:			.db	0	; 4
init_count:		.db	0	; 5
amsdos_outheader:	.dw	0	; 6
rom_workspace:		.dw	0	; 8
old_bb5a:			.ds	3	; 10
old_bc6e:			.ds	3	; 13
amsdos_ver:		.db	0	; 16
amsdos_rom_num:	.db	0	; 17
basic_ver:		.db	0		; 18
				.db	0		; 19

runfile_ptr:		.dw	autoexec_fn ; 20
					; 22
tape_functions:	.ds	48



.org	sock_status
sock_info:	.ds	80	; 5 socket status structures (0 is used for gethostbyname*, 1-4 returned by socket function) of 16 bytes
; structure layout
;	status		1	- current status 0=idle, 1=connect in progress, 2=send in progress, 3=remote closed connectoion, 4=wait incoming (accept), 240-255 = error code
;	lastcmd		1	- last command updating sock status 0=none, 1=send, 2=dnslookup, 3=connect, 4=accept, 5=recv, 6=error handler
;	received		2	- data received in internal buffer (ready to get with C_NETRECV)
;	ip_addr		4	- ip addr of connected client in passive mode
;	port			2	- port of the same..
;	reserved		6	- not used yet (alignment!).
; *for socket 0, gethostbyname, status will be set to 5 when in progress and back to 0, when done.

.org	rom_table
			.dw	#0x201	; rom version
			.dw	rom_response
			.dw	rom_config
			.dw	sock_info
			.dw	helper_functions
			.dw	run_filename
	
.org	0xFFFF
			.db	0xFF	
.AREA _DATA