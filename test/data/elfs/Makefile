source=source.cpp
FLAGS=
PIE_FLAGS=-pie
NOPIE_FLAGS=-no-pie
FULL_RELRO_FLAGS=-Wl,-z,relro,-z,now
PARTIAL_RELRO_FLAGS=-Wl,-z,relro
NO_RELRO_FLAGS=-Wl,-z,norelro
STATIC_FLAGS=-static
TARGETS=amd64 i386
.PHONY: clean
all: ${TARGETS}

amd64: ${source}
	g++ -m64 ${source} -o amd64.frelro.elf ${FLAGS} ${FULL_RELRO_FLAGS} ${NOPIE_FLAGS}
	g++ -m64 ${source} -o amd64.frelro.pie.elf ${FLAGS} ${FULL_RELRO_FLAGS} ${PIE_FLAGS}
	g++ -m64 ${source} -o amd64.prelro.elf ${FLAGS} ${PARTIAL_RELRO_FLAGS} ${NOPIE_FLAGS}
	g++ -m64 ${source} -o amd64.nrelro.elf ${FLAGS} ${NO_RELRO_FLAGS} ${NOPIE_FLAGS}
	g++ -m64 ${source} -o amd64.static.elf ${FLAGS} ${STATIC_FLAGS} ${NOPIE_FLAGS}
i386: ${source}
	g++ -m32 ${source} -o i386.prelro.elf ${FLAGS} ${PARTIAL_RELRO_FLAGS} ${NOPIE_FLAGS}
	g++ -m32 ${source} -o i386.frelro.pie.elf ${FLAGS} ${FULL_RELRO_FLAGS} ${PIE_FLAGS}

clean:
	rm -f *.elf
