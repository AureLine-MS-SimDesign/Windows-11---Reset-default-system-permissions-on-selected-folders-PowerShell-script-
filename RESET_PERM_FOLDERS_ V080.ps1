Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework

# 📁 Wybór folderów przez GUI
$selectedFolders = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Podaj ścieżkę folderu lub folderów oddzielonych znakiem średnika, by przywrócić podstawowe uprawnienia dostępu", 
    "Wpisz ścieżkę do folderu/folderów", 
    ""
)

# Rozdziel na listę
$folderList = $selectedFolders -split ";" | Where-Object { $_.Trim() -ne "" }

# Jeśli nic nie podano
if ($folderList.Count -eq 0) {
    Write-Host "❌ Nie podano żadnych folderów. Zakończono." -ForegroundColor Red
    return
}

# 📋 Potwierdzenie
Write-Host "`n📂 Foldery do przywrócenia podstawowych uprawnień dostępu:"
$folderList | ForEach-Object { Write-Host " - $_" }

$confirmation = Read-Host "`n❓ Czy na pewno rozpocząć przywracanie uprawnień dla wybranych folderów? (T/Y = Tak, N = Nie)"
if ($confirmation -notin @("T", "t", "Y", "y")) {
    Write-Host "🔁 Możesz teraz ponownie uruchomić skrypt i podać inne foldery." -ForegroundColor Cyan
    return
}

# 📄 Plik logu
$logPath = "$env:USERPROFILE\icacls_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -Path $logPath -ItemType File -Force | Out-Null

# 🔄 Przywracanie uprawnień dostępu...
foreach ($folder in $folderList) {
    Write-Host "`n🔧 Przetwarzanie: $folder"
    Add-Content -Path $logPath -Value "`n=== Folder: $folder ==="

    $items = Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { -not ($_.Attributes -match "ReparsePoint") }

    # Dodaj folder główny
    $items += Get-Item -Path $folder

    foreach ($item in $items) {
        try {
            icacls $item.FullName /reset /C /Q /L | Out-Null
            Add-Content -Path $logPath -Value "✔️ OK: $($item.FullName)"
        } catch {
            Add-Content -Path $logPath -Value "❌ Błąd: $($item.FullName)"
        }
    }
}

Write-Host "`n✅ Zakończono pomyślnie. Plik LOG z przebiegiem operacji zapisano do: $logPath" -ForegroundColor Green
[System.Windows.MessageBox]::Show("Wciśnij OK by zakończyć działanie skryptu.")