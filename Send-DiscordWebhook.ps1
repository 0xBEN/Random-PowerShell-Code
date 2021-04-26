Param (
    [Parameter(Mandatory = $true)]
    [System.Uri]
    $webhook_uri,

    [Parameter()]
    [Alias('BotName')]
    [ValidateNotNullOrEmpty()]
    [String]
    $username,

    [Parameter(Mandatory = $true)]
    [Alias('Message')]
    [ValidateNotNullOrEmpty()]
    [String]
    $content,

    [Parameter()]
    [Alias('AvatarUri')]
    [ValidateNotNullOrEmpty()]
    [String]
    $avatar_url
)
begin {
    $InformationPreference = 'SilentlyContinue'
    $VerbosePreference = 'SilentlyContinue'
    $ProgressPreference = 'SilentlyContinue'
    $content = 'application/json'
}
process {
    $jsonBody = $PSBoundParameters | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Method Post -Uri $webhook_uri -Body $jsonBody -Content $content | Out-Null
}
