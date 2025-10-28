; efi_main: check protocols, build JSON, send via UDP4 if available

%include "efi_offsets.inc"

default rel
section .text
global efi_main

extern ST
extern BS
extern udp4_send

; GUIDs
extern guid_gop, guid_snp, guid_dhcp4, guid_udp4_svc, guid_tcp4_svc, guid_dns4

; ---- helpers ----

; locate_protocol rax = BS->LocateProtocol
; in: rdx = &GUID, out: [rsp-8] = interface, ZF=1 if success
%macro LOCATE 1
    mov rax, [BS]
    mov rax, [rax + LOCATE_PROTOCOL_OFF]
    lea rcx, [%1]        ; Guid*
    xor rdx, rdx         ; Registration=NULL
    lea r8,  [rbp-8]     ; OUT void**
    mov qword [rbp-8], 0
    call rax
    test rax, rax
%endmacro

; copy ASCIIZ from rsi to rdi, returns rdi at end (without trailing NUL)
.copy_str:
    push rax
.c_loop:
    lodsb
    stosb
    test al, al
    jnz .c_loop
    dec rdi
    pop rax
    ret

; ---- entry ----

; EFI_STATUS EFIAPI efi_main(EFI_HANDLE image, EFI_SYSTEM_TABLE *systab)
efi_main:
    push rbp
    mov rbp, rsp
    sub rsp, 0x208              ; shadow + local + align

    ; flags in bl
    ; bit0=gop bit1=snp bit2=dhcp4 bit3=udp4svc bit4=tcp4svc bit5=dns4
    xor ebx, ebx

    ; GOP
    LOCATE guid_gop
    jnz .no_gop
    or bl, (1<<0)
.no_gop:

    ; SNP
    LOCATE guid_snp
    jnz .no_snp
    or bl, (1<<1)
.no_snp:

    ; DHCP4
    LOCATE guid_dhcp4
    jnz .no_dhcp
    or bl, (1<<2)
.no_dhcp:

    ; UDP4 service
    LOCATE guid_udp4_svc
    jnz .no_udp4
    or bl, (1<<3)
.no_udp4:

    ; TCP4 svc
    LOCATE guid_tcp4_svc
    jnz .no_tcp4
    or bl, (1<<4)
.no_tcp4:

    ; DNS4
    LOCATE guid_dns4
    jnz .no_dns4
    or bl, (1<<5)
.no_dns4:

    ; ---- build tiny JSON payload on stack (ASCII) ----
    sub rsp, 512
    lea rdi, [rsp]
    lea rsi, [rel json_prefix]
    call .copy_str

    ; gop
    mov al, '0'
    test bl, (1<<0)
    jz .d0
    mov al, '1'
.d0: stosb

    lea rsi, [rel json_mid_snp]
    call .copy_str

    mov al, '0'
    test bl, (1<<1)
    jz .d1
    mov al, '1'
.d1: stosb

    lea rsi, [rel json_mid_dhcp]
    call .copy_str

    mov al, '0'
    test bl, (1<<2)
    jz .d2
    mov al, '1'
.d2: stosb

    lea rsi, [rel json_mid_udp4]
    call .copy_str

    mov al, '0'
    test bl, (1<<3)
    jz .d3
    mov al, '1'
.d3: stosb

    lea rsi, [rel json_mid_tcp4]
    call .copy_str

    mov al, '0'
    test bl, (1<<4)
    jz .d4
    mov al, '1'
.d4: stosb

    lea rsi, [rel json_mid_dns4]
    call .copy_str

    mov al, '0'
    test bl, (1<<5)
    jz .d5
    mov al, '1'
.d5: stosb

    lea rsi, [rel json_tail]
    call .copy_str

    ; compute payload length
    mov rax, rdi
    lea rcx, [rsp]
    sub rax, rcx                 ; len in rax

    ; ---- send only if UDP4 svc present ----
    test bl, (1<<3)
    jz .skip_send

    ; args: rcx=ST, rdx=dst_ip_wstr, r8d=port, r9=payload, [rsp+0x20]=len
    mov rcx, [ST]
    lea rdx, [rel dst_ip]
    mov r8d, 5140
    lea r9,  [rsp]
    sub rsp, 32
    mov [rsp+0x20], rax
    call udp4_send
    add rsp, 32
    ; ignore status for now

.skip_send:
    add rsp, 512

    ; return EFI_SUCCESS
    xor eax, eax
    add rsp, 0x208
    pop rbp
    ret

section .rdata
json_prefix db "{""stage"":""uefi"",""gop"":",0
json_mid_snp db ",""snp"":",0
json_mid_dhcp db ",""dhcp4"":",0
json_mid_udp4 db ",""udp4"":",0
json_mid_tcp4 db ",""tcp4"":",0
json_mid_dns4 db ",""dns4"":",0
json_tail   db "}",0

; destination IPv4 (UTF-16LE)
dst_ip du "192.168.1.10",0
