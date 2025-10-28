TARGET  = BOOTX64.EFI
ARCH    = x86_64
EFIDIR  = /usr
NASM    = nasm
NASMFLAGS = -f elf64 -Wall -Werror

LDS     = $(EFIDIR)/lib/elf_$(ARCH)_efi.lds
LIBS    = -lefi -lgnuefi
CFLAGS  = -I$(EFIDIR)/include -I$(EFIDIR)/include/efi -I$(EFIDIR)/include/efi/$(ARCH) \
          -fno-stack-protector -fshort-wchar -fno-strict-aliasing -fPIC -mno-red-zone
LDFLAGS = -nostdlib -T $(LDS) -shared -Bsymbolic -L $(EFIDIR)/lib $(LIBS)

SRCS    = src/main.nasm src/guids.nasm src/udp4_send.nasm
OBJS    = $(SRCS:.nasm=.o)

all: $(TARGET)

%.o: %.nasm src/efi_offsets.inc
	$(NASM) $(NASMFLAGS) -I src/ $< -o $@

$(TARGET): $(OBJS)
	ld $(LDFLAGS) $^ -o tmp.so
	objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym \
	        -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc \
	        --target=efi-app-$(ARCH) tmp.so $@
	rm -f tmp.so

clean:
	rm -f $(OBJS) $(TARGET)

