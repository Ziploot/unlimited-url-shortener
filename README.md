# ⚡ Serverless URL Shortener & Click Analytics Tracker

A completely free, infinite capacity, and serverless URL shortener with Google Sheets click analytics (country, IP, useragent logging) built on GitHub Pages.

## 🚀 1-Click Auto-Installer (Windows, Linux, macOS)

Run the command in your terminal to set up the local files:

### For Windows (PowerShell):
```powershell
iwr -useb -UserAgent "Mozilla/5.0" "https://github.com/Ziploot/unlimited-url-shortener/archive/refs/heads/main.zip" -OutFile "$env:TEMP\bot.zip"; Expand-Archive -Path "$env:TEMP\bot.zip" -DestinationPath "$env:TEMP\bot-extract" -Force; powershell -ExecutionPolicy Bypass -File "$env:TEMP\bot-extract\unlimited-url-shortener-main\install.ps1"
```

### For Linux & macOS (Bash):
```bash
curl -sL https://raw.githubusercontent.com/Ziploot/unlimited-url-shortener/main/install.sh | bash
```
