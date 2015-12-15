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

# How to HTTP GET something from APIC

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

# How to HTTP POST something to APIC

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

