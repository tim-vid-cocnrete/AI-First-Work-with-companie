
$path = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv"
$outPath = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\sources_report.txt"
$enc = [System.Text.Encoding]::GetEncoding(1251)
$lines = [System.IO.File]::ReadAllLines($path, $enc)

$sources = @{}
$statuses = @{}

$data = $lines | Select-Object -Skip 1

foreach ($line in $data) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split(';')
    if ($parts.Count -lt 3) { continue }

    $source = $parts[1].Trim('"')
    $status = $parts[2].Trim('"')

    if (-not $sources.ContainsKey($source)) { $sources[$source] = 0 }
    $sources[$source]++

    if (-not $statuses.ContainsKey($status)) { $statuses[$status] = 0 }
    $statuses[$status]++
}

$report = [System.Text.StringBuilder]::new()
[void]$report.AppendLine("Unique Sources:")
$sources.Keys | Sort-Object | ForEach-Object {
    [void]$report.AppendLine("$_ ($($sources[$_]))")
}

[void]$report.AppendLine("`nUnique Statuses:")
$statuses.Keys | Sort-Object | ForEach-Object {
    [void]$report.AppendLine("$_ ($($statuses[$_]))")
}

[System.IO.File]::WriteAllText($outPath, $report.ToString(), [System.Text.Encoding]::UTF8)
