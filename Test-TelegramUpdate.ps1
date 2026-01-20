# Test-TelegramUpdate.ps1
# Local script to test the Telegram stats update workflow
# Run this before committing to verify the workflow will work correctly

param(
    [switch]$DryRun = $false,
    [switch]$ShowVerbose = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  iPapkorn Telegram Stats Update Test  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Fetch Telegram channel data
Write-Host "[1/4] Fetching Telegram channel data..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "https://t.me/s/iPapkorn" -UseBasicParsing
    $html = $response.Content
    Write-Host "  OK - Successfully fetched channel page" -ForegroundColor Green
}
catch {
    Write-Host "  FAILED - Could not fetch channel page: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Extract data
Write-Host "[2/4] Extracting statistics..." -ForegroundColor Yellow

# Extract subscriber count
$subscribers = $null
if ($html -match '([\d.]+[KMB]?)\s*subscribers') {
    $subscribers = $matches[1] + "+"
    Write-Host "  OK - Subscriber count: $subscribers" -ForegroundColor Green
}
else {
    Write-Host "  WARN - Could not extract subscriber count" -ForegroundColor Yellow
}

# Extract post IDs
$postMatches = [regex]::Matches($html, 'data-post="iPapkorn/(\d+)"')
$postIds = $postMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Descending -Unique | Select-Object -First 3

$postCountK = $null
if ($postIds.Count -ge 3) {
    Write-Host "  OK - Latest post IDs: $($postIds[0]), $($postIds[1]), $($postIds[2])" -ForegroundColor Green
    $lastPostId = [int]$postIds[0]
    
    # Calculate post count in K format
    $postCountK = [math]::Round($lastPostId / 1000, 1).ToString() + "K+"
    Write-Host "  OK - Post count: $postCountK (from post ID $lastPostId)" -ForegroundColor Green
}
else {
    Write-Host "  WARN - Could not extract enough post IDs" -ForegroundColor Yellow
    $postIds = @()
}

# Extract view counts
$viewMatches = [regex]::Matches($html, 'tgme_widget_message_views">([^<]+)')
$viewCounts = $viewMatches | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -First 3
if ($viewCounts.Count -gt 0) {
    Write-Host "  OK - View counts: $($viewCounts -join ', ')" -ForegroundColor Green
}

# Extract post dates
$dateMatches = [regex]::Matches($html, 'datetime="([^"]+)"')
$postDates = $dateMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 3
if ($postDates.Count -gt 0) {
    Write-Host "  OK - Post dates: $($postDates -join ', ')" -ForegroundColor Green
}

# Extract poster images
$posterMatches = [regex]::Matches($html, "background-image:url\('([^']+)'\)")
$posterImages = $posterMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 3
if ($posterImages.Count -gt 0) {
    Write-Host "  OK - Poster images found: $($posterImages.Count)" -ForegroundColor Green
    if ($ShowVerbose) {
        $posterImages | ForEach-Object { Write-Host "       $_" -ForegroundColor Gray }
    }
}

# Extract channel description
if ($html -match 'tgme_channel_info_description">([^<]+)') {
    $channelDesc = $matches[1]
    Write-Host "  OK - Channel description found ($($channelDesc.Length) chars)" -ForegroundColor Green
}

Write-Host ""

# Step 3: Show what will be updated
Write-Host "[3/4] Changes to be made:" -ForegroundColor Yellow

$indexPath = Join-Path $PSScriptRoot "index.html"
if (-not (Test-Path $indexPath)) {
    Write-Host "  FAILED - index.html not found at: $indexPath" -ForegroundColor Red
    exit 1
}

$indexContent = Get-Content $indexPath -Raw

# Current values
if ($indexContent -match 'id="stat-subscribers">([^<]+)<') {
    $currentSubs = $matches[1]
    if ($currentSubs -eq $subscribers) {
        Write-Host "  Subscribers: $currentSubs (no change)" -ForegroundColor Gray
    }
    else {
        Write-Host "  Subscribers: $currentSubs -> $subscribers" -ForegroundColor Magenta
    }
}

if ($indexContent -match 'id="stat-movies">([^<]+)<') {
    $currentPosts = $matches[1]
    if ($currentPosts -eq $postCountK) {
        Write-Host "  Movies/Posts: $currentPosts (no change)" -ForegroundColor Gray
    }
    else {
        Write-Host "  Movies/Posts: $currentPosts -> $postCountK" -ForegroundColor Magenta
    }
}

if ($indexContent -match "const postIds = \['(\d+)', '(\d+)', '(\d+)'\]") {
    $currentIds = "$($matches[1]), $($matches[2]), $($matches[3])"
    $newIds = "$($postIds[0]), $($postIds[1]), $($postIds[2])"
    if ($currentIds -eq $newIds) {
        Write-Host "  Recent Posts: $currentIds (no change)" -ForegroundColor Gray
    }
    else {
        Write-Host "  Recent Posts: $currentIds -> $newIds" -ForegroundColor Magenta
    }
}

Write-Host ""

# Step 4: Apply changes (or simulate)
if ($DryRun) {
    Write-Host "[4/4] DRY RUN - No changes made" -ForegroundColor Yellow
    Write-Host "  Run without -DryRun to apply changes" -ForegroundColor Gray
}
else {
    Write-Host "[4/4] Applying changes..." -ForegroundColor Yellow
    
    $modified = $false
    
    # Update subscriber count
    if ($subscribers) {
        $indexContent = $indexContent -replace 'id="stat-subscribers">[^<]*<', "id=`"stat-subscribers`">$subscribers<"
        $indexContent = $indexContent -replace "target: '[0-9.]+M\+'", "target: '$subscribers'"
        $modified = $true
    }
    
    # Update post count
    if ($postCountK) {
        $indexContent = $indexContent -replace 'id="stat-movies">[^<]*<', "id=`"stat-movies`">$postCountK<"
        $indexContent = $indexContent -replace "target: '[0-9.]+K\+'", "target: '$postCountK'"
        $modified = $true
    }
    
    # Update post IDs
    if ($postIds -and $postIds.Count -ge 3) {
        $newPostIdsStr = "const postIds = ['$($postIds[0])', '$($postIds[1])', '$($postIds[2])']"
        $indexContent = $indexContent -replace "const postIds = \['\d+', '\d+', '\d+'\]", $newPostIdsStr
        $modified = $true
    }
    
    if ($modified) {
        Set-Content -Path $indexPath -Value $indexContent -NoNewline
        Write-Host "  OK - index.html updated successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "  No changes needed" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test complete!                       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor Gray
Write-Host "  .\Test-TelegramUpdate.ps1 -DryRun   # Preview changes" -ForegroundColor Gray
Write-Host "  .\Test-TelegramUpdate.ps1           # Apply changes" -ForegroundColor Gray
