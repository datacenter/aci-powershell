# super simple powershell for ACI
# first, we log in, we extract the cookie
# and use it for subsequent requests

param (
  [parameter(Mandatory=$true,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$username,
  [parameter(Mandatory=$true,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$password,
  [parameter(Mandatory=$true,ValueFromPipeLine=$true,ValueFromPipeLineByPropertyName=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$apic
  )

$creds = '<aaaUser name="' + $username + '" pwd="' + $password + '"/>'
$baseurl = "http://" + $apic
$url = $baseurl + "/api/aaaLogin.xml"
$r = Invoke-RestMethod -Uri $url -Method Post -SessionVariable s -Body $creds
$cookies = $s.Cookies.GetCookies($url)

$tenanturl = $baseurl + "/api/node/class/fvTenant.json?"
$web = new-object net.webclient
$web.Headers.add("Cookie", $cookies)
$result = $web.DownloadString($tenanturl)
$resultjson = $result | ConvertFrom-Json
foreach( $tenant in $resultjson.imdata ) 
{
    $tn = "Found tenant " + $tenant.fvTenant.attributes.name
    write $tn
}
