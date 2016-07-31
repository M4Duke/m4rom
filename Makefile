SRCS = M4ROM.s
PROJ_NAME = M4ROM
AS:=sdasz80
CC:=sdcc
LD:=sdcc
HEXBIN=./hex2bin.exe

OBJS = $(SRCS:.s=.rel)
.SUFFIXES: .c .s 

all: $(PROJ_NAME).bin

$(PROJ_NAME).bin: #$(OBJS)
	$(AS) -o $(SRCS:.s=.rel) $(SRCS)
	$(CC) -o $(SRCS:.s=.ihx) --no-std-crt0 -mz80 --verbose $(OBJS)
	$(HEXBIN) -e BIN $(SRCS:.s=.ihx)

.s.rel:
	$(AS) $(ASFLAGS) -o $@ $<

.S.rel:
	$(AS) $(ASFLAGS) -o $@ $<

.c.rel:
	$(CC) $(CFLAGS) $(INCDIR) -c $< -o $*.o
