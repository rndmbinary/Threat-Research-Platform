#Requires -RunAsAdministrator
<#
.NAME
    stage_win.ps1
.DISCRIPTION
    Inspired by FireEye's FlareVM, this was created to support security analysts to conduct
    static, dynamic analysis and reverse enginnering against malicious objects. 
    Recommend using a Windows VM.
    Use at your own risk.
.AUTHOR
    Tyron Howard
.VERSION
    2.9.0 (10.02.2022)
.QUICK_STAGING
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/rndmbinary/Threat-Research-Platform/dev/stage_win.ps1'))
#>

function main {
        disable_defender;
        connection_check;
        bootstrap_vm(0);
        bootstrap_vm(1);
        bootstrap_vm(2);
        bootstrap_vm(3);
        stage_desktop;
};

function disable_defender {
    $firewall_status = Get-MpPreference | % {$_.Name -eq "DisableRealtimeMonitoring"};
    $UAC_status = Get-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin | % {$_.ConsentPromptBehaviorAdmin}
    
    if ($results = "False") {
        Write-Host "Disabling Windows Defender and UAC. . .";
        Set-MpPreference -DisableRealtimeMonitoring $True;
    } elseif ($UAC_status -ne 0) {
        Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
    };
};

function connection_check {
    try {
        Test-NetConnection www.google.com -port 443 | % {$_.TcpTestSucceeded};
    } catch {
        Write-Output "Internet Connection Failed!\n
        Closing staging script."
    };
};

function bootstrap_vm($mode) {
    $bootstrap_url = @(
        'https://chocolatey.org/install.ps1'
    );
    $bootstrap_clipath = @(
        'C:\ProgramData\chocolatey\bin\',
        'C:\Python37\Scripts\;C:\Python37\'
    );
    
    $userenv = $env:Path;
    $env:Path = $userenv + $bootstrap_clipath[$mode] +";";
    
    if ($mode -eq 0) {
        iwr $bootstrap_url[$mode] -UseBasicParsing | iex
    };
    install_tools($mode)
    return
};

function install_tools($mode) {
    $choco_package = @(
        # Required Packages
        'git',
        'python3 --version=3.10.7',
        # Coding Packages
        'nodejs.install',
        'typescript',
        'powershell-core',
        'golang',
        'vscode',
        # Static Identification
        'exiftool',
        # Static Debugging and Reversing
        'hxd',
        'x64dbg.portable',
        'rizin',
        'cutter',
        'ida-free --version=7.07.0',
        # Static Pattern Matching
        'yara',
        'yara-ci',
        # Process and System Watchers
        'processhacker',
        'RegistryChangesView',
        'sysinternals',
        # OSINT Tools
        'vt-cli',
        # OS Tools
        '7zip.install',
        'chrome'
        'powertoys',
        # Network Monitoring
        'mitmproxy',
        'wireshark'
    );
    $pip3_package = @(
        'requests',
        'oletools',
        'pdfminer.six',
        'scapy'
    );
    $git_package = @{
        'Binwalk' = 'https://github.com/ReFirmLabs/binwalk.git'
        'theZoo' = 'https://github.com/ytisf/theZoo.git'
    };
    $archive_package = @{
        'ProcDot' = 'https://www.procdot.com/download/procdot/binaries/procdot_1_22_57_windows.zip'
        'PeStudio' = 'https://www.winitor.com/tools/pestudio/current/pestudio.zip'
        'ImHex-NoGPU' = 'https://github.com/WerWolv/ImHex/releases/download/v1.23.2/imhex-1.23.2-Windows-Portable-NoGPU.zip'
    };
    
    If ($mode -eq 0) {
        Write-Host "Installing Chocolatey and VM tools" -BackgroundColor Red;
        ForEach ($tool in $choco_package) {
            iex "choco install -y $tool"
        };
        return
    } elseif ($mode -eq 1) {
        Write-Host "Installing Python 3" -BackgroundColor Red;
        ForEach ($tool in $pip3_package) {
            iex "pip install $tool";
        };
        return
    } elseif ($mode -eq 2) {
        ForEach ($tool in $git_package.Keys) {
            iex 'git clone $git_package[$tool] $env:USERPROFILE\Desktop\$tool';
        };
        return
    } elseif ($mode -eq 3) {
        ForEach ($tool in $archive_package.Keys) {
            if ((Test-Path "$env:USERPROFILE\Desktop\$tool") -eq $false) {
                New-Item -Path "$env:USERPROFILE\Desktop\$tool" -ItemType "Directory";
            };
            iwr $archive_package[$tool] -OutFile "$env:USERPROFILE\Desktop\$tool\$tool.zip" -UseBasicParsing
            Expand-Archive "$env:USERPROFILE\Desktop\$tool\$tool.zip" "$env:USERPROFILE\Desktop\$tool" -ErrorAction SilentlyContinue;
        };
        return
    };
}

function stage_desktop {
    $shell = New-Object -ComObject ("WScript.Shell");
    $tool_list = iex 'Get-ChildItem C:\ProgramData\chocolatey\bin | % {$_.Name}'

    if ((Test-Path "$env:USERPROFILE\Desktop\Tools") -eq $false) {
        New-Item -Path "$env:USERPROFILE\Desktop\Tools" -ItemType "Directory";
    };

    ForEach ($tool in $tool_list) {
            $shortcut_location = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Tools\$tool" + ".lnk");
            $shortcut_location.TargetPath="$x";
            $shortcut_location.WorkingDirectory = 'C:\ProgramData\chocolatey\bin';
            $shortcut_location.WindowStyle = 1;
            $shortcut_location.IconLocation = "$x, 0";
            $shortcut_location.Save();
    };

};


main;
