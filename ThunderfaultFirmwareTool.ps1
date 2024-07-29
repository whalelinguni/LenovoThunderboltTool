<# 

 _____  _                    _            ___  ___  _   _  _     _____ 
|_   _|| |_   _  _  _ _   __| | ___  _ _ | __|/   \| | | || |   |_   _|
  | |  |   \ | || || ' \ / _` |/ -_)| '_|| _| | - || |_| || |__   | |  
  |_|  |_||_| \_._||_||_|\__/_|\___||_|  |_|  |_|_| \___/ |____|  |_|  


#>

# File: ThunderboltOperations.ps1

$origFC = $host.UI.RawUI.ForegroundColor
$origBC = $host.UI.RawUI.BackgroundColor
$scriptDir = $PWD
$tmpDir = Join-Path -Path $scriptDir -ChildPath "tmp"
$binDir = Join-Path -Path $scriptDir -ChildPath "bin"
$downloadDir = Join-Path -Path $scriptDir -ChildPath "downloads"

function Check-RequiredFiles {
    $requiredFiles = @("Lenovo.Driver.Manager.exe")
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path -Path $binDir -ChildPath $file
        if (-Not (Test-Path $filePath)) {
            Write-Error "Required file not found: $filePath"
            exit
        }
    }
}

function Write-HyphenToEnd {
    $consoleWidth = [Console]::WindowWidth
    Write-Output ""
    Write-Output ("-" * $consoleWidth)
    Write-Output ""
}

function Pad-FirmwareTo1MB {
    [CmdletBinding()]
    param (
        [string]$TargetSize = 1048576  # Default target size: 1 MB (1048576 bytes)
    )
    
    Add-Type -AssemblyName System.Windows.Forms

    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.InitialDirectory = $scriptDir
    $fileDialog.Filter = "All files (*.*)|*.*"
    $fileDialog.Title = "Select the file to pad"

    if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $inputFile = $fileDialog.FileName
    } else {
        Write-Output "File selection cancelled."
        return
    }

    $outputFile = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($inputFile), "TBT_padded.bin")

    if (-Not (Test-Path $inputFile)) {
        Write-Error "Input file not found: $inputFile"
        return
    }

    $inputFileSize = (Get-Item $inputFile).length

    if ($inputFileSize -ge $TargetSize) {
        Copy-Item -Path $inputFile -Destination $outputFile
        Write-Output "Input file is already larger than or equal to the target size. Copied to $outputFile."
        return
    }

    $bytesToAdd = $TargetSize - $inputFileSize

    $fileBytes = [System.IO.File]::ReadAllBytes($inputFile)
    $paddedBytes = New-Object byte[] $TargetSize
    [Array]::Copy($fileBytes, $paddedBytes, $inputFileSize)
    [System.IO.File]::WriteAllBytes($outputFile, $paddedBytes)

    Write-Output "Padded file created: $outputFile"
	Read-Host "Press for menu going back to return."
}

function Show-InitialInfo {
    cls
    Write-Host "#####################################################################################"
    Write-Host ""
    Write-Host "                         Thinkpad Thunderbolt Firmware Tool" -ForegroundColor Yellow
    Write-Host "                                                                  --Whale Linguini"
    Write-Host "#####################################################################################"
    Write-Output "Loading...."
    Write-Host ""
    
    (Invoke-WebRequest "https://raw.githubusercontent.com/lptstr/winfetch/master/winfetch.ps1" -UseBasicParsing).Content.Remove(0,1) | Invoke-Expression
    
    Write-Output ""
    $biosSerialNumber = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber
    $biosSerialNumberCIM = Get-CimInstance win32_bios | Select-Object -ExpandProperty SerialNumber
    Write-Host "                                        [ -- System Serial -- ]" 
    Write-Output "                                        BIOS Serial Number: $biosSerialNumber"
    Write-Output "                                        BIOS Serial Number (CIM): $biosSerialNumberCIM"
    Write-Output ""
    Write-Host "                                        [ -- System Thunderbolt -- ]"
    $thunderboltDriverVersion = (Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "Thunderbolt*" }).driverversion
    Write-Output "                                        Thunderbolt Controller Driver Version: $thunderboltDriverVersion"
    $thunderboltFirmwareVersion = (Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -like "*Thunderbolt*" }).DriverVersion
    Write-Output "                                        Thunderbolt Firmware Version: $thunderboltFirmwareVersion"
    Write-Output ""
}

$splashExit0=@"

 __   __ _______ __   __ __   __ _______    _______ _______ _______ __    _                
|  | |  |       |  | |  |  | |  |       |  |  _    |       |       |  |  | |               
|  |_|  |   _   |  | |  |  |_|  |    ___|  | |_|   |    ___|    ___|   |_| |               
|       |  | |  |  |_|  |       |   |___   |       |   |___|   |___|       |               
|_     _|  |_|  |       |       |    ___|  |  _   ||    ___|    ___|  _    |___  ___  ___  
  |   | |       |       ||     ||   |___   | |_|   |   |___|   |___| | |   |   ||   ||   | 
  |___| |_______|_______| |___| |_______|  |_______|_______|_______|_|  |__|___||___||___| 

"@

$splashExit1=@"
___________/\                      ___               _____              __               ____ 
\__    ___/  |__  __ __  ____   __| _/ ____ ________/ ____\__ __  ____ |  | __ ____   __| _/ |
  |    |  |  |  \|  |  \/    \ / __ |_/ __ \\_  __ \   __\|  |  \/ ___\|  |/ // __ \ / __ || |
  |    |  |      \  |  /   |  \ /_/ |\  ___/_|  | \/|  |  |  |  /  \___|    \\  ___/_ /_/ | \|
  |____|  |___|  /____/|___|  /____ | \___  /|__|   |_ |  |____/ \___  /__|_ \\___  /____ | __
               \/           \/     \/     \/          \/             \/     \/    \/     \/ \/

"@



function Extract-Installer {
    param (
        [string]$scriptDir
    )

    # Define the paths
    $tmpDir = "$scriptDir\tmp"
    $downloadsDir = "$scriptDir\downloads"
    $binDir = "$scriptDir\bin"
    $innounpExe = "$binDir\innounp.exe"
    $extractedDirPath = "$scriptDir\Extracted"
    
    $factory_foreground = (Get-Host).UI.RawUI.ForegroundColor
    $factory_background = (Get-Host).UI.RawUI.BackgroundColor

    # Function to open a file browser and prompt the user to select the installer EXE
    function Get-InstallerExe {
        Add-Type -AssemblyName System.Windows.Forms
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.InitialDirectory = $scriptDir
        $OpenFileDialog.Filter = "Executable Files (*.exe)|*.exe"
        $OpenFileDialog.Title = "Select the Installer EXE"
        $OpenFileDialog.ShowDialog() | Out-Null
        return $OpenFileDialog.FileName
    }

    # Get the installer EXE path from the user
    $installerExe = Get-InstallerExe

    # Check if the installer EXE was selected
    if (-not [string]::IsNullOrEmpty($installerExe)) {
        Write-Host "Installer EXE selected: $installerExe" -Verbose

        # Ensure the tmp directory exists
        if (-not (Test-Path -Path $tmpDir)) {
            New-Item -Path $tmpDir -ItemType Directory | Out-Null
        }

        # Ensure the extracted directory exists
        if (-not (Test-Path -Path $extractedDirPath)) {
            New-Item -Path $extractedDirPath -ItemType Directory | Out-Null
            Write-Host "Created extracted directory: $extractedDirPath" -Verbose
        }

        # Move the installer EXE to the tmp directory
        $installerExeName = [System.IO.Path]::GetFileName($installerExe)
        Move-Item -Path "$installerExe" -Destination "$tmpDir" -Force

        # Ensure the innounp.exe exists in the bin directory
        if (-not (Test-Path -Path $innounpExe)) {
            Write-Host "innounp.exe not found in $binDir" -Verbose
            exit 1
        }

        # Copy 'innounp.exe' from the bin directory to the tmp directory
        Copy-Item -Path "$innounpExe" -Destination "$tmpDir" -Force

        # Change to the tmp directory
        Set-Location -Path "$tmpDir"

        # Extract the installer using innounp.exe
        Write-Host ""
        $Host.UI.RawUI.ForegroundColor = "Green"
        Write-Host "    Extracted Files"
        Write-Host "-------------------------------------------------"
        & "$tmpDir\innounp.exe" -x "$tmpDir\$installerExeName"
        $Host.UI.RawUI.ForegroundColor = $factory_foreground
        Write-Host ""

        # Introduce a delay to ensure extraction is complete
        Start-Sleep -Seconds 2

        # Get the extracted directory name
        $extractedDir = Get-Item -Path "$tmpDir\{code_GetExtractPath_}" -ErrorAction SilentlyContinue

        if ($extractedDir) {
            # Define the new directory name
            $newDirName = "${installerExeName}_extracted"
            $destinationDir = "$extractedDirPath\$newDirName"

            # Check if the destination directory already exists
            if (Test-Path -Path $destinationDir) {
                $response = Read-Host "Directory $newDirName already exists. Do you want to overwrite it? (Y/N)"
                if ($response -eq 'Y' -or $response -eq 'y') {
                    Remove-Item -Path "$destinationDir" -Recurse -Force
                    Write-Host "Removed directory: $destinationDir" -Verbose
                } else {
                    Write-Host "Did not overwrite existing directory: $destinationDir" -Verbose
                    exit
                }
            }

            # Rename the extracted directory
            Rename-Item -Path "$extractedDir" -NewName "$newDirName"

            # Move the renamed directory to the Extracted directory
            Move-Item -Path "$tmpDir\$newDirName" -Destination "$extractedDirPath"

            # Move the installer EXE to the root of the extracted directory
            Move-Item -Path "$tmpDir\$installerExeName" -Destination "$extractedDirPath\$newDirName" -Force
        } else {
            Write-Host "Extraction failed or the extracted directory not found." -Verbose
        }

        # Change back to the script directory
        Set-Location -Path "$scriptDir"

        Write-Host "Cleaning Up ..."
        # Cleanup
        try {
            Remove-Item -Path "$tmpDir" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$downloadsDir" -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Failed to delete tmp directory: $tmpDir. Error: $_" -Verbose
        }
    } else {
        Write-Host "No installer EXE was selected." -Verbose
    }

    Write-Host "Extraction process completed." -Verbose
    Write-Host ""
    Write-Host "You have done! Good You!"
    Read-Host "Press f13 to menu."
}

function Run-LenovoDriverManager {
    Add-Type -AssemblyName System.Windows.Forms

    $biosSerialNumber = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber

    $form = New-Object Windows.Forms.Form -Property @{
        Text = "BIOS Serial Number"
        Size = New-Object Drawing.Size(600,200)
        StartPosition = "CenterScreen"
    }

    $labels = @(
        @{Text = "BIOS Serial Number: $biosSerialNumber"; Location = New-Object Drawing.Point(20,20)}
        @{Text = "Lenovo Driver Manager will download drivers/firmware directly from Lenovo. `nDownloaded files will be saved in the script directory under 'downloads'."; Location = New-Object Drawing.Point(20,40)}
    )

    foreach ($labelInfo in $labels) {
        $label = New-Object Windows.Forms.Label -Property @{
            Text = $labelInfo.Text
            AutoSize = $true
            Location = $labelInfo.Location
            Font = New-Object Drawing.Font("Consolas",10)
        }
        $form.Controls.Add($label)
    }

    $copyButton = New-Object Windows.Forms.Button -Property @{
        Text = "Copy to Clipboard and Open Lenovo Driver Manager"
        Size = New-Object Drawing.Size(250,40)
        Location = New-Object Drawing.Point(50,100)
        Font = New-Object Drawing.Font("Consolas",10)
    }

    $copyButton.Add_Click({
        [Windows.Forms.Clipboard]::SetText($biosSerialNumber)
        $form.Close()
    })

    $form.Controls.Add($copyButton)

    $openButton = New-Object Windows.Forms.Button -Property @{
        Text = "Open Lenovo Driver Manager"
        Size = New-Object Drawing.Size(250,40)
        Location = New-Object Drawing.Point(300,100)
        Font = New-Object Drawing.Font("Consolas",10)
    }

    $openButton.Add_Click({
        $form.Close()
    })

    $form.Controls.Add($openButton)

    $form.ShowDialog() | Out-Null

    Write-Output "Launching Lenovo Driver Manager..."
    $lenovoDriverManagerPath = Join-Path -Path $binDir -ChildPath "Lenovo.Driver.Manager.exe"
    if (-Not (Test-Path $lenovoDriverManagerPath)) {
        Write-Error "Lenovo Driver Manager not found at: $lenovoDriverManagerPath"
        return
    }

    try {
        Start-Process -FilePath $lenovoDriverManagerPath -ErrorAction Stop
        Write-Output "Lenovo Driver Manager launched successfully."
    } catch {
        Write-Error "Failed to launch Lenovo Driver Manager. Error: $_"
    }
}

function Export-DeviceList {
    Write-Output "Exporting device list using DevManView..."
    $devManViewPath = Join-Path -Path $binDir -ChildPath "DevManView.exe"
    $outputFilePath = Join-Path -Path $scriptDir -ChildPath "DeviceManagerExport.txt"
    if (-Not (Test-Path $devManViewPath)) {
        Write-Error "DevManView not found at: $devManViewPath"
        return
    }
    try {
        $quotedOutputFilePath = "`"$outputFilePath`""  # Quote the output file path
        Start-Process -FilePath $devManViewPath -ArgumentList "/stext $quotedOutputFilePath" -NoNewWindow -Wait
        Write-Output "Device list export command executed."
        if (Test-Path $outputFilePath) {
            Write-Output "Device list exported successfully. Opening file..."
            Invoke-Item -Path $outputFilePath
        } else {
            Write-Error "Failed to export device list. File not found: $outputFilePath"
        }
    } catch {
        Write-Error "Failed to export device list using DevManView. Error: $_"
    }
}

function Run-DevManView {
    Write-Output "Launching DevManView..."
    $devManViewPath = Join-Path -Path $binDir -ChildPath "DevManView.exe"
    if (-Not (Test-Path $devManViewPath)) {
        Write-Error "DevManView not found at: $devManViewPath"
        return
    }
    try {
        Start-Process -FilePath $devManViewPath -ErrorAction Stop
        Write-Output "DevManView launched successfully."
    } catch {
        Write-Error "Failed to launch DevManView. Error: $_"
    }
}

function Invoke-Menu {
    [cmdletbinding()]
    Param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter your menu text")]
        [ValidateNotNullOrEmpty()]
        [string]$Menu,
        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$Title = "My Menu",
        [Alias("cls")]
        [switch]$ClearScreen
    )

    if ($ClearScreen) {
        Clear-Host
    }

    $menuPrompt = $title
    $menuPrompt+="`n"
    $menuPrompt+="-"*$title.Length
    $menuPrompt+="`n"
    $menuPrompt+=$menu
    Read-Host -Prompt $menuPrompt
} 

# Check required files on startup
Check-RequiredFiles

$menu=@"
1. Run Lenovo Driver Manager
2. Extract Firmware From Installer
3. Pad Thunderbolt Firmware BIN
4. Device Managing
5. Export Device List
6. Quit
Select a task by number or Q to quit
"@

$exit = $false
Do {
    Show-InitialInfo
    Write-Host ""
    $choice = Invoke-Menu -menu $menu -title "---  Thunderbolt Firmware Menu ---"
    $choice = $choice.ToUpper()  # Normalize input to uppercase
    Switch ($choice) {
        "1" {
            Write-Host "Launching Lenovo Driver Manager..." -ForegroundColor Yellow
            Run-LenovoDriverManager
            sleep -seconds 2
            cls
        }
        "2" {
            Write-Host "Extracting Firmware Install..." -ForegroundColor Green
            Extract-Installer -scriptDir $scriptDir
            sleep -seconds 2
            cls
        }
        "3" {
            Write-Host "Setting up padding operations..." -ForegroundColor Green
            Pad-FirmwareTo1MB
            sleep -seconds 2
            cls
        }
        "4" {
            Write-Host "Launching DevManView..." -ForegroundColor Blue
            Run-DevManView
            sleep -seconds 2
            cls
        }
        "5" {
            Write-Host "Exporting device list using DevManView..." -ForegroundColor Blue
            Export-DeviceList
            sleep -seconds 2
            cls
        }
        "6" {
            Write-Host "Goodbye!" -ForegroundColor Cyan
			Write-Host $splashExit0
			start-sleep -seconds 1.2
			write-host $splashExit1
			start-sleep -seconds 2
			Write-Host "											--Whale Linguini"
			Start-Sleep -Seconds 1
            $exit = $true
        }
        "Q" {
            Write-Host "Goodbye!" -ForegroundColor Cyan
			Write-Host $splashExit0
			start-sleep -seconds 1.2
			write-host $splashExit1
			start-sleep -seconds 2
			Write-Host "											--Whale Linguini"
			Start-Sleep -Seconds 1
            $exit = $true
        }
        Default {
            Write-Warning "Invalid Choice. Try again."
            sleep -milliseconds 750
        }
    }
} While (-not $exit)
