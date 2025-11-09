$expectedACLs = @{}
$folders = @(
    "C:\Windows",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData",
    "C:\Users",
    "C:\System Volume Information"
)

$expectedOwners = @{
    "C:\Windows" = "NT SERVICE\TrustedInstaller"
    "C:\Program Files" = "NT SERVICE\TrustedInstaller"
    "C:\Program Files (x86)" = "NT SERVICE\TrustedInstaller"
    "C:\ProgramData" = "NT AUTHORITY\SYSTEM"
    "C:\Users" = "NT AUTHORITY\SYSTEM"
    "C:\System Volume Information" = "NT AUTHORITY\SYSTEM"
}

$expectedACLs = @{
    "C:\Windows" = @(
        @{ Identity = "NT AUTHORITY\SYSTEM"; Rights = "FullControl" },
        @{ Identity = "BUILTIN\Administrators"; Rights = "FullControl" },
        @{ Identity = "BUILTIN\Users"; Rights = "ReadAndExecute" },
        @{ Identity = "NT SERVICE\TrustedInstaller"; Rights = "FullControl" },
        @{ Identity = "APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES"; Rights = "ReadAndExecute" },
        @{ Identity = "APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES"; Rights = "ReadAndExecute" }
    )
    "C:\Program Files" = $expectedACLs["C:\Windows"]
    "C:\Program Files (x86)" = $expectedACLs["C:\Windows"]
    "C:\ProgramData" = @(
        @{ Identity = "NT AUTHORITY\SYSTEM"; Rights = "FullControl" },
        @{ Identity = "BUILTIN\Administrators"; Rights = "FullControl" },
        @{ Identity = "BUILTIN\Users"; Rights = "ReadAndExecute" }
    )
    "C:\Users" = @(
        @{ Identity = "NT AUTHORITY\SYSTEM"; Rights = "FullControl" },
        @{ Identity = "BUILTIN\Administrators"; Rights = "FullControl" },
        @{ Identity = "BUILTIN\Users"; Rights = "ReadAndExecute" },
        @{ Identity = "Everyone"; Rights = "ReadAndExecute" }
    )
}

$reportPath = "$env:USERPROFILE\Desktop\Raport_Uprawnienia.txt"
"Raport porównania uprawnień - $(Get-Date)" | Out-File $reportPath

echo "🔍 Rozpoczynam analizę folderów względem standardowego wzorca uprawnień..."
pause


foreach ($folder in $folders) {
    echo "`n📁 Sprawdzam: $folder"
    pause

    try {
        $acl = Get-Acl -Path $folder
        $owner = $acl.Owner
        $lines = @()
        $lines += "----------------------------------------"
        $lines += "Folder: $folder"
        $lines += "Właściciel: $owner"

        if ($expectedOwners[$folder] -and $owner -ne $expectedOwners[$folder]) {
            $lines += "⚠️ UWAGA: Niewłaściwe uprawnienia właściciela! Oczekiwano: $($expectedOwners[$folder])"
        }

        $actualACLs = @{}
        foreach ($access in $acl.Access) {
            $identity = $access.IdentityReference.Value
            $rights = $access.FileSystemRights.ToString()
            if (($access.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::FullControl) -ne 0) {
    # ma FullControl
}
            $actualACLs[$identity] = $rights
            $entry = "→ ${identity}: ${rights} | Dziedziczenie: $($access.IsInherited)"
            $lines += $entry

            if ($identity -like "*S-1-*") {
                $lines += "⚠️ Nieznany SID: $identity"
            }

            if ($identity -eq "Everyone" -and $rights -like "*FullControl*") {
                $lines += "⚠️ Everyone ma FullControl!"
            }
        }

        if ($expectedACLs.ContainsKey($folder)) {
            foreach ($expected in $expectedACLs[$folder]) {
                $id = $expected.Identity
                $expectedRights = $expected.Rights
                if ($actualACLs.ContainsKey($id)) {
                    if ($actualACLs[$id] -notlike "*$expectedRights*") {
                        $lines += "⚠️ $id nie ma domyślnych uprawnień dostępu, możliwe problemy!  ($expectedRights)"
                    }
                } else {
                    $lines += "⚠️ Brak wpisu ACL dla $id (oczekiwano: $expectedRights)"
                }
            }
        }

        $lines | Out-File -Append $reportPath
    } catch {
        "❌ Brak dostępu do $folder — uruchom jako administrator" | Out-File -Append $reportPath
    }
}

echo "`n✅ Analiza zakończona. Raport uprawnień do folderów systemowych zapisany w pliku LOG: $reportPath"
pause
