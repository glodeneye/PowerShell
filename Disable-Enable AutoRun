#Disable-AutoRun
function Disable-AutoRun
{
    $item = Get-Item `
        "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf" `
        -ErrorAction SilentlyContinue
    if (-not $item) {
        $item = New-Item "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf"
    }
    Set-ItemProperty $item.PSPath "(default)" "@SYS:DoesNotExist"
}
function Enable-AutoRun
{
    Remove-Item "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf" -Force
}
#Enable-AutoRun
function Enable-AutoRun
{
    Remove-Item "REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\IniFileMapping\AutoRun.inf" -Force
}
