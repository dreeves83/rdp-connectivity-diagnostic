<#
.SYNOPSIS
    Tests repeated TCP connectivity to an RDP endpoint.

.DESCRIPTION
    This script repeatedly attempts to open a TCP connection to a target host
    and port. It reports each attempt as SUCCESS, FAIL, or ERROR, then prints
    a summary with success rate and response-time statistics.

    Typical use:
        Change only -TargetHost when running the script.

    Optional parameters:
        -Port       Defaults to 3389 for RDP. Change only if testing another port.
        -Attempts   Defaults to 100. Increase for longer testing.
        -TimeoutMs  Defaults to 5000. Increase for slow or unreliable networks.

.EXAMPLE
    .\Test-RdpConnectivity.ps1 -TargetHost example.com

.EXAMPLE
    .\Test-RdpConnectivity.ps1 -TargetHost 203.0.113.10 -Attempts 500

.EXAMPLE
    .\Test-RdpConnectivity.ps1 -TargetHost server.example.com -Port 3389 -Attempts 1000 -TimeoutMs 30000
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetHost,

    [ValidateRange(1, 65535)]
    [int]$Port = 3389,

    [ValidateRange(1, 100000)]
    [int]$Attempts = 100,

    [ValidateRange(100, 300000)]
    [int]$TimeoutMs = 5000
)

$successCount = 0
$failCount = 0
$times = @()

Write-Host ""
Write-Host "RDP Connectivity Test"
Write-Host "Target  : $TargetHost`:$Port"
Write-Host "Attempts: $Attempts"
Write-Host "Timeout : $TimeoutMs ms"
Write-Host ""

for ($i = 1; $i -le $Attempts; $i++) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $asyncResult = $tcp.BeginConnect($TargetHost, $Port, $null, $null)
        $connected = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)

        if ($connected -and $tcp.Connected) {
            $tcp.EndConnect($asyncResult)
            $status = "SUCCESS"
            $successCount++
        }
        else {
            $status = "FAIL"
            $failCount++
        }
    }
    catch {
        $status = "ERROR"
        $failCount++
    }
    finally {
        $sw.Stop()
        $time = $sw.ElapsedMilliseconds
        $times += $time

        $tcp.Close()
        $tcp.Dispose()
    }

    Write-Host ("Attempt {0,4} | {1,-7} | {2,6} ms" -f $i, $status, $time)
}

$avg = [math]::Round(($times | Measure-Object -Average).Average, 2)
$min = ($times | Measure-Object -Minimum).Minimum
$max = ($times | Measure-Object -Maximum).Maximum
$successRate = [math]::Round(($successCount / $Attempts) * 100, 2)

Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Successful attempts : $successCount"
Write-Host "Failed attempts     : $failCount"
Write-Host "Success rate        : $successRate%"
Write-Host "Average time        : $avg ms"
Write-Host "Minimum time        : $min ms"
Write-Host "Maximum time        : $max ms"
Write-Host ""
