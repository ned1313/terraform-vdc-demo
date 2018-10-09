<script>
  winrm quickconfig -q & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"}
</script>
<powershell>
  netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
Function Invoke-WindowsApi( 
    [string] $dllName,  
    [Type] $returnType,  
    [string] $methodName, 
    [Type[]] $parameterTypes, 
    [Object[]] $parameters 
    )
{
  ## Begin to build the dynamic assembly 
  $domain = [AppDomain]::CurrentDomain 
  $name = New-Object Reflection.AssemblyName 'PInvokeAssembly' 
  $assembly = $domain.DefineDynamicAssembly($name, 'Run') 
  $module = $assembly.DefineDynamicModule('PInvokeModule') 
  $type = $module.DefineType('PInvokeType', "Public,BeforeFieldInit") 

  $inputParameters = @() 

  for($counter = 1; $counter -le $parameterTypes.Length; $counter++) 
  { 
     $inputParameters += $parameters[$counter - 1] 
  } 

  $method = $type.DefineMethod($methodName, 'Public,HideBySig,Static,PinvokeImpl',$returnType, $parameterTypes) 

  ## Apply the P/Invoke constructor 
  $ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([string]) 
  $attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, $dllName 
  $method.SetCustomAttribute($attr) 

  ## Create the temporary type, and invoke the method. 
  $realType = $type.CreateType() 

  $ret = $realType.InvokeMember($methodName, 'Public,Static,InvokeMethod', $null, $null, $inputParameters) 

  return $ret
}

Function Set-PrivateProfileString( 
    $file, 
    $category, 
    $key, 
    $value) 
{
  ## Prepare the parameter types and parameter values for the Invoke-WindowsApi script 
  $parameterTypes = [string], [string], [string], [string] 
  $parameters = [string] $category, [string] $key, [string] $value, [string] $file 

  ## Invoke the API 
  [void] (Invoke-WindowsApi "kernel32.dll" ([UInt32]) "WritePrivateProfileString" $parameterTypes $parameters)
}

#Add the RemoteAccess Feature
Add-WindowsFeature -Name RemoteAccess -IncludeAllSubFeature -IncludeManagementTools

#Add the S2S VPN component
Install-RemoteAccess -VpnType VpnS2S

#Add an interface to use for the S2S VPN
$InterfaceProps = @{
    Protocol = "IKEv2"
    AuthenticationMethod = "PSKOnly"
    NumberOfTries = "3"
    ResponderAuthenticationMethod = "PSKOnly"
    Name = "${RemoteIPAddress}"
    Destination = "${RemoteIPAddress}"
    IPv4Subnet = "${RemoteSubnet}:2"
    SharedSecret = "${ShareSecret}"
}
Add-VpnS2SInterface @InterfaceProps

Set-VpnServerIPsecConfiguration -EncryptionType MaximumEncryption

Set-VpnS2Sinterface -Name "${RemoteIPAddress}" -InitiateConfigPayload $false -Force

# Set S2S VPN connection to be persistent by editing the router.pbk file (required admin priveleges)
Set-PrivateProfileString $env:windir\System32\ras\router.pbk "${RemoteIPAddress}" "IdleDisconnectSeconds" "0"
Set-PrivateProfileString $env:windir\System32\ras\router.pbk "${RemoteIPAddress}" "RedialOnLinkFailure" "1"

# Restart the RRAS service
Restart-Service RemoteAccess

# Dial-in to Azure gateway
Connect-VpnS2SInterface -Name "${RemoteIPAddress}"

</powershell>