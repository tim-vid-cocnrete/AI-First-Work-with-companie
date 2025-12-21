
$enc = [System.Text.Encoding]::GetEncoding(1251)
$path = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv"
$lines = [System.IO.File]::ReadAllLines($path, $enc)

$stats = @{
    Total       = 0
    Sources     = @{}
    Statuses    = @{}
    Ages        = @{}
    Cities      = @{}
    Techs       = @{}
    Conversions = @{
        Age  = @{}
        City = @{}
        Tech = @{}
    }
}

$techRegex = [regex]"(?i)(Java script|JS|Java|Go|QA|1C|Frontend|Backend|Python)"
$ageRegex = [regex]"(\d{1,2})\s*(?:год|лет|л)"
$citiesRegex = [regex]"(?i)(Москва|Санкт-Петербург|Питер|Казань|Новосибирск|Екатеринбург|Нижний Новгород|Самара|Омск|Челябинск|Ростов|Уфа|Волгоград|Пермь|Красноярск|Воронеж|Саратов|Краснодар|Тольятти|Тюмень|Ижевск|Барнаул|Иркутск|Ульяновск|Хабаровск|Владивосток|Ярославль|Махачкала|Томск|Оренбург|Кемерово|Новокузнецк|Рязань|Астрахань|Набережные Челны|Пенза|Киров|Липецк)"

$cleanedLines = $lines | Select-Object -Skip 1

foreach ($line in $cleanedLines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line.Split(';')
    if ($parts.Count -lt 3) { continue }
    
    $nameField = $parts[0].Trim('"')
    $source = $parts[1].Trim('"')
    $status = $parts[2].Trim('"')
    
    $stats.Total++
    if (-not $stats.Sources.ContainsKey($source)) { $stats.Sources[$source] = 0 }
    $stats.Sources[$source] = [double]$stats.Sources[$source] + 1
    
    if (-not $stats.Statuses.ContainsKey($status)) { $stats.Statuses[$status] = 0 }
    $stats.Statuses[$status] = [double]$stats.Statuses[$status] + 1
    
    $isQualified = ($status -eq "Квалифицирован") -or ($status -eq "Успешная оплата") -or ($status -match "Prepayment") -or ($status -match "Hybrid")
    
    # Age
    $ageMatch = $ageRegex.Match($nameField)
    if ($ageMatch.Success) {
        $age = [int]$ageMatch.Groups[1].Value
        if ($age -ge 16 -and $age -le 60) {
            $ageGroup = ""
            if ($age -lt 20) { $ageGroup = "<20" }
            elseif ($age -le 24) { $ageGroup = "20-24" }
            elseif ($age -le 29) { $ageGroup = "25-29" }
            elseif ($age -le 34) { $ageGroup = "30-34" }
            elseif ($age -le 39) { $ageGroup = "35-39" }
            else { $ageGroup = "40+" }
            
            if (-not $stats.Ages.ContainsKey($ageGroup)) { $stats.Ages[$ageGroup] = 0 }
            $stats.Ages[$ageGroup] = [double]$stats.Ages[$ageGroup] + 1
            
            if (-not $stats.Conversions.Age.ContainsKey($ageGroup)) { $stats.Conversions.Age[$ageGroup] = @{Total = 0; Qualified = 0 } }
            $stats.Conversions.Age[$ageGroup].Total++
            if ($isQualified) { $stats.Conversions.Age[$ageGroup].Qualified++ }
        }
    }
    
    # City
    $cityMatch = $citiesRegex.Match($nameField)
    if ($cityMatch.Success) {
        $city = $cityMatch.Groups[1].Value
        if ($city -match "Питер") { $city = "Санкт-Петербург" }
        
        if (-not $stats.Cities.ContainsKey($city)) { $stats.Cities[$city] = 0 }
        $stats.Cities[$city] = [double]$stats.Cities[$city] + 1
        
        if (-not $stats.Conversions.City.ContainsKey($city)) { $stats.Conversions.City[$city] = @{Total = 0; Qualified = 0 } }
        $stats.Conversions.City[$city].Total++
        if ($isQualified) { $stats.Conversions.City[$city].Qualified++ }
    }
    
    # Tech
    $techMatch = $techRegex.Match($nameField)
    $tech = ""
    if ($techMatch.Success) {
        $tech = $techMatch.Groups[1].Value
        if ($tech -match "Java script|JS") { $tech = "JS/Frontend" }
        if ($tech -eq "Frontend") { $tech = "JS/Frontend" }
        if ($tech -eq "Backend") { $tech = "Java" }
    }
    elseif ($source -match "Java") {
        $tech = "Java" 
    }
    elseif ($source -match "QA") {
        $tech = "QA"
    }
    elseif ($source -match "1C") {
        $tech = "1C"
    }
    elseif ($source -match "Frontend|FE") {
        $tech = "JS/Frontend"
    }
    
    if ($tech -ne "") {
        if (-not $stats.Techs.ContainsKey($tech)) { $stats.Techs[$tech] = 0 }
        $stats.Techs[$tech] = [double]$stats.Techs[$tech] + 1
        
        if (-not $stats.Conversions.Tech.ContainsKey($tech)) { $stats.Conversions.Tech[$tech] = @{Total = 0; Qualified = 0 } }
        $stats.Conversions.Tech[$tech].Total++
        if ($isQualified) { $stats.Conversions.Tech[$tech].Qualified++ }
    }
}

Write-Output "# Analysis Results"
Write-Output "Total Leads: $($stats.Total)"

Write-Output "`n## Age Distribution"
$stats.Ages.GetEnumerator() | Sort-Object Key | Format-Table -AutoSize

Write-Output "`n## Age Conversion (Qualify Rate)"
$stats.Conversions.Age.GetEnumerator() | Sort-Object Key | ForEach-Object {
    $rate = if ($_.Value.Total -gt 0) { [math]::Round(($_.Value.Qualified / $_.Value.Total) * 100, 1) } else { 0 }
    [PSCustomObject]@{AgeGroup = $_.Key; Total = $_.Value.Total; Qualified = $_.Value.Qualified; Rate = "$rate%" }
} | Format-Table -AutoSize

Write-Output "`n## Top Cities"
$stats.Cities.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | Format-Table -AutoSize

Write-Output "`n## Top Cities Conversion"
$stats.Conversions.City.GetEnumerator() | Sort-Object { [int]$_.Value.Total } -Descending | Select-Object -First 20 | ForEach-Object {
    $rate = if ($_.Value.Total -gt 0) { [math]::Round(($_.Value.Qualified / $_.Value.Total) * 100, 1) } else { 0 }
    [PSCustomObject]@{City = $_.Key; Total = $_.Value.Total; Qualified = $_.Value.Qualified; Rate = "$rate%" }
} | Format-Table -AutoSize

Write-Output "`n## Tech Interest"
$stats.Techs.GetEnumerator() | Sort-Object Value -Descending | Format-Table -AutoSize

Write-Output "`n## Top Sources"
$stats.Sources.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | Format-Table -AutoSize

Write-Output "`n## Status Distribution"
$stats.Statuses.GetEnumerator() | Sort-Object Value -Descending | Format-Table -AutoSize
