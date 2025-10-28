; GUID definitions (little-endian in memory as UEFI expects)

default rel
section .data

global guid_gop, guid_snp, guid_dhcp4, guid_udp4_svc, guid_udp4, guid_tcp4_svc, guid_dns4

; EFI_GRAPHICS_OUTPUT_PROTOCOL
guid_gop:
  dq 0x9042a9de23dc4a38
  dq 0x96fb7aded080516a

; EFI_SIMPLE_NETWORK_PROTOCOL
guid_snp:
  dq 0x5b1b31a1c0b5d211
  dq 0x9397080009dfe3b8

; EFI_DHCP4_PROTOCOL
guid_dhcp4:
  dq 0x8a2197184ef54a3a
  dq 0x82a69833db4223f4

; EFI_UDP4_SERVICE_BINDING_PROTOCOL
guid_udp4_svc:
  dq 0x83f014642bcf4a8b
  dq 0x90e384e5bdb226a3

; EFI_UDP4_PROTOCOL
guid_udp4:
  dq 0x3ad9df29e6bd43e8
  dq 0x8a2a3e0f9ea82117

; EFI_TCP4_SERVICE_BINDING_PROTOCOL
guid_tcp4_svc:
  dq 0x0072062b4a1563a4
  dq 0xa0f9fb16aab8b6f3

; EFI_DNS4_PROTOCOL
guid_dns4:
  dq 0xadf0d5340cfb49f1
  dq 0xa112b4567fe2fce1

