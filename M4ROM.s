			
			; M4 Board cpc z80 rom
			; Written by Duke, 2016
			; www.spinpoint.org
			
			.module cpc
			.area _HEADER (ABS)
			.org 0xC000
	
cas_catalog					.equ 0xbc9b
cas_in_close					.equ 0xbc7a
cas_in_open					.equ 0xbc77
cas_out_close					.equ 0xbc8f
cas_out_open					.equ 0xbc8c
hi_kl_curr_selection 			.equ 0xb912
mc_start_program		   		.equ 0xbd16

rom_response					.equ	0xD000
rom_config					.equ 0xD900
sock_status					.equ	0xFE00

FA_READ 						.equ	1
FA_WRITE						.equ	2
FA_CREATE_ALWAYS				.equ 8

C_OPEN						.equ 0x4301
C_READ						.equ 0x4302
C_WRITE						.equ 0x4303
C_CLOSE						.equ 0x4304
C_SEEK						.equ 0x4305
C_READDIR						.equ	0x4306
C_EOF						.equ	0x4307
C_CD							.equ 0x4308
C_FREE  						.equ 0x4309
C_FTELL						.equ 0x430A
C_READSECTOR					.equ 0x430B
C_WRITESECTOR					.equ 0x430C
C_FORMATTRACK					.equ 0x430D
C_ERASEFILE					.equ 0x430E
C_RENAME						.equ	0x430F
C_MAKEDIR						.equ	0x4310
C_FSIZE						.equ	0x4311
C_READ2						.equ 0x4312
C_GETPATH						.equ 0x4313
C_HTTPGET						.equ 0x4320
C_SETNETWORK					.equ 0x4321
C_M4OFF						.equ	0x4322
C_NETSTAT						.equ	0x4323
C_TIME						.equ	0x4324
C_DIRSETARGS					.equ	0x4325
C_VERSION						.equ	0x4326
C_UPGRADE						.equ	0x4327
C_HTTPGETMEM					.equ	0x4328
C_COPYBUF						.equ	0x4329
C_COPYFILE					.equ	0x432A
C_ROMSUPDATE					.equ	0x432B
C_NETSOCKET					.equ 0x4331
C_NETCONNECT					.equ 0x4332
C_NETCLOSE					.equ 0x4333
C_NETSEND						.equ 0x4334
C_NETRECV						.equ 0x4335
C_NETHOSTIP					.equ 0x4336
C_CONFIG						.equ 0x43FE


DATAPORT						.equ 0xFE00
ACKPORT						.equ 0xFC00

			.db	0x01
			.db	2, 0, 0
	
			.dw	rsx_commands

			; RSX jump block
			jp 	init_rom
			jp	temp			; |A
			jp	change_dir	; |CD
			jp	copy_file		; |COPYF
			jp 	directory		; |DIR
			jp	temp			; |DISC
			jp	temp			; |DRIVE
			jp	erase_file	; |ERA
			jp	httpget		; |HTTPGET
			jp	httpgetmem	; |HTTPMEM
			jp	m4off		; |M4ROMOFF
			jp	makedir		; |MKDIR
			jp	setnetwork	; |NETSET
			jp	netstat		; |NETSTAT
			jp	rename_file	; |REN
			jp	gettime		; |TIME
			jp	upgrade		; |UPGRADE
			jp	version		; |VERSION
			jp	temp			; 0x81	Set message
			jp	temp			; 0x82	Drive speed
			jp	temp			; 0x83	Disc type
			jp	read_sector	; 0x84	Read sector
			jp	temp			; 0x85	Write sector
			jp	temp			; 0x86	Format track
			jp	temp			; 0x87	Seek track
			jp	temp			; 0x88	Test drive
			jp	temp			; 0x89	Set retry count
			jp	rom_upload	; |ROMUP
			jp	rom_set		; |ROMSET
			jp	rom_update	; |ROMUPD
			.org 0xC072
  			jp	init_plus
rsx_commands:
			.ascis "M4 BOARD"	
			.ascis "A"
			.ascis "CD"
			.ascis "COPYF"
			.ascis "DIR"
			.ascis "DISC"
			.ascis "DRIVE"
			.ascis "ERA"
			.ascis "HTTPGET"
			.ascis "HTTPMEM"
			.ascis "M4ROMOFF"
			.ascis "MKDIR"
			.ascis "NETSET"
			.ascis "NETSTAT"
			.ascis "REN"
			.ascis "TIME"
			.ascis "UPGRADE"
			.ascis "VERSION"
			.db 0x81	; Set message
			.db 0x82	; Drive speed
			.db 0x83	; Disc type
			.db 0x84	; Read sector
			.db 0x85	; Write sector
			.db 0x86	; Format track
			.db 0x87	; Seek track
			.db 0x88	; Test drive
			.db 0x89	; Set retry count
			.ascis "ROMUP"
			.ascis "ROMSET"
			.ascis "ROMUPD"
			.db 0

get_iy_amsdos_header:
			ld	iy,(#rom_config)
			ret
			
get_iy_workspace:
			push	bc
			ld	iy,(#rom_config)
			ld	bc,#128	;70
			add	iy,bc
			pop	bc
			ret

init_rom:		push de
			push hl
			ld	hl,#8
			add	hl,sp
			push	af
		
			ld	a,(hl)
			cp	#0x2e
			jr	z,ok464
			cp	#0x2b
			jr	nz,nosign
ok464:
			inc hl
			ld a,(hl)
			cp #3
			call z,boot_message
nosign:
			pop	af
			cp	#0			; normally a is 0, but if called by m4 bootrom a == rom number
			call z, #hi_kl_curr_selection
		
			pop	iy
			ld	bc,#-260	
			add	iy,bc
			push	iy
			push	iy
			pop	hl
			ld	de, #fio_jvec
init_cont:			
			ld	(iy),#8			; config size (to increase)
			ld	1(iy),#C_CONFIG
			ld	2(iy),#C_CONFIG>>8
			ld	3(iy),l			; amsdos header ptr l
			ld	4(iy),h			; amsdos header ptr h
			ld	5(iy),e			; patch jump vector l
			ld	6(iy),d			; patch jump vector h
			ld	7(iy),a			; current rom
			ld	8(iy),#0
			
			call	send_command_iy
			call	patch_fio
			pop	hl
			pop	de
			and a
			scf
			
			ret
			
init_plus:	ld	hl,#plus_packet
			call	send_command
			
			ld	hl,#0
			.db 0xc3,0x16, 0xbd
			; set config offset 8 to +, to indicate it is a CPC+ 
plus_packet:	.db	0x9,#C_CONFIG,#C_CONFIG>>8,0,0,0,0,0,1,'+'

boot_message:
			ld	a,(#rom_config+6)
			cp	#'+'	
			jr	nz,not_plus
			ld	a,(#rom_config+5)
			cp	#1
			ret	nz
not_plus:			
			ld	hl,#init_msg
			call	disp_msg
			ret	

init_msg:
			.ascii " M4 Board V2.0"
			.db 10, 13, 10, 13, 0x0

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
			;push	iy
			;call get_iy_workspace
			;ld	0(iy),#2
			;ld	1(iy),#0xFF
			;ld	2(iy),#0x43
			;call	send_command_iy
			;pop	iy
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

upper_case:
			cp	#'a'
			jr	nc,ge_a
			
ge_a:		cp	#'z'
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

_cas_in_open:
			push	iy
			push	hl
			push	de
			push	bc
			ld	a,#FA_READ			; read mode
			call	fopen
			cp	#0xFF
			jr	nz, open_ok
			pop	bc
			pop	de
			pop	hl
			pop	iy
			or	a					; clear carry
			ret
open_ok:

			; read first 128 bytes and check if its using AMSDOS header
			call	get_iy_amsdos_header
			push	iy
			pop	de				; DE address =  ptr to amsdos header
			ld	hl,#128			; size of header
			ld	a,#1				; fd
			call	fread
			
			; todo add error checking
			
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
			
			pop	hl
			ld	b,#128
clear_loop:
			ld	(hl),#0
			inc	hl
			djnz	clear_loop			
			
			; copy filename into "fake" header
			pop	bc	; b = filename len
			pop	de	; 2k buffer or 0
			ld	19(iy),e
			ld	20(iy),d
			pop	hl	; filename
			push	iy
			pop	de
			inc	de
			call	strcpy83
			ld	18(iy),#0x16; set as ascii?
			ld	23(iy),#0xFF	; first block 0xFF
			
			;ld	de,#0;	x170			; load adr
			ld	e,19(iy)
			ld	d,20(iy)
			
			ld	bc,#0			; size, should set ?
			push	iy
			pop	hl
			scf	; set carry flag
			sbc	a,a	; clear z	
			ld	a,#0x16	; x2
			pop	iy
			ret
	
checksum_ok:
			pop	hl
			pop	de	; b =filename len
			pop	de	; 2k buffer or 0
			pop	de	; filename

			
			; HL = AMSDOS header
			;pop	hl	;de
			;ex	de,hl
			
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
; ------------------------- cas_in_char replacment BC80 
_cas_in_char:
			push	hl
			push	bc
			push de
			push	iy
			ld	ix,(#rom_config)
			call	get_iy_workspace
			ld	l,-6(iy)			;	size
			ld	h,-5(iy)			;	
			ld	c,-4(iy)			;	index
			ld	b,-3(iy)			; 
			or	a
			sbc	hl,bc
			xor	a
			cp	h
			jr	nz, no_buffer_fill
			cp	l
			jr	nz, no_buffer_fill
			ld	a,-2(iy)			; EOF yet?
			cp	#0
			jp	nz, char_in_eof
			
			ld	(iy),#5			; packet size, cmd (2), fd (1), size (2)
			ld	1(iy),#C_READ2
			ld	2(iy),#C_READ2>>8
			ld	3(iy),#1			; fd
			ld	4(iy),#0			; 
			ld	5(iy),#0x08		; size 2k
			push	iy
			pop	hl
			call	send_command
			
			ld	a,(#rom_response+3)
			cp	#20				; eof ?
			jr	nz, not_eof_yet
			ld	hl,(#rom_response+4)	; read size
			xor	a
			cp	h
			jr	nz, not_eof_yet
			cp	l
			jr	nz, not_eof_yet
			ld	a,#1
			ld	-2(iy),a			; this is end of file
			jr	char_in_eof
not_eof_yet:			
			
			ld	hl,(#rom_response+4)	; read size
			ld	-6(iy),l			;	size
			ld	-5(iy),h			;	
			ld	-4(iy),#0			; index
			ld	-3(iy),#0			; index
			ld	c,l
			ld	b,h
			ld	hl,#rom_response+6
			
			ld	e,19(ix)			; 2k buffer
			ld	d,20(ix)
			ldir
no_buffer_fill:

			; should add screen ram check
			;ld	l,-6(iy)			;	size
			;ld	h,-5(iy)			;	
			
			ld	l,19(ix)			; 2k buffer
			ld	h,20(ix)
		
			ld	c,-4(iy)			;	index
			ld	b,-3(iy)			; 
			add	hl,bc
			
			inc	bc
			ld	-4(iy),c			;	index
			ld	-3(iy),b			; 
			ld	b,(hl)
			inc	hl
			ld	a,(hl)
			cp	#26
			jr	nz,over_eof		;	char_in_eof		; soft EOF
			ld	a,#1
			ld	-2(iy),a			; this is end of file
over_eof:		ld	a,b
			cp	a,#26
			jr	z,char_in_eof
			or	a

					; Z flag reset (false)
			scf		; C flag set (true)
			
			;sbc	a	;false
			pop	iy
			pop	de
			pop	bc
			pop	hl
			ret


char_in_eof:	or	a	; Z flag reset (false)
			scf
			ccf		; C flag reset (false)
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
			call	get_iy_amsdos_header
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
			ld	hl,#C_FTELL
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
_cas_test_eof:
			push	iy
			call	get_iy_workspace
			ld	a,-2(iy)
			pop	iy
			cp	#0
			jr	z, not_eof2
			or	a	; Z flag reset (false)
			scf
			ccf		; C flag reset (false)
			ret

not_eof2:		;or a	; Z flag reset
			scf	; C flag set
			sbc	a,a ; Z flag set
			
			ret

			push	hl
			push	de
			push	bc
			ld	hl,#eof_cmd
			call	send_command
			ld	a,(#rom_response+3)
			cp	#0
			jr	z, not_eof
			pop	bc
			pop	de
			pop	hl
			or	a	; z flag not set (false)
			scf
			ccf		; carry not set (false)
			
			ret
			
not_eof:		pop	bc
			pop	de
			pop	hl
			push	iy
			call	get_iy_workspace
			
			;or	a	; z flag not set (false)
			scf
			sbc	a,a
			
			ld	a,-1(iy)
			pop	iy
			ret
; ------------------------- cas_out_close replacement BC8F
_cas_out_close:
			ld	a,#2
			call	fclose
			cp	#0
			scf
			jr	nz,close_out_fail
			sbc	a,a
			ret
close_out_fail:
			ccf	
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
			push	bc
			ld	a,#FA_WRITE | FA_CREATE_ALWAYS	; write mode
			call	fopen
			cp	#0xFF
			jr	nz, open_w_ok
			pop	bc
			pop	iy
			or	a			; clear carry
			ret
open_w_ok:
			; create	header
			call	get_iy_amsdos_header
			push	iy
			pop	de
			ld	b, #128
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
			scf
			sbc	a,a
			ret
; ------------------------- cas_out_char  replacement	BC95
; -- parameters
; -- A = char
; TODO
; buffer stream and write on close.
_cas_out_char:
			push	bc
			push	af
			ld	bc,#DATAPORT				; data out port
			ld	a,#4
			out	(c),a						; size
			ld	a,#C_WRITE
			out	(c),a						; command lo
			ld	a,#C_WRITE>>8
			out	(c),a						; command	hi
			ld	a,#2
			out	(c),a						; fd
			pop	af
			out	(c),a						; output char
			
			; tell M4 that command has been send
			ld	bc,#ACKPORT
			out (c),c
			pop	bc
			scf
			sbc	a,a
			ret


			; ------------------------- cas_out_open  replacement	BC98
			; -- parameters
			; -- HL = address of data
			; -- DE = size of data
			; -- BC = execution address
			; --  A = filetype
_cas_out_direct:
			push	iy
			call	get_iy_amsdos_header
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
				
			
			ld	hl,#config+2
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

			; ------------------------- fopen
			; -- parameters: 
			; -- HL = filename
			; -- B = filename length
			; -- A = mode
			; -- return:
			; -- A = file fd

fopen:
			push	bc
			push	de
			push	hl
			push	iy
			call	get_iy_workspace
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
			ld	a,#0xFF
			pop	iy
			pop	hl
			pop	de
			pop	bc
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
			call	get_iy_workspace
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
			call	get_iy_workspace
			ld	1(iy),#C_READ
			ld	2(iy),#C_READ>>8
			ld	3(iy),a				; fd
			ld	(iy),#5				; packet size, cmd (2), fd (1), size (2)

read_loop:
			; get chunk size (<=0x200)
			
			push	hl
			ld	bc,#-0x200
			add	hl,bc				; and substract chunksize
			jp	c, full_chunk
			pop 	hl
			ld	4(iy),l				; chunk size low
			ld	5(iy),h				; chunk size high
			jr	fread_cont
	
full_chunk:
			pop	hl
			ld	4(iy),#0x0			; chunk size low
			ld	5(iy),#0x2			; chunk size high
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
			
			call	get_iy_workspace
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
			call	get_iy_workspace
			ld	1(iy),#C_CLOSE		; close cmd
			ld	2(iy),#C_CLOSE>>8	; close cmd
			ld	3(iy),a			; fd
			ld	(iy),#3	; size - cmd(2) + fd(1)
			call send_command_iy
			pop	iy
			pop	hl
			pop	bc
			ret
; ------------------------- _cas_catalog replacement BC9B
_cas_catalog:
			push	bc
			push	de
			push	hl
			push	iy
			call	get_iy_workspace
			ld	1(iy),#C_DIRSETARGS
			ld	2(iy),#C_DIRSETARGS>>8
			call	dir_no_args
			pop	iy
			pop	hl
			pop	de
			pop	bc
			ret
			scf
			sbc	a,a
			ret	
directory:
			call	get_iy_workspace
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
			call	#0xBB69			; TXT GET WINDOW
									; H holds the column number of the left edge, 
									; D holds the column number of the right edge, 
									; L holds the line number of the top edge, 
									; E holds the line number of the bottom edge, 
									; A is corrupt, Carry is false if the window covers the entire screen, and the other registers are always preserved
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
			call	#0xbb5a
			ld	a,#10
			call	#0xbb5a
was_last_column1:	
			ld	hl,#rom_response+3
			call	disp_msg
			scf
			sbc	a,a
			ret	
sdir_cont1:
			inc	hl
			inc	hl
			inc	hl
			call	disp_msg
			pop	bc
			inc	b
			ld	a,b
			cp	c
			jr	nz,next_column1
			ld	a,#13
			call	#0xbb5a
			ld	a,#10
			call	#0xbb5a
		
			jr	dir_loop1
next_column1:
			ld	a,#32
			call	#0xbb5a
			call	#0xbb5a
			call	#0xbb5a
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
			LD	A,#0x48
			call	key_scan
			BIT	2,A			; ESC 
			jr	nz, esc_exit			

esc_loop:		LD	A,#0x48
			call	key_scan
			BIT	2,A
			jr	z, esc_loop	; it is released
	
			call	#0xBB03
			call	#0xBB18
esc_exit:
			pop	bc
			ei
			ret
			
			; taken from http://www.cpcwiki.eu/index.php/Programming:Keyboard_scanning, thanks !
key_scan:		ld	d,#0
			ld	bc,#0xf782	; ppi port a out /c out 
			out	(c),c 
			ld	bc,#0xf40e	; select ay reg 14 on ppi port a 
			out	(c),c 
			ld	bc,#0xf6c0	; this value is an ay index (r14) 
			out	(c),c 
			out	(c),d 		; validate!! out (c),0
			ld	bc,#0xf792	; ppi port a in/c out 
			out	(c),c 
			dec	b 
			out	(c),a 		; send kbdline on reg 14 ay through ppi port a
			ld 	b,#0xf4		; read ppi port a 
			in	a,(c)		; e.g. ay r14 (ay port a) 
			ld	bc,#0xf782	; ppi port a out / c out 
			out	(c),c 
			dec	b			; reset ppi write 
			out	(c),d		; out (c),0
			ret

; ------------------------- HTTP GET - download file from http to current path
httpget:
			call	get_iy_workspace
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
			call	get_iy_workspace
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
			call	get_iy_workspace
			ld	(iy),#2
			ld	1(iy),#C_NETSTAT
			ld	2(iy),#C_NETSTAT>>8
			call	send_command_iy
			
			ld	hl,#rom_response+3
			call	disp_msg
			scf
			sbc	a,a
			ret
; ------------------------- get time and date
gettime:
			call	get_iy_workspace
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
			call	get_iy_workspace
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
			call	get_iy_workspace
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
			call	get_iy_workspace
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
			cp	#0
			jp	z,bad_args
			
			call	get_iy_workspace
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
			cp	#2			; 2 arguments?
			jr	nz, bad_args
			call	get_iy_workspace
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
			call	get_iy_workspace
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
			
			call	get_iy_workspace
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
			call	get_iy_workspace
			cp	#0
			jr	nz,cd_has_args
			call	#0xBB69			; TXT GET WINDOW ( D = max column )
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
sendloop:	inc	b
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
			call	get_iy_workspace
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
			push	iy
			push	hl
			call	get_iy_workspace
			ld	(iy), #0x5
			ld	1(iy), #0x0B
			ld	2(iy), #0x43
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
			
disp_msg:		ld 	a, (hl)
			or	a
			ret	z
			call 0xBB5A
			inc	hl
			jr	disp_msg
			
			; cursor copy function for basic 1.0, may remove later if space needed now you can replace lowerrom and use basic 1.1
			
get_path:		call	#0xbb78	; get cursor pos
			push	hl	; real cursor pos
			pop	bc
			ld	a,#25
			cp	c
			jr	nc,not_last_line
			ld	c,#25	; no scrolling, please
not_last_line:
			call	#0xbb8a
inputloop:	
			push	hl
			call	#0xbd19
			call	#0xbb09
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
			call	#0xbb8d
			pop	hl
			ld	a,h
			cp	b
			jr	nz,not_same_pos
			ld	a,l
			cp	c
			jr	z,same_pos
not_same_pos:	ld	h,b
			ld	l,c
			call	#0xbb75
			call	#0xbb8d	;remove real cursor

same_pos:
			ld	a,#10
			call	#0xbb5a
			ld	a,#13
			call	#0xbb5a
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
			call	z, #0xbb8d
			ld	(iy),#1
	
			call	#0xbb75	; set cursor
			call	#0xbb8a
			pop	hl
			ret

copy_char:	push	af
			push	hl	; copy cursor position
	
			call	#0xbb8d	; remove copy cursor
			call	#0xbb60	; read char current cursor pos
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
			call	#0xbb75
			call	#0xbb8d	; remove cursor
			pop	af
			push	bc
			call	#0xbb5d	; print 'copy' char
			pop	bc
			; set new real cursor position
			inc	b
			ld	h,b
			ld	l,c
			call	#0xbb75	
			call	#0xbb8a	; place cursor
	
			pop	hl
			; set back to copy cursor pos
			inc	h	; new pos
			push	hl
			call	#0xbb75	; 
			call	#0xbb8a	; place cursor
			pop	hl
			
			pop	af
			ret
key_press:	
			push	hl
			push	af
			; set real cursor pos
			ld	h,b
			ld	l,c
			call	#0xbb75
			call	#0xbb8d	; remove cursor
			
	
			
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

			call	#0xbb5a	; print char
			; set new real cursor position
			inc	b
			ld	h,b
			ld	l,c
			call	#0xbb75	
			call	#0xbb8a	; place cursor
	
			pop	hl
			; set back to copy cursor pos
			push	hl
			call	#0xbb75
			pop	hl
			ret


del_char:		push	af
			push	hl
			; set real cursor pos
			ld	h,b
			ld	l,c
			call	#0xbb75
			call	#0xbb8d	; remove cursor
			ld	a,b
			cp	#1
			jr	z,at_start_pos
			dec	b
			ld	h,b
			ld	l,c
			call	#0xbb75	; update real cursor pos
			
			ld	a,2(iy)	; filename len (pos)
			cp	#0
			jr	z, at_start_pos
			dec	a
			ld	2(iy),a
			
at_start_pos:
			ld	a,#32
			call	#0xbb5a	; overwrite the char with a space
			; set cursor back
			ld	h,b
			ld	l,c
			call	#0xbb75	; update real cursor pos
			call	#0xbb8a
			pop	hl
			; set back to copy cursor pos
			push	hl
			call	#0xbb75	
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
			call	get_iy_workspace
				
			; get rom slot
			
			;ld	 ,(ix)
			;ld	 ,1(ix)
			
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
			call	get_iy_workspace
				
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
			ld	1(iy),#C_ROMSUPDATE
			ld	2(iy),#C_ROMSUPDATE>>8
			ld	(iy),#2			; packet size, cmd (2)
			call	send_command_iy
			scf
			sbc	a,a
			ret	
			
;---------------------------------------
; Helper functions
			
			
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
		
					
data_0:		.db	0,1		
romslots_fn:
			.ascii "/m4/romslots.bin"
			.db	0
romconfig_fn:
			.ascii "/m4/romconfig.bin"
			.db	0

sdir_cmd:
			.db 2			; size
			.dw C_READDIR	; command C_sdir

sfree_cmd:
			.db 2			; size
			.dw C_FREE	; command C_sdir

seek_cmd:
			.db 2			; size
			.dw C_SEEK	; command C_sdir

eof_cmd:
			.db 2
			.dw	C_EOF
debug_cmd:
			.db 2			; size
			.dw 0x43FF	; command C_sdir


fail_msg:
			.ascii "File not found or other error."
			.db 10, 13, 0
	
miss_arg:
			.ascii "Missing arguments."
			.db 10, 13, 0

text_unkdir:
			.ascii "Unknown directory."
			.db 10, 13, 0

text_drive:
			.db 10, 13
			.ascii "Drive A: SD card"
			.db 10, 13, 10, 13, 0
text_break:	.ascii  "*Break*"
			.db 10, 13, 0

.org rom_response
			.ds	0x800



.org	rom_config
config:
			.db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.org	sock_status
sock_info:	.ds	20
			; socket 0  status		[1]
			; socket 0  notused		[1]
			; socket 0  recv buf size[2]
			; socket 1  status		[1]
			; socket 1  notused		[1]
			; socket 1  recv buf size[2]
			; etc...
			
helper_functions:
			.dw hsend
			.dw hreceive
.org	0xFF00
			.dw	#0x109	; rom version
			.dw	rom_response
			.dw	rom_config
			.dw	sock_info
			.dw	helper_functions
	
.org	0xFFFF
			.db	0xFF	
.AREA _DATA