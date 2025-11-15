# PowerShell script to generate Android keystore with predefined configuration
# Usage: .\generate-keystore.ps1

# Load configuration from keystore-config.env
$configFile = Join-Path $PSScriptRoot "keystore-config.env"

if (-not (Test-Path $configFile)) {
    Write-Host "Error: keystore-config.env not found!" -ForegroundColor Red
    Write-Host "Please create keystore-config.env file first." -ForegroundColor Yellow
    exit 1
}

# Parse configuration file
$config = @{}
Get-Content $configFile | ForEach-Object {
    $line = $_.Trim()
    # Skip empty lines and comments
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Count -eq 2) {
            $config[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

# Validate required parameters
$required = @("KEYSTORE_FILE", "KEY_ALIAS", "KEYSTORE_PASSWORD", "KEY_PASSWORD", 
              "DN_NAME", "DN_OU", "DN_O", "DN_L", "DN_ST", "DN_C", "VALIDITY")

foreach ($param in $required) {
    if (-not $config.ContainsKey($param)) {
        Write-Host "Error: Missing required parameter: $param" -ForegroundColor Red
        exit 1
    }
}

# Build Distinguished Name (DN)
$dn = "CN=$($config['DN_NAME']), OU=$($config['DN_OU']), O=$($config['DN_O']), " +
      "L=$($config['DN_L']), ST=$($config['DN_ST']), C=$($config['DN_C'])"

# Check if keystore already exists
$keystorePath = Join-Path $PSScriptRoot $config['KEYSTORE_FILE']
if (Test-Path $keystorePath) {
    Write-Host "Warning: Keystore file already exists: $keystorePath" -ForegroundColor Yellow
    $response = Read-Host "Do you want to overwrite it? (yes/no)"
    if ($response -ne "yes") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $keystorePath -Force
}

Write-Host "Generating keystore..." -ForegroundColor Green
Write-Host "Keystore file: $($config['KEYSTORE_FILE'])" -ForegroundColor Cyan
Write-Host "Key alias: $($config['KEY_ALIAS'])" -ForegroundColor Cyan
Write-Host "DN: $dn" -ForegroundColor Cyan

# Create temporary batch file with passwords
$batchFile = Join-Path $env:TEMP "keytool_input.txt"
@"
$($config['KEYSTORE_PASSWORD'])
$($config['KEYSTORE_PASSWORD'])
$($config['KEY_PASSWORD'])
"@ | Out-File -FilePath $batchFile -Encoding ASCII

try {
    # Generate keystore
    $keytoolCmd = "keytool -genkey -v " +
                  "-keystore `"$keystorePath`" " +
                  "-alias $($config['KEY_ALIAS']) " +
                  "-keyalg RSA " +
                  "-keysize 2048 " +
                  "-validity $($config['VALIDITY']) " +
                  "-dname `"$dn`" " +
                  "-storepass $($config['KEYSTORE_PASSWORD']) " +
                  "-keypass $($config['KEY_PASSWORD'])"
    
    Invoke-Expression $keytoolCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nKeystore generated successfully!" -ForegroundColor Green
        Write-Host "Location: $keystorePath" -ForegroundColor Cyan
        
        # Verify keystore
        Write-Host "`nVerifying keystore..." -ForegroundColor Yellow
        keytool -list -v -keystore "$keystorePath" -storepass $($config['KEYSTORE_PASSWORD'])
        
        Write-Host "`n=== Next Steps ===" -ForegroundColor Green
        Write-Host "1. Add GitHub Secrets (Settings > Secrets and variables > Actions):" -ForegroundColor Yellow
        Write-Host "   - KEYSTORE_PASSWORD: $($config['KEYSTORE_PASSWORD'])" -ForegroundColor White
        Write-Host "   - KEY_PASSWORD: $($config['KEY_PASSWORD'])" -ForegroundColor White
        Write-Host "   - KEY_ALIAS: $($config['KEY_ALIAS'])" -ForegroundColor White
        Write-Host "`n2. Generate KEYSTORE_BASE64 secret:" -ForegroundColor Yellow
        Write-Host "   Run: [Convert]::ToBase64String([IO.File]::ReadAllBytes('$keystorePath')) | Set-Clipboard" -ForegroundColor White
        Write-Host "   Then paste from clipboard to GitHub Secret" -ForegroundColor White
        Write-Host "`n3. IMPORTANT: Keep keystore-config.env and upload-keystore.jks secure!" -ForegroundColor Red
        Write-Host "   These files should NEVER be committed to Git." -ForegroundColor Red
    } else {
        Write-Host "`nError: Keystore generation failed!" -ForegroundColor Red
        exit 1
    }
} finally {
    # Clean up temporary file
    if (Test-Path $batchFile) {
        Remove-Item $batchFile -Force
    }
}
