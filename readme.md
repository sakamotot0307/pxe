Windows 11 PXE ブートセットアップガイド

このガイドは、Windows 11のSysprepイメージを作成し、WinPEイメージを準備し、pypxeを使用してPXEブートを設定する手順を説明します。

# 概要
1. SysprepでWindows 11のシステムを汎用化
2. ディスクイメージの作成
3. PXEブートサーバーの設定（pypxeの使用）
4. クライアントPCのPXEブート設定
5. クライアントPCのPXEブート設定

# 詳細手順

# 1. SysprepでWindows 11のシステムを汎用化

* Windows 11のセットアップとカスタマイズ

必要なソフトウェアや設定を行い、すべての不要なファイルやプログラムを削除します。

監査モードでログイン

```bash
cd %windir%\system32\sysprep
sysprep /audit /reboot
```
Sysprepの実行

監査モードで設定を行い、次にSysprepを実行します：

```bash
cd %windir%\system32\sysprep
sysprep /oobe /generalize /shutdown
```
/oobe: 次回の起動時にOut-of-Box Experienceを実行。

/generalize: システムを汎用化し、固有のSIDを削除。

/shutdown: Sysprep実行後にシステムをシャットダウン。

# 2. ディスクイメージの作成

Windows PEの作成

Windows ADKをダウンロードし、インストールします。

コマンドプロンプトで以下を実行し、WinPE作業ディレクトリを作成します：

```bash
copype amd64 C:\WinPE_amd64
MakeWinPEMedia /ISO C:\WinPE_amd64 C:\WinPE_amd64\WinPE.iso
```

Windows PEからブート

作成したWinPE ISOをマウントし、USBメディアにコピーしてブートします。

DISMを使用してイメージのキャプチャ

Windows PE環境でコマンドプロンプトを開き、以下を実行します：

```bash
dism /capture-image /imagefile:D:\install.wim /capturedir:C:\ /name:"Windows 11 Image"
```

# 3. WinPEの作成と準備

WinPEイメージのカスタマイズ
必要なドライバやツールをWinPEに追加します：

```bash
dism /Add-Driver /Image:C:\WinPE_amd64\mount /Driver:<path_to_driver>
```

WinPEイメージをISOとして作成

以下を実行します：

```bash
MakeWinPEMedia /ISO C:\WinPE_amd64 C:\WinPE_amd64\WinPE.iso
```

ISOファイルをマウントし、TFTPルートディレクトリにファイルをコピー

以下を実行します：

```bash
xcopy /e /h /k /i D:\* C:\TFTP-Root\
```

# 4. PXEブートサーバーの設定（pypxeの使用）

Python環境の準備とpypxeのインストール
以下を実行します：

```bash
sudo apt update
sudo apt install python3 python3-pip
pip install pypxe
```

pypxeの設定ファイルを作成
以下の内容で設定ファイルを作成します：

```bash
{
    "DHCP": {
        "enabled": true,
        "start_ip": "192.168.1.100",
        "end_ip": "192.168.1.200",
        "subnet_mask": "255.255.255.0",
        "gateway": "192.168.1.1",
        "dns": ["8.8.8.8"],
        "broadcast": "192.168.1.255",
        "options": {
            "arch": ["x86_64"]
        }
    },
    "TFTP": {
        "enabled": true,
        "root": "/path/to/tftp/root"
    },
    "HTTP": {
        "enabled": true,
        "root": "/path/to/http/root"
    },
    "iPXE": {
        "enabled": true,
        "script": "/path/to/boot.ipxe"
    }
}
```

boot.ipxeスクリプトを作成
以下の内容でboot.ipxeスクリプトを作成します：

```bash
#!ipxe
dhcp
set base-url http://192.168.1.1:8080
kernel ${base-url}/bootmgr.exe
initrd ${base-url}/Boot/BCD
initrd ${base-url}/Boot/boot.sdi
initrd ${base-url}/sources/boot.wim
boot
```

pypxeを起動
以下を実行します：

```bash
pypxe --config /path/to/pypxe-config.json
```

# 5. クライアントPCのPXEブート設定

BIOS/UEFI設定でネットワークブートを有効にする

クライアントPCのBIOS/UEFI設定に入り、ネットワークブートを有効にし、PXEブートの優先順位を上げます。

クライアントPCのPXEブート

クライアントPCを再起動し、PXEブートが正常に行われるか確認します。
