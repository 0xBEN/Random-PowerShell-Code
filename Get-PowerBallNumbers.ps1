function Get-PowerBallNumbers {

    [CmdletBinding()]
    Param ()
    DynamicParam {

        # Year parameter
        $yearParamTitle = 'Year'
        $yearParamAttrib = New-Object System.Management.Automation.ParameterAttribute
        $yearParamAttrib.Mandatory = $false
        $yearValidationSet = New-Object System.Management.Automation.ValidateSetAttribute(1992..(Get-Date).Year)
        $yearAttribCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $yearAttribCollection.Add($yearParamAttrib)        
        $yearAttribCollection.Add($yearValidationSet)
        $yearParameter = New-Object -Type System.Management.Automation.RuntimeDefinedParameter($yearParamTitle, [Int32[]], $yearAttribCollection)

        # Add parameters to parameter set
        $allDynamicParameters = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $allDynamicParameters.Add($yearParamTitle, $yearParameter)

        return $allDynamicParameters

    }
    begin {
        
        $Year = $PSBoundParameters['Year']
        $upperLetters = 65..90 | ForEach-Object { [char]$_ }
        $lowerLetters = $upperLetters | ForEach-Object { $_.ToString().ToLower() }
        $numbers = 0..100
        $daysInMonth = 1..31
        $validCharacters = $upperLetters + $lowerLetters + $numbers + ' '
        $monthsOfYear = 1..12 | ForEach-Object { 
            
            $dateTime = Get-Date -Month $_
            $dateTime.ToLongDateString() -split ', ' -split ' ' | Select-Object -Index 1

        }

    }
    process {

        $processJobs = @()
        $Year | ForEach-Object {

            $yearInProcess = $_
            $uri = "https://www.powerball.net/archive/$yearInProcess"
            Write-Verbose "Making web request to $uri"
            $webRequest = Invoke-WebRequest $uri -UseBasicParsing -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -Method Get
            $html = $webRequest.RawContent
            $scriptBlock = {
                    
                $html = $args[0]
                $validCharacters = $args[1]
                $text = $html.Split('>')
                $text = $text -replace '\<.*', '' -replace "`n*", '' -split ' ' -replace '^st|nd|rd|th$', ''
                $text = $text -replace '\<.*', '' -replace "`n*", '' -split ' ' 
                $text = $text | Where-Object { -not [string]::IsNullOrEmpty($_) -and -not [string]::IsNullOrWhiteSpace($_) }
                $text = $text | ForEach-Object {

                    $line = $_
                    $acceptableCharacters = ""
                    $charArray = $line.ToCharArray()
                    $charArray | ForEach-Object {

                        $char = $_
                        if ($char.ToString() -in $validCharacters) {

                            $acceptableCharacters += $char
                        
                        }
                        else {

                            Out-Null

                        }

                    }
                    if ($acceptableCharacters) { $acceptableCharacters.ToString() }

                }

                return $text

            }

            $processJobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $html, $validCharacters

        }
        Write-Verbose "Parsing HTML and formatting for output"
        $compiledText = $processJobs | Wait-Job | Receive-Job
        $processJobs | Remove-Job        
        
        Write-Verbose "Converting parsed HTML into object notation"
        $results = @()
        $compiledText | ForEach-Object {

            $line = $_
            $monthDateLine = ""
            if ($line -in $monthsOfYear) {

                $monthNameIndex = $indexCounter
                if ($compiledText[$monthNameIndex + 1] -in $daysInMonth) {
                    
                    $drawingObject = New-Object -Type PSObject

                    $monthDateLine = $line # Month name
                    $monthDateLine += $compiledText[$monthNameIndex + 1] # Day of month
                    $monthDateLine += ', ' # For formatting
                    $monthDateLine += $compiledText[$monthNameIndex + 2] # Year
                    $monthDateLine += ' 10:59 PM' # When drawings are done
                    $date = Get-Date $monthDateLine
                    if ($date.Year -lt 2001) { # Power Play Numbers wasn't a thing before then

                        $startNumberIndex = $monthNameIndex + 3
                        $endNumberIndex = $startNumberIndex + 4
                        $drawingNumbers = $compiledText[$startNumberIndex..$endNumberIndex] | ForEach-Object { [int]$_ }
                        $drawingObject | Add-Member -Type NoteProperty -Name DrawingDate -Value $date -Force
                        $drawingObject | Add-Member -Type NoteProperty -Name DrawingNumbers -Value $drawingNumbers -Force
                        $drawingObject | Add-Member -Type NoteProperty -Name DrawingString -Value ($drawingNumbers -join ' ') -Force

                    }
                    else {

                        $startNumberIndex = $monthNameIndex + 3
                        $endNumberIndex = $startNumberIndex + 5
                        $powerPlayIndex = $startNumberIndex + 6
                        $drawingNumbers = $compiledText[$startNumberIndex..$endNumberIndex] | ForEach-Object { [int]$_ }
                        [int]$powerPlayNumber = $compiledText[$powerPlayIndex]
                        $drawingObject | Add-Member -Type NoteProperty -Name DrawingDate -Value $date -Force
                        $drawingObject | Add-Member -Type NoteProperty -Name DrawingNumbers -Value $drawingNumbers -Force
                        $drawingObject | Add-Member -Type NoteProperty -Name PowerPlayNumber -Value $powerPlayNumber -Force
                        $drawingObject | Add-Member -Type NoteProperty -Name DrawingString -Value (($drawingNumbers -join ' ') + ' ' + $powerPlayNumber + 'X') -Force

                    }

                    $results += $drawingObject

                }

            }

            $indexCounter++

        }

        if ($results) { return $results }

    }

}