FROM ubuntu:16.04

RUN apt-get update && \
	apt-get -yq install sdcc make wget bzip2 binutils

WORKDIR /tmp
RUN wget https://freefr.dl.sourceforge.net/project/hex2bin/hex2bin/Hex2bin-2.5.tar.bz2 && \
	tar -xjf Hex2bin-2.5.tar.bz2 &&\
	cd  /tmp/Hex2bin-2.5 &&\
	make install


RUN mkdir -p /src/m4rom
WORKDIR /src/m4rom

