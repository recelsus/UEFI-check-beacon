# uefi-asm-beacon

- GOP / SNP / DHCP4 / UDP4 / TCP4 / DNS4 の各プロトコルをLocateProtocolで検出
- UDP4サービスが利用可能な場合、UseDefaultAddress (DHCP) でJSON形式のビーコンを一度だけ送信
- 上記以外の場合は何もせず EFI_SUCCESS を返却

- 受信側は未実装です

## ビルド手順
Arch Linux での例:
```bash
sudo pacman -S --needed gnu-efi nasm ovmf qemu
make
```

`build/bootx64.efi` に出力されます。OVMFとQEMUを用意している場合は `make run` で簡単に確認できます。

## ディレクトリ構成
- `src/` : NASMソースコード (`main.nasm`, `udp4_send.nasm` など)
- `efi_offsets.inc` : Boot Services や UDP4構造体のオフセット定義
- `guids.nasm` : 使用しているUEFIプロトコルのGUID定義

## 注意点
- Boot Servicesテーブルのオフセット値や構造体レイアウトは、一般的なUEFI 2.x / edk2環境を想定しています。プラットフォームによっては調整が必要になる場合があります。
- ネットワーク機能を利用するため、環境に応じたDHCP/UDP設定が有効であることを確認してください。
