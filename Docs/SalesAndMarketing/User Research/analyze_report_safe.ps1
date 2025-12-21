
$path = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\Leads June-October.csv"
$outPath = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\report.txt"
$enc = [System.Text.Encoding]::GetEncoding(1251)
$lines = [System.IO.File]::ReadAllLines($path, $enc)

$statsTotal = 0
$statsSources = @{}
$statsStatuses = @{}
$statsAges = @{}
$statsCities = @{}
$statsTechs = @{}

# Regexes in Unicode Literal format to assume ASCII script file
# лет = \u043b\u0435\u0442
# год = \u0433\u043e\u0434
$regexAge = "(\d{1,2})\s*(?:[\u043b\u0435\u0442]|[\u0433\u043e\u0434])"

# Cities
# Moscow = \u041c\u043e\u0441\u043a\u0432\u0430
# SPb = \u0421\u0430\u043d\u043a\u0442-\u041f\u0435\u0442\u0435\u0440\u0431\u0443\u0440\u0433
# Piter (slang) = \u041f\u0438\u0442\u0435\u0440
# Kazan = \u041a\u0430\u0437\u0430\u043d\u044c
# Novosibirsk = \u041d\u043e\u0432\u043e\u0441\u0438\u0431\u0438\u0440\u0441\u043a
# Krasnodar = \u041a\u0440\u0430\u0441\u043d\u043e\u0434\u0430\u0440
# Yekaterinburg = \u0415\u043a\u0430\u0442\u0435\u0440\u0438\u043d\u0431\u0443\u0440\u0433
$regexCities = "(?i)(\u041c\u043e\u0441\u043a\u0432\u0430|\u0421\u0430\u043d\u043a\u0442-\u041f\u0435\u0442\u0435\u0440\u0431\u0443\u0440\u0433|\u041f\u0438\u0442\u0435\u0440|\u041a\u0430\u0437\u0430\u043d\u044c|\u041d\u043e\u0432\u043e\u0441\u0438\u0431\u0438\u0440\u0441\u043a|\u041a\u0440\u0430\u0441\u043d\u043e\u0434\u0430\u0440|\u0415\u043a\u0430\u0442\u0435\u0440\u0438\u043d\u0431\u0443\u0440\u0433)"

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

    # Age extraction
    if ($name -match $regexAge) {
        $a = [int]$matches[1]
        if ($a -ge 16 -and $a -le 60) {
            $ag = "40+"
            if ($a -lt 20) { $ag = "<20" }
            elseif ($a -le 24) { $ag = "20-24" }
            elseif ($a -le 29) { $ag = "25-29" }
            elseif ($a -le 34) { $ag = "30-34" }
            elseif ($a -le 39) { $ag = "35-39" }
           
            if (-not $statsAges.ContainsKey($ag)) { $statsAges[$ag] = 0 }
            $statsAges[$ag] = [double]$statsAges[$ag] + 1
        }
    }
    
    # City extraction
    if ($name -match $regexCities) {
        $c = $matches[1]
        # Normalize Piter
        if ($c -match "\u041f\u0438\u0442\u0435\u0440") { $c = "SPb" } # Output ASCII for safety
        elseif ($c -match "\u0421\u0430\u043d\u043a\u0442") { $c = "SPb" }
        elseif ($c -match "\u041c\u043e\u0441\u043a\u0432\u0430") { $c = "Moscow" }
        elseif ($c -match "\u041a\u0430\u0437\u0430\u043d\u044c") { $c = "Kazan" }
        elseif ($c -match "\u041d\u043e\u0432\u043e\u0441\u0438\u0431\u0438\u0440\u0441\u043a") { $c = "Novosibirsk" }
        elseif ($c -match "\u041a\u0440\u0430\u0441\u043d\u043e\u0434\u0430\u0440") { $c = "Krasnodar" }
        elseif ($c -match "\u0415\u043a\u0430\u0442\u0435\u0440\u0438\u043d\u0431\u0443\u0440\u0433") { $c = "Ekb" }
        
        if (-not $statsCities.ContainsKey($c)) { $statsCities[$c] = 0 }
        $statsCities[$c] = [double]$statsCities[$c] + 1
    }
    
    # Tech
    $foundTech = ""
    if ($name -match "JS|Frontend|Java script") { $foundTech = "JS" }
    elseif ($name -match "Java|Backend") { $foundTech = "Java" }
    elseif ($name -match "Go|Golang") { $foundTech = "Go" }
    elseif ($name -match "QA") { $foundTech = "QA" }
    elseif ($name -match "1C") { $foundTech = "1C" }
    
    if ($foundTech -eq "") {
        if ($src -match "Java") { $foundTech = "Java" }
        elseif ($src -match "QA") { $foundTech = "QA" }
        elseif ($src -match "1C") { $foundTech = "1C" }
        elseif ($src -match "Frontend|FE") { $foundTech = "JS" }
        elseif ($src -match "Go") { $foundTech = "Go" }
    }
    
    if ($foundTech -ne "") {
        if (-not $statsTechs.ContainsKey($foundTech)) { $statsTechs[$foundTech] = 0 }
        $statsTechs[$foundTech] = [double]$statsTechs[$foundTech] + 1
    }
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("Total Leads: $statsTotal")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Sources:")
foreach ($k in $statsSources.Keys) { [void]$sb.AppendLine("$k : $($statsSources[$k])") }

[void]$sb.AppendLine("")
[void]$sb.AppendLine("Statuses:")
foreach ($k in $statsStatuses.Keys) { [void]$sb.AppendLine("$k : $($statsStatuses[$k])") }

[void]$sb.AppendLine("")
[void]$sb.AppendLine("Ages:")
foreach ($k in $statsAges.Keys) { [void]$sb.AppendLine("$k : $($statsAges[$k])") }

[void]$sb.AppendLine("")
[void]$sb.AppendLine("Cities:")
foreach ($k in $statsCities.Keys) { [void]$sb.AppendLine("$k : $($statsCities[$k])") }

[void]$sb.AppendLine("")
[void]$sb.AppendLine("Techs:")
foreach ($k in $statsTechs.Keys) { [void]$sb.AppendLine("$k : $($statsTechs[$k])") }

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
