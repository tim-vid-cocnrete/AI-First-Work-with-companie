
$files = Get-ChildItem "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv"
$enc = [System.Text.Encoding]::GetEncoding(1251)
if ($files.Count -eq 0) { Write-Error "File not found"; exit }
$lines = [System.IO.File]::ReadAllLines($files[0].FullName, $enc)

$statsTotal = 0
$statsSources = @{}
$statsStatuses = @{}
$statsAges = @{}
$statsCities = @{}
$statsTechs = @{}

$regexJS = "Java script|JS|Frontend"
$regexJava = "Java|Backend"
$regexGo = "Go"
$regexQA = "QA"
$regex1C = "1C"

# Clean header
$data = $lines | Select-Object -Skip 1

foreach ($line in $data) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split(';')
    if ($parts.Count -lt 3) { continue }

    $name = $parts[0].Trim('"')
    $src = $parts[1].Trim('"')
    $st = $parts[2].Trim('"')

    $statsTotal++
    
    if (-not $statsSources.ContainsKey($src)) { $statsSources[$src] = 0 }
    $statsSources[$src] = [double]$statsSources[$src] + 1

    if (-not $statsStatuses.ContainsKey($st)) { $statsStatuses[$st] = 0 }
    $statsStatuses[$st] = [double]$statsStatuses[$st] + 1

    # Age
    if ($name -match "(\d{1,2})\s*(?:год|лет|л)") {
        $age = [int]$matches[1]
        if ($age -ge 16 -and $age -le 60) {
            $grp = "40+"
            if ($age -lt 20) { $grp = "<20" }
            elseif ($age -le 24) { $grp = "20-24" }
            elseif ($age -le 29) { $grp = "25-29" }
            elseif ($age -le 34) { $grp = "30-34" }
            elseif ($age -le 39) { $grp = "35-39" }
           
            if (-not $statsAges.ContainsKey($grp)) { $statsAges[$grp] = 0 }
            $statsAges[$grp] = [double]$statsAges[$grp] + 1
        }
    }

    # City (Simplified regex to match common ones)
    if ($name -match "(?i)(Москва|Санкт-Петербург|Питер|Казань|Новосибирск|Екатеринбург|Уфа|Волгоград|Пермь|Краснодар|Тюмень|Минск|Алматы|Ташкент)") {
        $city = $matches[1]
        if ($city -match "Питер") { $city = "Санкт-Петербург" }
        if (-not $statsCities.ContainsKey($city)) { $statsCities[$city] = 0 }
        $statsCities[$city] = [double]$statsCities[$city] + 1
    }

    # Tech
    $foundTech = ""
    if ($name -match $regexJS) { $foundTech = "JS/Frontend" }
    elseif ($name -match $regexJava) { $foundTech = "Java" }
    elseif ($name -match $regexGo) { $foundTech = "Go" }
    elseif ($name -match $regexQA) { $foundTech = "QA" }
    elseif ($name -match $regex1C) { $foundTech = "1C" }
    
    if ($foundTech -eq "") {
        if ($src -match "Java") { $foundTech = "Java" }
        elseif ($src -match "QA") { $foundTech = "QA" }
        elseif ($src -match "1C") { $foundTech = "1C" }
        elseif ($src -match "Frontend|FE") { $foundTech = "JS/Frontend" }
    }

    if ($foundTech -ne "") {
        if (-not $statsTechs.ContainsKey($foundTech)) { $statsTechs[$foundTech] = 0 }
        $statsTechs[$foundTech] = [double]$statsTechs[$foundTech] + 1
    }
}

Write-Output "Total: $statsTotal"
Write-Output "`n-- AGE --"
$statsAges.GetEnumerator() | Sort-Object Key | Format-Table -AutoSize
Write-Output "`n-- TECH --"
$statsTechs.GetEnumerator() | Sort-Object Value -Descending | Format-Table -AutoSize
Write-Output "`n-- CITY --"
$statsCities.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | Format-Table -AutoSize
Write-Output "`n-- SOURCE --"
$statsSources.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | Format-Table -AutoSize
Write-Output "`n-- STATUS --"
$statsStatuses.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | Format-Table -AutoSize
