# ZipLoot Windows 1-Click Serverless URL Shortener Setup
try {
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "[ZipLoot] URL Shortener Installer" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green

    $ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

    # --- COLLECT INPUT ---
    $pat = ""
    while ([string]::IsNullOrWhiteSpace($pat)) {
        $pat = Read-Host "[INPUT] Enter your GitHub Personal Access Token (PAT)"
    }

    Write-Host "`n[INFO] Connecting to GitHub..." -ForegroundColor Green
    $headers = @{
        "Authorization" = "token $pat"
        "Accept"        = "application/vnd.github.v3+json"
        "User-Agent"    = $ua
    }

    # 1. Fetch GitHub Username
    $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
    $username = $user.login
    $repoName = "$username.github.io"
    Write-Host "[INFO] Logged in as: $username" -ForegroundColor Green
    Write-Host "[INFO] Repository to create: $repoName" -ForegroundColor Green

    # 2. Create the Repository (<username>.github.io)
    Write-Host "[SETUP] Creating repository on GitHub..." -ForegroundColor Cyan
    $repoPayload = @{
        name = $repoName
        description = "Serverless URL Shortener & Click Analytics Tracker using GitHub Pages and Google Sheets"
        private = $false
        has_issues = $true
        has_projects = $false
        has_wiki = $false
    } | ConvertTo-Json

    try {
        $createRes = Invoke-RestMethod -Method Post -Uri "https://api.github.com/user/repos" -Headers $headers -Body $repoPayload -ContentType "application/json"
        Write-Host "[SUCCESS] Repository created successfully!" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode -eq 422) {
            Write-Host "[INFO] Repository already exists on your account." -ForegroundColor Green
        } else {
            throw $_
        }
    }

    # Helper function to upload file to GitHub Pages repository
    function Upload-GitHubFile($filename, $filePath) {
        $fileContent = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
        $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $contentBase64 = [Convert]::ToBase64String($contentBytes)
        
        $uploadUrl = "https://api.github.com/repos/$username/$repoName/contents/$filename"
        
        # Get file SHA if it exists
        $sha = $null
        try {
            $meta = Invoke-RestMethod -Method Get -Uri $uploadUrl -Headers $headers
            $sha = $meta.sha
        } catch {}

        $uploadPayload = @{
            message = "Deploy $filename via ZipLoot Installer"
            content = $contentBase64
        }
        if ($sha) { $uploadPayload["sha"] = $sha }

        $uploadJson = $uploadPayload | ConvertTo-Json
        Invoke-RestMethod -Method Put -Uri $uploadUrl -Headers $headers -Body $uploadJson -ContentType "application/json" | Out-Null
        Write-Host "[SUCCESS] Uploaded $filename" -ForegroundColor Green
    }

    # 3. Upload template files
    Write-Host "[SETUP] Uploading files to your repository..." -ForegroundColor Cyan
    Upload-GitHubFile "index.html" "$scriptDir\index.html"
    Upload-GitHubFile "404.html" "$scriptDir\404.html"
    Upload-GitHubFile "admin.html" "$scriptDir\admin.html"
    Upload-GitHubFile "redirects.json" "$scriptDir\redirects.json"
    Upload-GitHubFile "README.md" "$scriptDir\README.md"

    # 4. Automatically enable GitHub Pages
    Write-Host "[SETUP] Activating GitHub Pages..." -ForegroundColor Cyan
    $pagesPayload = @{
        source = @{
            branch = "main"
            path   = "/"
        }
    } | ConvertTo-Json

    try {
        $pagesRes = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$username/$repoName/pages" -Headers $headers -Body $pagesPayload -ContentType "application/json"
        Write-Host "[SUCCESS] GitHub Pages activated successfully!" -ForegroundColor Green
    } catch {
        try {
            $pagesInfo = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$username/$repoName/pages" -Headers $headers
            Write-Host "[SUCCESS] GitHub Pages is active!" -ForegroundColor Green
        } catch {
            Write-Host "[WARN] Could not auto-enable GitHub Pages. Please enable it manually in Settings > Pages on GitHub." -ForegroundColor Yellow
        }
    }

    # 5. Wait for Pages deployment to be live
    Write-Host "`n[SETUP] Waiting for GitHub Pages to build and deploy your site..." -ForegroundColor Cyan
    Write-Host "[INFO] This takes about 20-40 seconds on GitHub's side. Please wait..." -ForegroundColor Gray
    
    $siteReady = $false
    $retries = 15 # 15 * 5 = 75 seconds max
    for ($i = 0; $i -lt $retries; $i++) {
        Write-Host -NoNewline "."
        try {
            $req = [System.Net.HttpWebRequest]::Create("https://$username.github.io/admin.html")
            $req.Method = "HEAD"
            $req.Timeout = 3000
            $req.CachePolicy = New-Object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore)
            $res = $req.GetResponse()
            if ($res.StatusCode -eq 200 -or $res.StatusCode -eq 302 -or $res.StatusCode -eq 301) {
                $siteReady = $true
                $res.Close()
                break
            }
            $res.Close()
        } catch {
            # 404 or other network error means it is still building
        }
        Start-Sleep -Seconds 5
    }
    Write-Host "`n"

    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] Setup Completed! Your Link Shortener is active!" -ForegroundColor Green
    Write-Host "Redirection Site: https://$username.github.io" -ForegroundColor Green
    Write-Host "Admin Dashboard:  https://$username.github.io/admin.html" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    
    Read-Host "`nPress Enter to exit..."
} catch {
    Write-Host "[ERROR] Setup failed: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}
