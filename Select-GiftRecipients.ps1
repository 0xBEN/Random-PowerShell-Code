[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({$ParticipantNames.Count % 2 -eq 0})]
    [String[]]
    $ParticipantNames
)
process {
    
    do {
        $tallied = @{}
        while ($tallied.Count -ne $ParticipantNames.Count) {
            $buyer = $ParticipantNames | Where-Object {$_ -notin $tallied.Keys} | Get-Random -Count 1
            $receiver = $ParticipantNames | Where-Object {$_ -notin $tallied.Values} | Get-Random -Count 1
            $tallied.Add($buyer, $receiver)
        }
        $duplicateEntries = $tallied.GetEnumerator() | Where-Object { $_.Value -eq $_.Key }
    }
    until ($duplicateEntries.Count -eq 0)
    $tallied.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Host $_.Key -ForegroundColor Cyan -NoNewLine
        Write-Host " buys for " -NoNewLine
        Write-Host $_.Value -ForegroundColor Magenta
    }
    
}