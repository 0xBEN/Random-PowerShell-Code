$InformationPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
$credentials = Import-Clixml "$PSScriptRoot/EncryptedCredentials/gmail.clixml"
$smtpServer = 'smtp.gmail.com'
$port = 587
$subject = "Today's Free Packt eBook"
$modulesToImport = '/root/PSModules/PSToolbox'
$uri = 'https://www.packtpub.com/free-learning'
$discordBotLogo = 'https://freeiconshop.com/wp-content/uploads/edd/book-open-flat.png'
$botName = 'Study Bot'

Import-Module $modulesToImport
$encryptedWebhookUri = Import-Clixml "$PSScriptRoot/EncryptedCredentials/StudyBotDiscordWebhook.clixml"
$plaintextWebhookUri = $encryptedWebhookUri | ConvertFrom-SecureString
$request = Invoke-WebRequest $uri
$eBook = $request.Content | Remove-HtmlTags | Select-String '^Free.eBook.*'

$emailBody = 
@"
<html>
<body>
	<p><strong><a href=`"$uri`">Today's Free eBook (must click link to claim, must be read on publisher page -- no download)</a></strong>:<br>$eBook</p>
    <p><em>This email was sent by a cron job on your Proxmox server.</p>
</body>
</html>
"@

$discordBody = @"
**__Today's Free Packt E-Book:__**
*This e-book must be read using the publisher's online reader, no downloads*

**Link:** $uri
**Title:** $ebook
"@

Send-MailMessage `
-UseSsl `
-From $credentials.UserName `
-To $credentials.UserName `
-Subject $subject `
-Body $emailBody `
-BodyAsHtml `
-SmtpServer $smtpServer `
-Port $port `
-Credential $credentials `
-WarningAction SilentlyContinue

& "$PSScriptRoot/Send-DiscordWebhook.ps1" -webhook_uri $plaintextWebhookUri -username $botName -content $discordBody -avatar_url $discordBotLogo
