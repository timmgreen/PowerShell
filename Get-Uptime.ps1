Function Get-Uptime
{
	
	[cmdletbinding()]
	Param (
		[parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]$ComputerName = $env:COMPUTERNAME,
		[switch]$PassThru
	)
	
	PROCESS
	{
		foreach ($computer in $ComputerName)
		{
			If (Test-Connection -ComputerName $computer -Quiet -Count 1 -TimeToLive 10)
			{
				$LastBoot = [System.Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject win32_operatingsystem -ComputerName $computer).lastbootuptime)
				$Uptime = (Get-Date) - $LastBoot
				$properties = [ordered]@{
					'ComputerName' = $computer;
					'LastBootTime' = $LastBoot;
					'Years' = $Uptime.Years;
					'Days' = $Uptime.Days;
					'Hours' = $Uptime.Hours;
					'Minutes' = $Uptime.Minutes;
					'Seconds' = $Uptime.Seconds;
				}
				$objOutput = New-Object -TypeName System.Management.Automation.PSObject -Property $properties
				If ($PassThru)
				{
					Write-Output $objOutput
				}
				Else
				{
					Write-Host ($objOutput.computername.ToUpper() + " has been up since " + $objOutput.LastBootTime)
					Write-Host ("Uptime:  ") -NoNewline
					
					If ($objOutput.Years -ge 1)
					{
						Write-Host ($objOutput.Years.ToString() + " years, ") -NoNewline
					}
					
					If ($objOutput.Days -ge 1)
					{
						Write-Host ($objOutput.Days.ToString() + " days, ") -NoNewline
					}
					
					If ($objOutput.Hours -ge 1)
					{
						Write-Host ($objOutput.Hours.ToString() + " hours, ") -NoNewline
					}
					
					If ($objOutput.Minutes -ge 1)
					{
						Write-Host ($objOutput.Minutes.ToString() + " minutes, ") -NoNewline
					}
					
					If ($objOutput.Seconds -ge 1)
					{
						Write-Host ($objOutput.Seconds.ToString() + " seconds.")
					}
					
					Write-Host " "
				}
			}
			Else
			{
				Write-Host ($computer + " is not available.") -ForegroundColor Yellow
				Write-Host " "
			}
		}
	}
}
