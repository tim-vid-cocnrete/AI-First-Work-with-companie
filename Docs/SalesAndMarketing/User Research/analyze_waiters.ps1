
$path = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv"
$outPath = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\waiters_report.txt"
$enc = [System.Text.Encoding]::GetEncoding(1251)
$lines = [System.IO.File]::ReadAllLines($path, $enc)

$dateFormat = "dd.MM.yyyy HH:mm:ss"
$culture = [System.Globalization.CultureInfo]::InvariantCulture

$cohorts = @{}

$data = $lines | Select-Object -Skip 1
$dt = [DateTime]::MinValue

foreach ($line in $data) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split(';')
    if ($parts.Count -lt 8) { continue }

    $st = $parts[2].Trim('"')
    if ($st -eq "Дубли") { continue } # Exclude duplicates for clean analysis

    $dateStr = $parts[7].Trim('"')
    
    if ([DateTime]::TryParseExact($dateStr, $dateFormat, $culture, [System.Globalization.DateTimeStyles]::None, [ref]$dt)) {
        $m = $dt.ToString("yyyy-MM")
        if (-not $cohorts.ContainsKey($m)) { $cohorts[$m] = @{Total = 0; Qual = 0; Wait = 0; Lost = 0 } }
        
        $cohorts[$m].Total++
        
        if ($st -match "Квалифицирован|Успешная оплата|Prepayment|Hybrid") {
            $cohorts[$m].Qual++
        }
        elseif ($st -match "В перспективе|Инкубатор") {
            $cohorts[$m].Wait++
        }
        else {
            $cohorts[$m].Lost++
        }
    }
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("Month | Total | Qual % | Wait % | Lost %")
[void]$sb.AppendLine("----- | ----- | ------ | ------ | ------")

$cohorts.Keys | Sort-Object | ForEach-Object {
    $m = $_
    $t = $cohorts[$m].Total
    if ($t -gt 0) {
        $q = [math]::Round(($cohorts[$m].Qual / $t) * 100, 1)
        $w = [math]::Round(($cohorts[$m].Wait / $t) * 100, 1)
        $l = [math]::Round(($cohorts[$m].Lost / $t) * 100, 1)
        [void]$sb.AppendLine("$m | $t | $q% | $w% | $l%")
    }
}

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
