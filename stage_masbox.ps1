<#
.NAME
    stage_masbox.ps1
.DISCRIPTION
.AUTHOR
    TYRON HOWARD
.VERSION
    1.0 (9.19.2019)
#>
function connection_check {
    $results = Test-NetConnection www.google.com -port 443 | % {$_.TcpTestSucceeded}
    if ($results -eq "True") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        Write-Output "Installing Chocolatey and VM tools"
        bootstrap_vm(0)
        Write-Output "Installing Python 3 PIP and Python 3 Modules"
        bootstrap_vm(1)
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
        ForEach ($tool in $choco_package) {
            iex "choco install -y $tool"
        }
        $userenv = [System.Environment]::GetEnvironmentVariable("PATH", "User");
        [System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";C:\ProgramData\chocolatey\bin", "User")
    } elseif ($mode -eq 1) {
        ForEach ($tool in $pip_package) {
            iex "pip3 install $tool"
        }
    }
    return
}

connection_check
