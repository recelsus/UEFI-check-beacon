; UEFI x86_64, Microsoft x64 ABI
; BootServices vtable offsets (typical for UEFI 2.x / gnu-efi)

%ifndef EFI_OFFSETS_INC
%define EFI_OFFSETS_INC

; === BootServices function pointer offsets ===
%define RAISE_TPL_OFF              0x18
%define RESTORE_TPL_OFF            0x20
%define ALLOCATE_PAGES_OFF         0x28
%define FREE_PAGES_OFF             0x30
%define GET_MEMORY_MAP_OFF         0x38
%define ALLOCATE_POOL_OFF          0x58
%define FREE_POOL_OFF              0x60
%define CREATE_EVENT_OFF           0x68
%define CLOSE_EVENT_OFF            0x78
%define WAIT_FOR_EVENT_OFF         0x80
%define SET_TIMER_OFF              0x88
%define SIGNAL_EVENT_OFF           0x90
%define LOCATE_HANDLE_BUFFER_OFF   0x120
%define LOCATE_PROTOCOL_OFF        0x140   ; EFI_STATUS LocateProtocol(IN EFI_GUID*, IN VOID*, OUT VOID**)

; === EFI_UDP4 structures (packed) ===
; EFI_IPv4_ADDRESS = 4 bytes
; EFI_UDP4_CONFIG_DATA layout (per UEFI spec; with natural alignment)
; Offsets here assume typical edk2 packing on x64.
%define UDP4_CFG_ACCEPT_BCAST      0
%define UDP4_CFG_ACCEPT_PROMISCU   1
%define UDP4_CFG_ACCEPT_ANYPORT    2
%define UDP4_CFG_ALLOW_DUP_PORT    3
%define UDP4_CFG_TOS               4   ; UINT8
%define UDP4_CFG_TTL               5   ; UINT8
%define UDP4_CFG_DNF               6   ; BOOLEAN
%define UDP4_CFG_PAD0              7
%define UDP4_CFG_RECV_TIMEOUT      8   ; UINT32
%define UDP4_CFG_XMIT_TIMEOUT      12  ; UINT32
%define UDP4_CFG_USE_DEF_ADDR      16  ; BOOLEAN
%define UDP4_CFG_PAD1              17
%define UDP4_CFG_PAD2              18
%define UDP4_CFG_PAD3              19
%define UDP4_CFG_STATION_ADDR      20  ; 4
%define UDP4_CFG_SUBNET_MASK       24  ; 4
%define UDP4_CFG_STATION_PORT      28  ; UINT16
%define UDP4_CFG_PAD4              30  ; 2
%define UDP4_CFG_REMOTE_ADDR       32  ; 4
%define UDP4_CFG_REMOTE_PORT       36  ; UINT16
%define UDP4_CFG_SIZE              40

; EFI_UDP4_SESSION_DATA
%define UDP4_SESS_SRC_ADDR         0    ; 4 (unused if UseDefaultAddress=TRUE)
%define UDP4_SESS_SRC_PORT         4    ; UINT16
%define UDP4_SESS_PAD0             6    ; 2
%define UDP4_SESS_DST_ADDR         8    ; 4
%define UDP4_SESS_DST_PORT         12   ; UINT16
%define UDP4_SESS_PAD1             14   ; 2
%define UDP4_SESS_SIZE             16

; EFI_UDP4_FRAGMENT_DATA
%define UDP4_FRAG_LENGTH           0    ; UINT32
%define UDP4_FRAG_BUFFER           8    ; VOID* (on x64, 8 bytes)
%define UDP4_FRAG_SIZE             16

; EFI_UDP4_TRANSMIT_DATA (simplified: 1 fragment)
; struct {
;   EFI_UDP4_SESSION_DATA *UdpSessionData;         +0
;   EFI_EVENT              GatewayAddress;         +8   (unused here)
;   EFI_EVENT              RecyclingEvent;         +16  (unused)
;   UINT32                 DataLength;             +24
;   UINT32                 FragmentCount;          +28
;   EFI_UDP4_FRAGMENT_DATA FragmentTable[1];       +32
; }
%define UDP4_TX_SESS_PTR           0
%define UDP4_TX_GW_EVENT           8
%define UDP4_TX_RECYCLE_EVENT      16
%define UDP4_TX_DATA_LEN           24
%define UDP4_TX_FRAG_COUNT         28
%define UDP4_TX_FRAG_TABLE         32
%define UDP4_TX_SIZE               32+16  ; 48

%endif

