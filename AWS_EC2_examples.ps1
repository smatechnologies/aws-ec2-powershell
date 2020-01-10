param(
    $accesskey,
    $secretkey,
    $profile = "default",
    $imagename = "WINDOWS_2019_BASE",
    $imageid,
    $instancetype = "t2.micro", 
    $region = "us-west-2",
    $tag,
    $option,
    $apitoken,
    $apiaddress,
    $agentname,
    $agentsocket = "3100",
    $agentdescription = "AWS Test Instance",
    $agenttype ="Windows",
    $agentjors = "3110",
    $groupName = "default",
    $ip,
    $imagedescription = "AWS Image",
    $port,
    $ipDescription,
    $keyname = "Demo",
    $opconmodule = "C:\ProgramData\OpConxps\Demo\OpCon.psm1",
    $awsmodule = "C:\ProgramData\OpConxps\Demo\AWS.psm1",
    $volumetype = "gp2",
    $volumesize = 30
)

if(Test-Path $awsmodule)
{
    #Import needed modules
    try
    {
        Import-Module AWSPowershell
        Import-Module -Name $awsmodule -Force

        #Set-DefaultAWSRegion -Region $region

        Get-AWSPowerShellVersion #Output version
    }
    catch [Exception]
    {
        Write-Host "AWS Powershell modules not found!"
        Exit 100
    }
}
else
{
    Write-Host "Unable to import AWS modules!"
    Exit 100
}

#Call various functions based on option input as parameter
if($option -eq "createAWSOPCON")
{
    if(Test-Path $opconmodule)
    {
        Import-Module -Name $opconmodule -Force
    }
    else
    {
        Write-Host "Unable to import OpCon modules!"
        Exit 100        
    }

    SMA_CreateAWSInstance -awsimageid $imageid -awsimagename $imagename -awsinstancetype $instancetype -tagvalue $tag -key $keyname -region $region

    $counter = 0
    $status = ""
    While((($status.InstanceState.Name.Value -ne "running") -or ($status.SystemStatus.Status.Value -ne "ok") -or ($status.Status.Status.Value -ne "ok")) -and ($counter -lt 100))
    {
        try
        {
            $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region | Where-Object{$_.State.Name.Value -eq "running"}
        
            if($getinfo)
            {
                $status = (Get-EC2InstanceStatus -InstanceId $getinfo.InstanceId -region $region)
            }
        }
        catch [Exception]
        {
            Write-Host $_.Exception.Message
            Exit 103
        }

        Start-Sleep -s 6
        $counter++
    }

    if($counter -gt 99)
    {
        Write-Host "Instance took too long to start"
        Exit 105
    }

    $getinfo
    Write-Host "Number of loops: $counter`r`n"

    SMA_CreateAgent -agentname $tag -agenttype $agenttype -agentdescription $agentdescription -agentsocket $agentsocket -agentjors $agentjors -token $apitoken -url $apiaddress
    SMA_UpdateAgent -agentname $tag -url $apiaddress -token $apitoken -field "tcpIpAddress" -value $getinfo.PublicIpAddress
    SMA_UpdateAgent -agentname $tag -url $apiaddress -token $apitoken -field "fileTransferRole" -value "T"
    SMA_UpdateAgent -agentname $tag -url $apiaddress -token $apitoken -field "fileTransferPortNumberForNonTLS" -value $agentjors
    SMA_UpdateAgent -agentname $tag -url $apiaddress -token $apitoken -field "supportNonTLSForSMAFTServer" -value "true"
    SMA_UpdateAgent -agentname $tag -url $apiaddress -token $apitoken -field "supportNonTLSForSMAFTAgent" -value "true"
}
elseif($option -eq "getAWSIPforOpCon")
{
    if(Test-Path $opconmodule)
    {
        Import-Module -Name $opconmodule -Force
    }
    else
    {
        Write-Host "Unable to import OpCon modules!"
        Exit 100        
    }

    if($agentname)
    { $tag = $agentname }

    $aws = (SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region).PublicIpAddress
    SMA_UpdateAgent -agentname $tag -url $apiaddress -token $apitoken -field "tcpIpAddress" -value $aws
    Start-Sleep -Seconds 2

    $machine = SMA_GetAgent -agentname "$tag" -url $apiaddress -token $apitoken
    $machine[0].availableProperties = $machine[0].availableProperties -eq 0
    $machine[0].availableProperties += ,@(@{name="IP";value=$aws})
    SMA_UpdateAgent -agentname $tag -token $apitoken -url $apiaddress -field "availableProperties" -value $machine[0].availableProperties
}
elseif($option -eq "createinstance")
{
    $awsServer = SMA_CreateAWSInstance -awsimageid $imageid -awsimagename $imagename -awsinstancetype $instancetype -tagvalue $tag -key $keyname

    $counter = 0
    $status = ""
    While(($status -ne "running") -and ($counter -lt 20))
    {
        $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region
        $status = $getinfo.State.Name.Value

        Start-Sleep -Seconds 30
        $counter++
    }

    $getinfo

    if($counter -eq 20)
    {
        Write-Host "Instance took too long to start"
        Exit 105
    }
}
elseif($option -eq "createBlankInstance")
{
    $awsServer = SMA_CreateAWSInstance -awsimageid $imageid -awsimagename $imagename -awsinstancetype $instancetype -tagvalue $tag -key $keyname -isblank "yes"

    $counter = 0
    $status = ""
    While(($status -ne "running") -and ($counter -lt 20))
    {
        $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region
        $status = $getinfo.State.Name.Value

        Start-Sleep -Seconds 30
        $counter++
    }

    $getinfo

    if($counter -eq 20)
    {
        Write-Host "Instance took too long to start"
        Exit 105
    }
}
elseif($option -eq "stopinstance")
{ 
    $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region
    $awsServer = SMA_StopAWSInstance -id $getinfo.InstanceId -region $region

    $counter = 0
    $status = ""
    While(($status -ne "stopped") -and ($counter -lt 40))
    {
        $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region
        $status = $getinfo.State.Name.Value

        Start-Sleep -Seconds 15
        $counter++
    }

    $getinfo

    if($counter -eq 40)
    {
        Write-Host "Instance took too long to stop"
        Exit 105
    }
}
elseif($option -eq "startinstance")
{ 
    $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region
    $awsServer = SMA_StartAWSInstance -id $getinfo.InstanceId -region $region

    $counter = 0
    $status = ""
    While(($status -ne "running") -and ($counter -lt 40))
    {
        $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region
        $status = $getinfo.State.Name.Value

        Start-Sleep -Seconds 15
        $counter++
    }

    $getinfo

    if($counter -eq 40)
    {
        Write-Host "Instance took too long to start"
        Exit 105
    }
}
elseif($option -eq "removeInstance")
{
    $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region
    $remove = SMA_RemoveAWSInstance -id $getinfo.InstanceId -region $region

    $counter = 0
    $status = ""
    While(($status -ne "terminated") -and ($counter -lt 10))
    {
        $getinfo = SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region
        $status = $getinfo.State.Name.Value

        Start-Sleep -Seconds 30
        $counter++
    }

    $getinfo

    if($counter -eq 10)
    {
        Write-Host "Instance removal took too long"
        Exit 105
    }
}
elseif($option -eq "setupProfile")
{
    SMA_SetupAWSProfile -accesskey $accesskey -secretkey $secretkey -profile $profile
}
elseif($option -eq "verifyProfile")
{
    SMA_GetAWSProfiles
}
elseif($option -eq "createImage")
{
    $image = SMA_CreateAWSImage -instancetag $tag -imagename $imagename -imagedescription $imagedescription -region $region
    $image

    $counter = 0
    $status = ""
    While(($status -ne "available") -and ($counter -lt 40))
    {
        $status = (Get-EC2Image -ImageId $image.ImageId -Region $region).State

        Start-Sleep -Seconds 15
        $counter++
    }

    if($counter -eq 40)
    {
        Write-Host "Image creation took too long"
        Exit 105
    }
}
elseif($option -eq "addIp")
{
    try
    {
        $ipRange = [Amazon.EC2.Model.IpRange]@{ CidrIp="$ip/32"; Description="$ipDescription" }
        $ip1 = @{ IpProtocol="tcp"; FromPort="$port"; ToPort="$port"; Ipv4Ranges= $ipRange }
        Grant-EC2SecurityGroupIngress -GroupName "$groupName" -region $region -IpPermission $ip1
    }
    catch [Exception]
    {
        Write-Host $_
        Exit 100
    }
}
elseif($option -eq "removeIp")
{
    try
    {
        $ip = (Get-EC2SecurityGroup -GroupName "$groupName" -region $region).IpPermissions | Where-Object{ $_.Ipv4Ranges.Description -eq "$ipDescription" } | ForEach-Object{
            Revoke-EC2SecurityGroupIngress -GroupName "$groupName" -region $region -IpPermission $_
        }
    }
    catch [Exception]
    {
        Write-Host $_
        Exit 100
    }
}
elseif($option -eq "test")
{
    SMA_GetAWSInstanceByTag -instancetag "$tag" -region $region    
}
else
{
    Write-Host "No -option specified!"
    Exit 999
}