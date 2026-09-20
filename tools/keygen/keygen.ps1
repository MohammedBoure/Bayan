<#
.SYNOPSIS
    Bayan License Key Generator PowerShell Tool (مُوَلِّدُ مَفَاتِيحِ تَرْخِيصِ بَيَان)
.DESCRIPTION
    Generates an authentic activation code for Bayan using HMAC-SHA256 from a given device code.
.EXAMPLE
    .\keygen.ps1 -DeviceCode "BYN-675B-A8C1-7BFB"
    .\keygen.ps1
#>

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$DeviceCode
)

$MasterSecret = "BAYAN_PRIMARY_ARABIC_2026_MASTER_SECRET_KEY"

function Get-BayanActivationKey([string]$Code) {
    $cleanCode = $Code.Trim().ToUpper()
    if ([string]::IsNullOrWhiteSpace($cleanCode)) {
        return ""
    }

    $secretBytes = [System.Text.Encoding]::UTF8.GetBytes($MasterSecret)
    $msgBytes = [System.Text.Encoding]::UTF8.GetBytes($cleanCode)

    $hmac = [System.Security.Cryptography.HMACSHA256]::new($secretBytes)
    $hash = $hmac.ComputeHash($msgBytes)
    $hex = [BitConverter]::ToString($hash).Replace("-", "").ToUpper()

    $b1 = $hex.Substring(0, 4)
    $b2 = $hex.Substring(4, 4)
    $b3 = $hex.Substring(8, 4)
    $b4 = $hex.Substring(12, 4)

    return "ACT-$b1-$b2-$b3-$b4"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   بُسْتَانُ النَّحْوِ العَرَبِيِّ - مُوَلِّدُ كَوْدِ التَّفْعِيلِ (PowerShell)" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($DeviceCode)) {
    $DeviceCode = Read-Host "أَدْخِلْ كَوْدَ الجِهَازِ (Device Code)"
}

if ([string]::IsNullOrWhiteSpace($DeviceCode)) {
    Write-Host "خطأ: لم يتم إدخال كود الجهاز." -ForegroundColor Red
    exit 1
}

$ActivationKey = Get-BayanActivationKey -Code $DeviceCode

Write-Host "`n------------------------------------------------------------" -ForegroundColor Gray
Write-Host " كَوْدُ الجِهَازِ:     " -NoNewline -ForegroundColor White
Write-Host "$($DeviceCode.ToUpper())" -ForegroundColor Cyan

Write-Host " كَوْدُ التَّفْعِيلِ:   " -NoNewline -ForegroundColor White
Write-Host "$ActivationKey" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor Gray

# Copy to clipboard if on Windows desktop
try {
    Set-Clipboard -Value $ActivationKey
    Write-Host "✓ تَمَّ نَسْخُ كَوْدِ التَّفْعِيلِ تِلْقَائِيّاً إِلَى الحَافِظَةِ (Clipboard)." -ForegroundColor Green
} catch {}

Write-Host "`nأَرْسِلْ كَوْدَ التَّفْعِيلِ أَعْلاهُ لِلْمُسْتَخْدِمِ لِتَنْشِيطِ البَرْنَامِجِ بَصِفَةٍ دَائِمَةٍ.`n" -ForegroundColor Yellow
