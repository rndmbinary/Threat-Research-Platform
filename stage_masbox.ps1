<#
.NAME
    stage_masbox.ps1
.DISCRIPTION
.AUTHOR
    TYRON HOWARD
.VERSION
    0.9 (9.19.2019)
#>
function connection_check {
    $results = Test-NetConnection www.google.com -port 443 | % {$_.TcpTestSucceeded}
    if ($results -eq "True") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        bootstrap_vm(1)
        bootstrap_vm(2)
    }
}

function bootstrap_vm ($mode) {
    $bootstrap_url = @(
        'https://chocolatey.org/install.ps1'
        'https://bootstrap.pypa.io/get-pip.py'
    )
    Set-ExecuationPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString($bootstrap_url[$mode]))
    install_tools($mode)
    return
}

function tool_packages ($mode) {
    $choco_package = @(
        'x64dbg.protable',
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
    If ($mode -eq 1) {
        ForEach ($tool in $choco_package) {
            Write-Host "choco install -y $tool"
        }
    } elseif ($mode -eq 2) {
        ForEach ($tool in $pip_package) {
            Write-Host "pip3 install $tool"
        }
    }
    return
}

connection_check()
