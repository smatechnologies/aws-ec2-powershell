#PowerShell Module file for Amazon Web Services
##################################################################################################
#Needed to get the necessary cmdlet files
#Install-Package -Name AWSPowerShell.NetCore -Source https://www.powershellgallery.com/api/v2/ -ProviderName NuGet -ExcludeVersion -Destination "C:\Program Files (x86)\PowerShell"

#SDK Install needed for AWS PowerShell
#https://aws.amazon.com/powershell/

#Sets up profile/keys so that it doesnt need to be called each time
function OpCon_SetupAWSProfile($accesskey,$secretkey,$profile)
{
    try
    {
        Set-AWSCredential -StoreAs $profile -AccessKey $accesskey -SecretKey $secretkey
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 101
    }
}

#Gets an AWS instance information by tag
function OpCon_CreateAWSImage($instancetag,$imagename,$imagedescription,$region)
{
    try
    {
        $getinfo = (Get-EC2Instance -Region $region).Instances | Where-Object{$_.Tag.Value -eq $instancetag}
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 101
    }

    try
    {
        $newImage = New-EC2Image -InstanceId $getinfo.InstanceId -Name $imagename -Description $imagedescription -Region $region
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 102
    }

    return $newImage
}

#Gets an AWS instance information by tag
function OpCon_GetAWSInstanceByTag($instancetag,$region)
{
    try
    {
        $get = (Get-EC2Instance -Region $region).Instances | Where-Object{($_.Tag.Key -eq "Name") -and ($_.Tag.Value -eq $instancetag)}
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 104
    }

    return $get
}

#Gets an AWS volume information by tag
function OpCon_GetAWSVolumeByTag($tag,$region)
{
    try
    {
        $get = Get-EC2Volume -Region $region | Where-Object{($_.Tag.Key -eq "Name") -and ($_.Tag.Value -eq $tag)}
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 104
    }

    return $get
}

#Creates a new AWS instance based of input image
function OpCon_CreateAWSInstance($awsimageid,$awsimagename,$awsinstancetype,$tagvalue,$key,$region,$isblank)
{
    if($awsimagename)
    {
        if($isblank -ne "yes")
        {
            try
            {
                $awsimageid = (Get-EC2Image -Region $region -Filter @{Name="name";Values="$imagename"}).ImageId 
            }
            catch [Exception]
            {
                Write-Host "Problem getting Image Id with supplied Image Name!"
                Write-Host $_.Exception.Message
                Exit 102
            }
        }
        else
        {
            try
            {
                $awsimageid = (Get-EC2ImageByName $awsimagename).ImageId 
            }
            catch [Exception]
            {
                Write-Host "Problem getting Image Id with supplied Image Name!"
                Write-Host $_.Exception.Message
                Exit 102
            }
        }
    }
    
    try
    {
        $tag1 = @{ Key="Name"; Value="$tagvalue" }
        $tag2 = @{ Key="Name"; Value="$tagvalue" }
        $tagspec1 = New-Object Amazon.EC2.Model.TagSpecification
        $tagspec2 = New-Object Amazon.EC2.Model.TagSpecification
        $tagspec1.ResourceType = "instance"
        $tagspec2.ResourceType = "volume"
        $tagspec1.Tags.Add($tag1)
        $tagspec2.Tags.Add($tag2)
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 102
    }

    try
    {
        $newinstance = New-EC2Instance -ImageId $awsimageid -MaxCount 1 -InstanceType $awsinstancetype -TagSpecification $tagspec1,$tagspec2 -KeyName $key -Region $region
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 103
    }

    Start-Sleep -s 10
    return $newinstance
}

#Creates a new EBS volume
function OpCon_CreateAWSVolume($tag,$region,$volumetype,$volumesize)
{
    $tag = @{ Key="Name"; Value="$tag" }
    $tagspec = new-object Amazon.EC2.Model.TagSpecification
    $tagspec.ResourceType = "volume"
    $tagspec.Tags.Add($tag)

    try
    {
        $zone = Get-EC2AvailabilityZone -Region $region | Where-Object{ $_.State -eq "available" }
        if($zone.Count -gt 0)
        {
            $zonename = $zone[0].ZoneName
        }
        else
        {
            Write-Host "No zones available for volume!"
            Exit 101
        }
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 100
    }

    try
    {
        $volume = New-EC2Volume -Size $volumesize -VolumeType $volumetype -AvailabilityZone $zonename -TagSpecification $tagspec
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 101
    }

    return $volume
}
