#Requires -RunAsAdministrator
<#
.NAME
    stage_masbox.ps1
.DISCRIPTION
.AUTHOR
    TYRON HOWARD
.VERSION
    1.0 (9.19.2019)
#>

function main {
    try {
        elevate_script
        disable_defender
        conection_check
        bootstrap_vm(0)
        bootstrap_vm(1)
        stage_desktop
    } catch [System.SystemException] {
        "One of the functions did not complete execution successfully."
    }

}

function elevate_script {
    Start-Process "Powershell Set-ExecutionPolicy Bypass -Scope Process -Force;$env:USERPROFILE\Desktop\stage_masbox.ps1" -Verb RunAs 
}

function disable_defender {
    $results = Get-MpPreference | % {$_.Name -eq "DisableRealtimeMonitoring"}
    if ($results = "False") {
        Write-Host "Disabling Windows Defender"
        Set-MpPreference -DisabledRealtimeMonitoring $True
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
        'vscode',
        '7zip.install',
        'yara',
        'ida-free',
        'fiddler',
        'python3',
        'sysinternals',
        'git',
        'exiftool'
    )
    $pip_package = @(
        'requests',
        'oletools',
        'pdfminer.six',
        'scapy'
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
    }
    return
}

function stage_desktop {
    $shell = New-Object -ComObject ("WScript.Shell")
    New-Item -Path $env:USERPROFILE + "\Desktop\Tools" -ItemType "Directory"
    $tools = Get-ChildItem "C:\ProgramData\chocolatey\bin" | % {%_.Name}

    ForEach ($tool in $tools) {
        $shortcut_location = $shell.CreateShortcut($env:USERPROFILE + "\Desktop\Tools\$tool" + ".lnk");
        $shortcut_location.TargetPath="$tool";
        $shortcut_location.WorkingDirectory = "C:\ProgramData\chocolatey\bin";
        $shortcut_location.WindowStyle = 1;
        $shortcut_location.IconLocation = "$tool, 0"
        $shortcut_location.Save()
    }
}

main