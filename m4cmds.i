			; M4 Board cpc z80 rom
			; Written by Duke, 2016
			; www.spinpoint.org

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
C_SDREAD						.equ 0x4314
C_SDWRITE						.equ 0x4315
C_FSTAT						.equ 0x4316	
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
C_ROMLIST						.equ	0x432C
C_CMDRBTRUN					.equ	0x432D

C_NETSOCKET					.equ 0x4331
C_NETCONNECT					.equ 0x4332
C_NETCLOSE					.equ 0x4333
C_NETSEND						.equ 0x4334
C_NETRECV						.equ 0x4335
C_NETHOSTIP					.equ 0x4336
C_NETRSSI						.equ 0x4337
C_NETBIND						.equ 0x4338
C_NETLISTEN					.equ 0x4339
C_NETACCEPT					.equ 0x433A
C_GETNETWORK					.equ 0x433B
C_WIFIPOW						.equ	0x433C

C_CONFIG						.equ 0x43FE

C_WRITE_COC					.equ 0x4343