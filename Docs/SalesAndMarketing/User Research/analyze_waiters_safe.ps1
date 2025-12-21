
$path = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv"
$outPath = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\waiters_report.txt"
$enc = [System.Text.Encoding]::GetEncoding(1251)
$lines = [System.IO.File]::ReadAllLines($path, $enc)

$dateFormat = "dd.MM.yyyy HH:mm:ss"
$culture = [System.Globalization.CultureInfo]::InvariantCulture

$cohorts = @{}

$data = $lines | Select-Object -Skip 1
$dt = [DateTime]::MinValue

# Qual regex: Квалифицирован|Успешная оплата|Prepayment|Hybrid
# Wait regex: В перспективе|Инкубатор
# Lost regex: everything else
# Duplicates: Дубли (\u0414\u0443\u0431\u043b\u0438)

$regexDup = "\u0414\u0443\u0431\u043b\u0438"
$regexQual = "\u041a\u0432\u0430\u043b\u0438\u0444\u0438\u0446\u0438\u0440\u043e\u0432\u0430\u043d|\u0423\u0441\u043f\u0435\u0448\u043d\u0430\u044f|Prepayment|Hybrid"
$regexWait = "\u0412 \u043f\u0435\u0440\u0441\u043f\u0435\u043a\u0442\u0438\u0432\u0435|\u0418\u043d\u043a\u0443\u0431\u0430\u0442\u043e\u0440"

foreach ($line in $data) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split(';')
    if ($parts.Count -lt 8) { continue }

    $st = $parts[2].Trim('"')
    if ($st -match $regexDup) { continue } # Exclude duplicates

    $dateStr = $parts[7].Trim('"')
    
    # Use explicit parsing with ref
    if ([DateTime]::TryParseExact($dateStr, $dateFormat, $culture, [System.Globalization.DateTimeStyles]::None, [ref]$dt)) {
        $m = $dt.ToString("yyyy-MM")
        if (-not $cohorts.ContainsKey($m)) { $cohorts[$m] = @{Total = 0; Qual = 0; Wait = 0; Lost = 0 } }
        
        $cohorts[$m].Total++
        
        if ($st -match $regexQual) {
            $cohorts[$m].Qual++
        }
        elseif ($st -match $regexWait) {
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
