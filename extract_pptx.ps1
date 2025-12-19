# Получаем файл .pptx
$pptxFile = Get-ChildItem -Path "c:\Code\ai-first-workspace-template-main\Courses Presentations" -Filter "*.pptx" | Select-Object -First 1

if ($pptxFile) {
    Write-Host "Найден файл: $($pptxFile.Name)"
    
    $ppt = New-Object -ComObject PowerPoint.Application
    $allText = ""
    
    try {
        $presentation = $ppt.Presentations.Open($pptxFile.FullName, $true, $true, $false)
        
        Write-Host "Презентация открыта. Количество слайдов: $($presentation.Slides.Count)"
        
        foreach ($slide in $presentation.Slides) {
            $allText += "--- Слайд $($slide.SlideIndex) ---`r`n"
            
            foreach ($shape in $slide.Shapes) {
                if ($shape.HasTextFrame -eq -1) {
                    if ($shape.TextFrame.HasText -eq -1) {
                        $text = $shape.TextFrame.TextRange.Text
                        if ($text) {
                            $allText += $text + "`r`n"
                        }
                    }
                }
            }
            $allText += "`r`n"
        }
        
        # Сохраняем в файл
        $outputPath = "c:\Code\ai-first-workspace-template-main\java_senior_extracted.txt"
        $allText | Out-File -FilePath $outputPath -Encoding UTF8
        Write-Host "Текст сохранен в: $outputPath"
        
        $presentation.Close()
    }
    catch {
        Write-Host "Ошибка: $_"
    }
    finally {
        $ppt.Quit()
        Start-Sleep -Milliseconds 500
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}
else {
    Write-Host "Файл .pptx не найден"
}
