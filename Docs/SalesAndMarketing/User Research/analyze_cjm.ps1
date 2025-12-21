
$path = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv"
$outPath = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\cjm_report.txt"
$enc = [System.Text.Encoding]::GetEncoding(1251)
$lines = [System.IO.File]::ReadAllLines($path, $enc)

$dateFormat = "dd.MM.yyyy HH:mm:ss"
$culture = [System.Globalization.CultureInfo]::InvariantCulture

$leads = @()
$maxDate = [DateTime]::MinValue

$data = $lines | Select-Object -Skip 1
$dt = [DateTime]::MinValue

foreach ($line in $data) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split(';')
    if ($parts.Count -lt 8) { continue } 

    $st = $parts[2].Trim('"')
    $dateStr = $parts[7].Trim('"')
    
    # Try parsing
    if ([DateTime]::TryParseExact($dateStr, $dateFormat, $culture, [System.Globalization.DateTimeStyles]::None, [ref]$dt)) {
        if ($dt -gt $maxDate) { $maxDate = $dt }
        $leads += [PSCustomObject]@{ Status = $st; Date = $dt }
    }
}

$report = [System.Text.StringBuilder]::new()
[void]$report.AppendLine("Max Date in Dataset: $maxDate")
[void]$report.AppendLine("Total Leads with Date: $($leads.Count)")

$statusAge = @{}

foreach ($l in $leads) {
    $ageDays = ($maxDate - $l.Date).TotalDays
    if (-not $statusAge.ContainsKey($l.Status)) { 
        $statusAge[$l.Status] = @{Sum = 0; Count = 0; Ages = @() } 
    }
    $statusAge[$l.Status].Sum += $ageDays
    $statusAge[$l.Status].Count++
    # Add to list for median calc (might be slow for large sets, but 20k is fine)
    $statusAge[$l.Status].Ages += $ageDays
}

[void]$report.AppendLine("`n## Average Lead Age by Status (Days since creation)")
$statusAge.Keys | Sort-Object { ($statusAge[$_].Sum / $statusAge[$_].Count) } | ForEach-Object {
    $avg = [math]::Round($statusAge[$_].Sum / $statusAge[$_].Count, 1)
    
    $sortedAges = $statusAge[$_].Ages | Sort-Object
    $mid = [math]::Floor($sortedAges.Count / 2)
    $median = [math]::Round($sortedAges[$mid], 1)
    
    [void]$report.AppendLine("$_ : Avg=$avg days | Median=$median days | Count=$($statusAge[$_].Count)")
}

$monthlyStats = @{}

foreach ($l in $leads) {
    $monthKey = $l.Date.ToString("yyyy-MM")
    if (-not $monthlyStats.ContainsKey($monthKey)) { $monthlyStats[$monthKey] = @{Total = 0; Statuses = @{} } }
    
    $monthlyStats[$monthKey].Total++
    if (-not $monthlyStats[$monthKey].Statuses.ContainsKey($l.Status)) { $monthlyStats[$monthKey].Statuses[$l.Status] = 0 }
    $monthlyStats[$monthKey].Statuses[$l.Status]++
}

[void]$report.AppendLine("`n## Status Distribution by Monthly Cohort")

$monthlyStats.Keys | Sort-Object | ForEach-Object {
    $m = $_
    $total = $monthlyStats[$m].Total
    [void]$report.AppendLine("`n### Cohort: $m (Total: $total)")
    
    $monthlyStats[$m].Statuses.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object {
        $pct = [math]::Round(($_.Value / $total) * 100, 1)
        [void]$report.AppendLine("- $($_.Key): $pct% ($($_.Value))")
    }
}

[System.IO.File]::WriteAllText($outPath, $report.ToString(), [System.Text.Encoding]::UTF8)
