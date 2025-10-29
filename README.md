# uefi-asm-beacon

Pure-asm (NASM, x86_64) UEFI app that:
- Detects the presence of GOP/SNP/DHCP4/UDP4/TCP4/DNS4 protocols
- If UDP4 is present, sends a 1-shot JSON beacon via UDP4 using UseDefaultAddress (DHCP)
- Otherwise, no-op and return success

- Receiving server not implemented.

## Build
Arch Linux:
```bash
sudo pacman -S --needed gnu-efi nasm ovmf qemu
make

