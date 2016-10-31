			; M4 Board cpc z80 rom
			; Written by Duke, 2016
			; www.spinpoint.org
			
FR_OK				.equ 0
FR_DISK_ERR			.equ 1
FR_INT_ERR			.equ 2
FR_NOT_READY			.equ 3
FR_NO_FILE			.equ 4
FR_NO_PATH			.equ 5
FR_INVALID_NAME		.equ 6
FR_DENIED				.equ 7
FR_EXIST				.equ 8
FR_INVALID_OBJECT		.equ 9
FR_WRITE_PROTECTED		.equ 10
FR_INVALID_DRIVE		.equ 11
FR_NOT_ENABLED			.equ 12
FR_NO_FILESYSTEM		.equ 13
FR_MKFS_ABORTED		.equ 14
FR_TIMEOUT			.equ 15
FR_LOCKED				.equ 16
FR_NOT_ENOUGH_CORE		.equ 17
FR_TOO_MANY_OPEN_FILES	.equ 18
FR_INVALID_PARAMETER	.equ 19


FA_READ 						.equ	1
FA_WRITE						.equ	2
FA_CREATE_ALWAYS				.equ 8