#Requires -RunAsAdministrator
<#
.NAME
    stage_masbox.ps1
.DISCRIPTION
.AUTHOR
.VERSION
    2.4.2 (10.18.2019)
#>


function main {
    try {
        disable_defender;
        connection_check;
        bootstrap_vm(0);
        bootstrap_vm(1);
        bootstrap_vm(2);
        bootstrap_vm(3);
        stage_desktop;
    } catch [System.SystemException] {
        Write-Host "One of the functions did not complete execution successfully." -BackgroundColor Red;
    };
};

function disable_defender {
    $results = Get-MpPreference | % {$_.Name -eq "DisableRealtimeMonitoring"};
    if ($results = "False") {
        Write-Host "Disabling Windows Defender";
        
        Set-MpPreference -DisableRealtimeMonitoring $True;
    };
};

function connection_check {
    $results = Test-NetConnection www.google.com -port 443 | % {$_.TcpTestSucceeded};
    if ($results -eq "True") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux;
    } else {
        break;
    };
};

function bootstrap_vm($mode) {
    $bootstrap_url = @(
        'https://chocolatey.org/install.ps1',
        'https://bootstrap.pypa.io/get-pip.py',
        'https://aka.ms/wsl-ubuntu-1804'
    );
    $bootstrap_clipath = @(
        'C:\ProgramData\chocolatey\bin\',
        'C:\Python37\Scripts\;C:\Python37\',
        'C:\Python27\Scripts\;C:\Python27\',
        'C:\Windows\Ubuntu\'
    );
    if ($mode -eq 0 -or $mode -eq 3) {
        $userenv = $env:Path;
        $env:Path = $userenv + $bootstrap_clipath[$mode] +";";
    }
    if ($mode -eq 0) {
        iwr $bootstrap_url[$mode] -UseBasicParsing | iex
    } elseif ($mode -eq 3) {
        if ((Test-Path "$env:SystemRoot\Ubuntu") -eq $false) {
            New-Item -Path "$env:SystemRoot\Ubuntu" -ItemType "Directory";
            iwr -Uri $bootstrap_url[$mode] -OutFile "$env:SystemRoot\Ubuntu\Ubuntu.appx" -UseBasicParsing;
        };  
    };
    install_tools($mode)
    return
};

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
        'ida-free --version=7.07.0',
        'fiddler',
        'python3 --version=3.7.4',
        'python2 --version=2.7.17',
        'sysinternals',
        'git',
        'exiftool',
        'vt-cli'
    );
    $pip_package = @(
        'requests',
        'oletools',
        'pdfminer.six',
        'scapy',
        'stoq-framework', #https://github.com/PUNCH-Cyber/stoq
        '-U https://github.com/decalage2/ViperMonkey/archive/master.zip' #ViperMonkey
    );
    $git_package = @{
        'YarGen' = 'https://github.com/Neo23x0/yarGen.git'
    };
    $manual_package = @(
        'https://www.procdot.com/download/procdot/binaries/procdot_1_22_57_windows.zip ', #ProcDot
        'https://winitor.com/tools/pestudio/current/A9B8E0FD-AFFC-4829-BE81-8F1AB5BC496A.zip' #PeStudio
    );
    
    If ($mode -eq 0) {
        Write-Host "Installing Chocolatey and VM tools" -BackgroundColor Red;
        ForEach ($tool in $choco_package) {
            iex "choco install -y $tool"
        };
    } elseif ($mode -eq 1) {
        Write-Host "Installing Python 3 Modules using PIP" -BackgroundColor Red;

        ForEach ($tool in $pip_package) {
            iex "pip3 install $tool";
            iex "pip2 install $tool";
        };
    } elseif ($mode -eq 3) {
        Write-Host "Installing Ubuntu. Please set a username and password when prompted" -BackgroundColor Red;
        
        Rename-Item "$env:SystemRoot\Ubuntu\Ubuntu.appx" "$env:SystemRoot\Ubuntu\Ubuntu.zip" -ErrorAction SilentlyContinue;
        Expand-Archive "$env:SystemRoot\Ubuntu\Ubuntu.zip" "$env:SystemRoot\Ubuntu" -ErrorAction SilentlyContinue;
        Start-Process "$env:SystemRoot\Ubuntu\ubuntu1804.exe" -NoNewWindow -Wait;

        Write-Host "Updating Ubuntu. Please use the username and password set during the initial install of Ubuntu" -BackgroundColor Red

        Start-Process C:\Windows\Ubuntu\ubuntu1804.exe 'run sudo apt update';
        # Remove-Item "$env:SystemRoot\Ubuntu\Ubuntu.zip"
    } elseif ($mode -eq 2) {
        ForEach ($tool in $git_package.Keys) {
            iex 'git clone $git_package[$tool] $env:USERPROFILE\Desktop\$tool';
        };
    };
};

function stage_desktop {
    $shell = New-Object -ComObject ("WScript.Shell");
    if ((Test-Path "$env:USERPROFILE\Desktop\Tools") -eq $false) {
        New-Item -Path "$env:USERPROFILE\Desktop\Tools" -ItemType "Directory";
    };
    
    $tools = @{
        'Get-ChildItem C:\ProgramData\chocolatey\bin | % {$_.Name}' = 'C:\ProgramData\chocolatey\bin'
        'Get-ChildItem $env:SystemRoot\Ubuntu\ubuntu1804.exe | % {$_.Name}' = '$env:SystemRoot\Ubuntu\'
    };

    ForEach ($tool in $tools.Keys) {
        $tool_list = iex $tool
        ForEach ($x in $tool_list) {
            $shortcut_location = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Tools\$x" + ".lnk");
            $shortcut_location.TargetPath="$x";
            $shortcut_location.WorkingDirectory = $tools[$tool];
            $shortcut_location.WindowStyle = 1;
            $shortcut_location.IconLocation = "$x, 0";
            $shortcut_location.Save();
        };
    };
};

<#
    ForEach ($tool in $tools) {
        $shortcut_location = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Tools\$tool" + ".lnk");
        $shortcut_location.TargetPath="$tool";
        $shortcut_location.WorkingDirectory = $location;
        $shortcut_location.WindowStyle = 1;
        $shortcut_location.IconLocation = "$tool, 0";
        $shortcut_location.Save();
    };
#>

<#
    $tools = Get-ChildItem "C:\ProgramData\chocolatey\bin" | % {$_.Name};
    $location = "C:\ProgramData\chocolatey\bin"
    $tools = Get-ChildItem "$env:SystemRoot\Ubuntu\ubuntu1804.exe"
    $location = "$env:SystemRoot\Ubuntu\"
#>

main;
