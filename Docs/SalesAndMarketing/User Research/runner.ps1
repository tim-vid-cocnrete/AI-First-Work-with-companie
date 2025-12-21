
$path = "c:\Code\ai-first-workspace-template-main\Docs\SalesAndMarketing\User Research\analyze_logic.ps1"
$content = Get-Content $path -Encoding UTF8 -Raw
Invoke-Expression $content
