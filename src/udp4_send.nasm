; Tiny helper: Configure UDP4 with UseDefaultAddress and Transmit a single fragment.
; int udp4_send(ST, dst_ip_wstr, dst_port, payload_ptr, payload_len)
;   rcx=ST*, rdx=CHAR16*, r8d=port, r9=payload
;   [rsp+0x20]=len
; returns EFI_STATUS in rax

%include "efi_offsets.inc"

default rel
section .text
global udp4_send

extern BS

; UEFI GUIDs and services
extern guid_udp4_svc
extern guid_udp4

; Import BootServices->LocateProtocol offset etc.

udp4_send:
    push rbp
    mov rbp, rsp
    sub rsp, 0x80                ; shadow + local temporaries
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, rcx                 ; st
    mov r13, rdx                 ; ip_wstr
    mov r14d, r8d                ; port
    mov r15, r9                  ; payload
    mov rbx, [rbp+0x28]          ; len (fifth arg at [rsp+0x20] before prologue -> [rbp+0x28] now)

    ; Locate UDP4 Service Binding
    mov rax, [BS]
    mov rax, [rax + LOCATE_PROTOCOL_OFF]
    lea rcx, [rel guid_udp4_svc]
    xor rdx, rdx
    lea r8,  [rbp-8]
    mov qword [rbp-8], 0
    call rax
    test rax, rax
    jnz .ret                     ; fail -> return status

    ; CreateChild
    mov rdi, [rbp-8]             ; service binding ptr
    mov rax, [rdi]               ; first entry is CreateChild in EFI_SERVICE_BINDING_PROTOCOL
    ; edk2 layout: CreateChild at offset 0, DestroyChild at +8
    lea rcx, [rbp-16]            ; handle storage
    sub rsp, 32
    ; Microsoft x64 ABI: rcx, rdx, r8, r9 used; svc->CreateChild(svc, &handle)
    ; we already have function pointer in rax; need to pass svc and &handle
    mov r9, 0
    mov r8, 0
    mov rdx, rcx                 ; &handle
    mov rcx, rdi                 ; svc
    call rax
    add rsp, 32
    test rax, rax
    jnz .ret

    mov rsi, [rbp-16]            ; child handle

    ; HandleProtocol(child, UDP4 -> udp)
    mov rax, [BS]
    ; EFI_STATUS HandleProtocol(IN EFI_HANDLE, IN EFI_GUID*, OUT VOID**)
    mov rdx, [rax + 0xa8]        ; HandleProtocol offset in BS table (typical)
    ; If 0xa8 differs on your platform, adjust or route via LocateHandleBuffer+OpenProtocol.
    ; For simplicity we use this common offset.
    mov rax, rdx
    mov rcx, rsi
    lea rdx, [rel guid_udp4]
    lea r8,  [rbp-24]
    mov qword [rbp-24], 0
    call rax
    test rax, rax
    jnz .destroy_child

    mov rdi, [rbp-24]            ; udp4 protocol ptr

    ; Configure with defaults
    ; Build EFI_UDP4_CONFIG_DATA on stack
    lea r8,  [rbp-0x80]          ; cfg base
    xor eax, eax
    mov rcx, 64/8
.zero_cfg:
    mov [r8 + rcx*8 - 8], rax
    loop .zero_cfg

    ; AcceptAnyPort=TRUE, AllowDuplicatePort=TRUE, TTL=64, UseDefaultAddress=TRUE
    mov byte [r8 + UDP4_CFG_ACCEPT_ANYPORT], 1
    mov byte [r8 + UDP4_CFG_ALLOW_DUP_PORT], 1
    mov byte [r8 + UDP4_CFG_TTL], 64
    mov byte [r8 + UDP4_CFG_USE_DEF_ADDR], 1

    ; Configure(udp, &cfg)
    ; function pointer at udp4->Configure is first or near first; in edk2 it is:
    ; typedef EFI_STATUS (EFIAPI *EFI_UDP4_CONFIGURE)(..., EFI_UDP4_CONFIG_DATA *);
    mov rax, [rdi]               ; assume Configure at vtable +0
    sub rsp, 32
    mov rcx, rdi
    mov rdx, r8
    mov r8,  0
    mov r9,  0
    call rax
    add rsp, 32
    test rax, rax
    jnz .destroy_child

    ; Build session + transmit data (1 fragment)
    lea r10, [rbp-0x60]          ; session
    mov rcx, (UDP4_SESS_SIZE+UDP4_TX_SIZE)/8 + 2
    lea r11, [rbp-0x70]
    xor eax, eax
.zero_sess_tx:
    mov [r11 + rcx*8 - 8], rax
    loop .zero_sess_tx

    ; parse ip_wstr "a.b.c.d" into 4 bytes
    ; simple parser: read digits, build octet
    ; r13 = wchar_t*
    lea rdx, [rbp-0x10]          ; store 4 bytes temporary
    xor r8d, r8d                 ; octet idx
    xor r9d, r9d                 ; current value
.parse_loop:
    movzx eax, word [r13]
    test eax, eax
    jz .ip_done
    add r13, 2
    cmp eax, '0'
    jb .skip_char
    cmp eax, '9'
    ja .check_dot
    ; digit
    imul r9d, r9d, 10
    add r9d, eax
    sub r9d, '0'
    jmp .parse_loop
.check_dot:
    cmp eax, '.'
    jne .skip_char
    ; store octet
    mov [rdx + r8], byte r9b
    inc r8b
    xor r9d, r9d
    jmp .parse_loop
.skip_char:
    jmp .parse_loop
.ip_done:
    mov [rdx + r8], byte r9b

    ; session.DestinationAddress = parsed bytes
    mov eax, dword [rbp-0x10]
    mov [r10 + UDP4_SESS_DST_ADDR], eax
    mov word [r10 + UDP4_SESS_DST_PORT], r14w

    ; tx
    lea r11, [rbp-0x30]          ; tx base
    mov [r11 + UDP4_TX_SESS_PTR], qword r10
    mov [r11 + UDP4_TX_DATA_LEN], dword ebx
    mov [r11 + UDP4_TX_FRAG_COUNT], dword 1

    ; frag
    mov [r11 + UDP4_TX_FRAG_TABLE + UDP4_FRAG_LENGTH], dword ebx
    mov [r11 + UDP4_TX_FRAG_TABLE + UDP4_FRAG_BUFFER], qword r15

    ; Transmit(udp, &tx)
    mov rax, [rdi + 8]           ; in edk2, Transmit is often second entry (+8)
    sub rsp, 32
    mov rcx, rdi
    mov rdx, r11
    mov r8,  0
    mov r9,  0
    call rax
    add rsp, 32
    mov r12, rax                 ; save status

.destroy_child:
    ; DestroyChild
    mov rax, [rbp-8]             ; svc ptr
    mov rdx, [rax + 8]           ; DestroyChild at +8
    sub rsp, 32
    mov rcx, rax                 ; svc
    mov r8,  0
    mov r9,  0
    mov rax, rdx
    mov rdx, rsi                 ; child handle
    call rax
    add rsp, 32

    mov rax, r12
.ret:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    leave
    ret
