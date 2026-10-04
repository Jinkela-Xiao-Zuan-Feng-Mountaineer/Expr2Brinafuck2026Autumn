# Expr 編譯器：學生起始專案

請依照 [HW3.md](../HW3.md) 實作將 Expr 轉換為 Brainfuck 的編譯器，再嘗試改善產生程式的執行效率。

`expr.cpp` 只提供命令列參數與檔案開啟的骨架，其餘部分由同學完成。

## 建置與介面

需要 C++17 編譯器、GNU Make 與 POSIX shell 工具。

- Linux、macOS 可使用終端機
- Windows 可使用 w64devkit、MSYS2 或 WSL。

```sh
make
./exprc example.expr > output.bf
```

命令列操作方法為 `exprc input.expr`。成功時將 Brainfuck 寫入 stdout 並回傳 0。失敗時將錯誤原因與原始碼行號寫入 stderr，並回傳 `43`，且**不輸出 Brainfuck**。

完成編譯器後，可用提供的執行器檢查結果：

```sh
make -C ../BrainfuckRunner
printf '4\n' | ../BrainfuckRunner/bf output.bf 1000000
```

`example.expr` 的預期輸出依序為 `23`、`4`、`5`、`251`，每筆一行。

## 測試

```sh
make test    # 語言行為與錯誤處理測試
make cases   # 執行保留的 44 組測資，顯示各案例指令步數
```

`benchmarks/cases/` 保留既有的 44 組測資：12 組針對性案例、8 組邊界案例及 24 組固定種子產生的隨機案例。

每組包含：

- `.expr`：待編譯的原始程式。
- `.in`：執行 Brainfuck 時提供的輸入，值皆在 0～255。
- `.expected`：預期 stdout。

測試腳本比對輸出並檢查程序是否成功；錯誤處理測試只自動檢查非零退出碼、stdout 為空及 stderr 有訊息，不限制錯誤文字。錯誤行號與原因仍須自行確認符合規格。

`make cases` 預設每組限制十億個 Brainfuck 指令，可用 `MAXSTEP=1000000 make cases` 調整。這是本機測試設定，不是正式評分標準。`make test` 也使用十億步上限。測試遇到第一個失敗即停止。

可自由設計編譯器內部架構。若拆分成多個來源檔，請同步調整 Makefile。

`make clean` 移除編譯產物。
