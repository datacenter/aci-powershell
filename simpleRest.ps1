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
try { $r = Invoke-WebRequest -Uri $url -Method Post -SessionVariable s -Body $creds
    } catch {
              $retcode = $_.Exception.Response.StatusCode.Value__
              Write-Host "Login failure. HTTP response code is $retcode"
              Break   
            }

$cookies = $s.Cookies.GetCookies($url)
Write-Host "Login successful. APIC cookie is $cookies"

# How to HTTP GET something from APIC

Write-Host "Retrieving list of tenants on ACI"
$tenanturl = $baseurl + "/api/node/class/fvTenant.json?"
$web = new-object net.webclient
$web.Headers.add("Cookie", $cookies)
$result = $web.DownloadString($tenanturl)
$resultjson = $result | ConvertFrom-Json
$tenants = New-Object System.Collections.ArrayList
foreach( $tenant in $resultjson.imdata ) 
{
    $tenant = $tenant.fvTenant.attributes.name
    $tenants.add($tenant) > $null
    Write-Host $tenant
}

# How to HTTP POST something to APIC

if ( $tenants -contains "sample" )
{
    Write-Host "Tenant sample already exists. Not creating it again."
    Break
}
Write-Host "Now creating a new tenant called sample on APIC"
$newtenanturl = $baseurl + "/api/node/mo/uni/tn-sample.json"
$jsonpayload = @'
    {"fvTenant":
      {"attributes":
        {"dn":"uni/tn-sample","name":"sample","rn":"tn-sample","status":"created"
        },
       "children":
         [{"fvCtx":
            {"attributes":
              {"dn":"uni/tn-sample/ctx-vrf-1","name":"vrf-1","rn":"ctx-vrf-1","status":"created"
              },
             "children":[]
            }
          }
         ]
      }
    }
'@
$response = $web.UploadString($newtenanturl,$jsonpayload)

