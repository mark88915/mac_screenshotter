# Screenshotter

一款輕量的 macOS 原生截圖與標註工具，常駐於選單列，透過快捷鍵即可快速擷取螢幕區域並進行編輯。

## 功能特色

- **區域截圖** — 自由框選螢幕任意區域，支援多螢幕
- **內建編輯器** — 截圖後立即進入編輯模式，提供以下工具：
  - 畫筆：自由繪製標註
  - 框選：繪製矩形標記
  - 馬賽克：對敏感資訊打碼
- **多色 & 線寬調整** — 紅、藍、綠、黃、白、黑六色可選，線寬 1–20 自由調整
- **快速匯出** — 複製到剪貼簿或儲存為 PNG 檔案
- **全域快捷鍵** — `⌘⇧7` 隨時觸發截圖
- **選單列常駐** — 不佔用 Dock，輕巧不干擾

## 系統需求

- macOS 14.0 (Sonoma) 或更新版本
- 需授予「螢幕錄製」與「輔助使用」權限

## 安裝與建構

```bash
# 建構 release 並打包為 .app
chmod +x build_app.sh
./build_app.sh

# 執行
open Screenshotter.app
```

## 首次啟動設定

1. 開啟 App 後，macOS 會要求授予「螢幕錄製」權限
2. 前往 **系統設定 > 隱私權與安全性 > 螢幕錄製**，啟用 Screenshotter
3. **重新啟動** App 以套用權限
4. 若出現「輔助使用」權限提示，請一併授予

## 使用方式

1. App 啟動後會出現在選單列（相機圖示）
2. 按下 `⌘⇧7` 或從選單列點選「截圖」
3. 拖曳框選要擷取的區域
4. 在編輯器中進行標註
5. 點選「複製」或「儲存」匯出成果

## 專案結構

```
├── Package.swift                  # Swift Package Manager 設定
├── build_app.sh                   # 建構與打包腳本
├── Resources/
│   └── Info.plist                 # App 設定檔
└── Sources/Screenshotter/
    ├── ScreenshotterApp.swift     # App 進入點
    ├── AppDelegate.swift          # 應用程式委派
    ├── StatusBarController.swift  # 選單列控制
    ├── HotkeyManager.swift        # 全域快捷鍵管理
    ├── ScreenCapture/
    │   ├── ScreenCaptureManager.swift   # 截圖核心邏輯
    │   ├── RegionSelectionWindow.swift  # 選取覆蓋視窗
    │   └── RegionSelectionView.swift    # 區域選取 UI
    ├── Editor/
    │   ├── EditorWindowController.swift # 編輯器視窗
    │   ├── EditorView.swift             # 編輯器 UI
    │   ├── CanvasView.swift             # 繪圖畫布
    │   └── DrawingElements.swift        # 繪圖元素定義
    └── Utilities/
        ├── ImageExport.swift      # 圖片匯出（剪貼簿 / 檔案）
        └── Permissions.swift      # 權限檢查
```

## 技術棧

- **Swift 5.9** + **SwiftUI** / **AppKit**
- **ScreenCaptureKit** — 螢幕擷取
- **Carbon HIToolbox** — 全域快捷鍵註冊
- **Swift Package Manager** — 建構管理

## 授權

本專案為個人專案，保留所有權利。
