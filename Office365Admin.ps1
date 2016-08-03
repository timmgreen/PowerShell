Function Connect-Office365
{
	If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
	[Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
		Break
	}
	$sessions = Get-PSSession | ? { $_.State -eq "Opened" -and $_.ComputerName -match "outlook.com" -and $_.ConfigurationName -match "Microsoft." }
	If ($sessions -eq $NULL)
	{
		If ((Get-Module MSOnline) -eq $null)
		{
			Import-Module MSOnline -WarningAction SilentlyContinue
			Import-Module LyncOnlineConnector -WarningAction SilentlyContinue
		}
		
		If ((Get-Module Microsoft.Online.SharePoint.PowerShell) -eq $null)
		{
			Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking -WarningAction SilentlyContinue
		}
		
		#Set-ExecutionPolicy Unrestricted -Confirm:$false
		
		$LiveCred = Get-Credential -Username ($env:USERNAME + (($env:USERDNSDOMAIN).Replace("HQ.", "@").ToLower())) -Message "Enter Office 365 Global Admin Credentials"
		
		$MSOLSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic –AllowRedirection -WarningAction SilentlyContinue
		
		Import-PSSession $MSOLSession -AllowClobber -WarningAction SilentlyContinue
		
		connect-msolservice -Credential $LiveCred -WarningAction SilentlyContinue
		
		$CSOLSession = New-CSOnlineSession -Credential $LiveCred -WarningAction SilentlyContinue
		
		Import-PSSession $CSOLSession -AllowClobber -WarningAction SilentlyContinue
		
		#Set-ExecutionPolicy RemoteSigned -Confirm:$false
	}
	ELSE
	{
		Write-Host "MSOL Session Already Exists"
	}
	
	$sessions = $null
} #end Function Connect-Office365

 Set-Alias -Name Logon-Office365 -value Connect-Office365

Function Get-NestedMembership
{
	param ([string]$GroupName)
	Connect-Office365
	Function Expand-DistributionGroups ([string]$DLName)
	{
		Get-DistributionGroupMember -Identity $DLName | % {
			If ($_.RecipientType -ne "UserMailbox")
			{
				Expand-DistributionGroups $_.Name
			}
			ELSE
			{
				$_ | Select PrimarySMTPAddress, FirstName, LastName | Export-Csv -Path $outputfilepath -Encoding ASCII -Append -NoTypeInformation -Force
			}
		}
	} #end Function Get-NestedMembership
	
	If ($GroupName -eq $null)
	{
		$GroupName = Read-Host -Prompt "Enter display name of distribution group"
	}
	
	$outputfilepath = "c:\nested_members_" + $GroupName + ".csv"
	$outputfile = New-Item -Path $outputfilepath -ItemType File -Force -confirm:$false
	Write-Host ("Nested Group Membership output to " + $outputfile.FullName)
	Expand-DistributionGroups $GroupName
} #end Function Get-NestedMembership