#PowerShell Module file for Amazon Web Services

function SMA_AWSVersion
{
    Write-Host "****************"
    Write-Host "AWS Version 1.0"
    Write-host "****************"
}

##################################################################################################
#Needed to get the necessary cmdlet files
#Install-Package -Name AWSPowerShell.NetCore -Source https://www.powershellgallery.com/api/v2/ -ProviderName NuGet -ExcludeVersion -Destination "C:\Program Files (x86)\PowerShell"

#SDK Install needed for AWS PowerShell
#https://aws.amazon.com/powershell/

#Sets up profile/keys so that it doesnt need to be called each time
function SMA_SetupAWSProfile($accesskey,$secretkey,$profile)
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


#Sets up profile/keys so that it doesnt need to be called each time
function SMA_GetAWSProfiles()
{
    try
    {
        $profiles = Get-AWSCredential -ListProfileDetail
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 101
    }

    if($profiles.Count -eq 0)
    {
        Write-Host "No AWS credentials stored on this account"
        Exit 999
    }

    return $profiles
}

#Gets an AWS instance information by tag
function SMA_CreateAWSImage($instancetag,$imagename,$imagedescription,$region)
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

#Stops an AWS Instance
function SMA_StopAWSInstance($id,$region)
{
    try
    {
        $stop = Stop-EC2Instance -InstanceId $id -Region $region
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 104
    }
}

#Starts an AWS Instance
function SMA_StartAWSInstance($id,$region)
{
    try
    {
        $start = Start-EC2Instance -InstanceId $id -Region $region
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 104
    }
}

#Removes an AWS Instance
function SMA_RemoveAWSInstance($id,$region)
{
    try
    {
        $remove = Remove-EC2Instance -InstanceId $id -Region $region -Force 
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 104
    }
}

#Restarts an AWS instance
function SMA_RestartAWSInstance($id,$region)
{
    try
    {
        $restart = Restart-EC2Instance -InstanceId $id -Region $region -Force 
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 104
    }
}

#Gets information about an instance based off the id
function SMA_GetAWSInstanceById($id,$region)
{
    try
    {
        $get = Get-EC2Instance -InstanceId $id -Region $region
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 104
    }
    return $get
}

#Gets an AWS instance information by tag
function SMA_GetAWSInstanceByTag($instancetag,$region)
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
function SMA_GetAWSVolumeByTag($tag,$region)
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
function SMA_CreateAWSInstance($awsimageid,$awsimagename,$awsinstancetype,$tagvalue,$key,$region,$isblank)
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
function SMA_CreateAWSVolume($tag,$region,$volumetype,$volumesize)
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

#Creates a keypair that is necessary to be able to login to AWS Instances
function SMA_CreateAWSKeyPair($key,$region)
{
    try
    {
        $keypair = New-EC2KeyPair -KeyName $key -Region $region
    }
    catch [Exception]
    {
        Write-Host $_.Exception.Message
        Exit 101
    }

    return $keypair
}
