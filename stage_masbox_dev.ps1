#Requires -RunAsAdministrator
<#
.NAME
    stage_masbox.ps1
.DISCRIPTION
.AUTHOR
    TYRON HOWARD
.VERSION
    2.0 (9.20.2019)
#>

function main {
    try {
        disable_defender
        connection_check
        bootstrap_vm(0)
        bootstrap_vm(1)
        bootstrap_vm(2)
        stage_desktop
    } catch [System.SystemException] {
        "One of the functions did not complete execution successfully."
    }
}

function disable_defender {
    $results = Get-MpPreference | % {$_.Name -eq "DisableRealtimeMonitoring"}
    if ($results = "False") {
        Write-Host "Disabling Windows Defender"
        Set-MpPreference -DisableRealtimeMonitoring $True
    }
}

function connection_check {
    $results = Test-NetConnection www.google.com -port 443 | % {$_.TcpTestSucceeded}
    if ($results -eq "True") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    } else {
        break
    }
}

function bootstrap_vm($mode) {
    $bootstrap_url = @(
        'https://chocolatey.org/install.ps1'
        'https://bootstrap.pypa.io/get-pip.py'
    )
    iwr $bootstrap_url[$mode] -UseBasicParsing | iex
    install_tools($mode)
    return
}

function install_tools($mode) {
    $choco_package = @(
        'x64dbg.portable',
        'radare',
        'hxd',
        'wireshark',
        'pebear',
        'processhacker',
        'resourcehacker'
        'vscode',
        '7zip.install',
        'yara',
        'ida-free',
        'fiddler',
        'python3',
        'python2',
        'sysinternals',
        'git',
        'exiftool'
    )
    $pip_package = @(
        'requests',
        'oletools',
        'pdfminer.six',
        'scapy'
        '-U https://github.com/decalage2/ViperMonkey/archive/master.zip' #ViperMonkey
    )
    If ($mode -eq 0) {
        Write-Output "Installing Chocolatey and VM tools"
        ForEach ($tool in $choco_package) {
            iex "choco install -y $tool"
        }
        $userenv = [System.Environment]::GetEnvironmentVariable("PATH", "User");
        [System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";C:\ProgramData\chocolatey\bin", "User")
    } elseif ($mode -eq 1) {
        Write-Output "Installing Python 3 Modules using PIP"
        ForEach ($tool in $pip_package) {
            iex "pip3 install $tool"
        }
    } elseif ($mode -eq 2) {
        New-Item -Path "$env:SystemRoot\Ubuntu" -ItemType "Directory"
        iwr -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile "$env:SystemRoot\Ubuntu.appx" -UseBasicParsing
        Rename-Item "$env:SystemRoot\Ubuntu.appx" "$env:SystemRoot\Ubuntu.zip"
        Expand-Archive "$env:SystemRoot\Ubuntu.zip" "$env:SystemRoot\Ubuntu"
        Start-Process "$env:SystemRoot\ubuntu1804.exe"
        $userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
        [System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";$env:SystemRoot\Ubuntu", "User")
        # Remove-Item "$env:SystemRoot\Ubuntu.zip"
    }
    return
}

function stage_desktop {
    $shell = New-Object -ComObject ("WScript.Shell")
    New-Item -Path "$env:USERPROFILE\Desktop\Tools" -ItemType "Directory"
    $tools = Get-ChildItem "C:\ProgramData\chocolatey\bin" | % {%_.Name}

    ForEach ($tool in $tools) {
        $shortcut_location = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Tools\$tool" + ".lnk");
        $shortcut_location.TargetPath="$tool";
        $shortcut_location.WorkingDirectory = "C:\ProgramData\chocolatey\bin";
        $shortcut_location.WindowStyle = 1;
        $shortcut_location.IconLocation = "$tool, 0"
        $shortcut_location.Save()
    }
}

main