
$path = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv"
$outPath = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\hybrid_cjm_report.txt"
$enc = [System.Text.Encoding]::GetEncoding(1251)
$lines = [System.IO.File]::ReadAllLines($path, $enc)

$dateFormat = "dd.MM.yyyy HH:mm:ss"
$culture = [System.Globalization.CultureInfo]::InvariantCulture

$leads = @()
$maxDate = [DateTime]::MinValue
$dt = [DateTime]::MinValue

$data = $lines | Select-Object -Skip 1

# Extract the marker from a known line (Line 6 in file, index 5 in all lines, or index 4 in $data since skip 1)
# Line 6 in original file is likely index 5 in $lines (0-based)
# Let's verify: $lines[5] should be the one with "Сайт JM Постоплата" based on prev view_file
# Actually line 2 was index 1. Line 6 is index 5.
# Line 6: "ПОЗДНЕЕ ...";"Сайт JM Постоплата";...
$markerLine = $lines[5] 
$markerParts = $markerLine.Split(';')
$markerSource = $markerParts[1].Trim('"') # "Сайт JM Постоплата"
$markerWord = $markerSource.Split(' ')[-1] # Should be "Постоплата"

# Fallback in case line 5 isn't what we expect (though it should be)
if ($markerSource -notmatch " ") {
    $markerWord = $markerSource # Just use the whole thing if no space
}

$report = [System.Text.StringBuilder]::new()
[void]$report.AppendLine("Analysis for Hybrid Funnel")
[void]$report.AppendLine("Extracted Marker from data: $markerWord (Source: $markerSource)")

foreach ($line in $data) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split(';')
    if ($parts.Count -lt 8) { continue } 

    $source = $parts[1].Trim('"')
    
    # Filter using the extracted marker
    if ($source -notmatch [regex]::Escape($markerWord)) { continue }

    $st = $parts[2].Trim('"')
    $dateStr = $parts[7].Trim('"')
    
    # Try parsing
    if ([DateTime]::TryParseExact($dateStr, $dateFormat, $culture, [System.Globalization.DateTimeStyles]::None, [ref]$dt)) {
        if ($dt -gt $maxDate) { $maxDate = $dt }
        
        # Clean status as needed? No, use raw for now.
        $leads += [PSCustomObject]@{ Status = $st; Date = $dt }
    }
}

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

# Cohort analysis (Month of Creation)
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
    
    $monthlyStats[$m].Statuses.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object {
        $pct = [math]::Round(($_.Value / $total) * 100, 1)
        [void]$report.AppendLine("- $($_.Key): $pct% ($($_.Value))")
    }
}

[System.IO.File]::WriteAllText($outPath, $report.ToString(), [System.Text.Encoding]::UTF8)
