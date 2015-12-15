#
# Create a user and attach OpflexAgent cert to that user
#

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

# Get a list of tenants, just to make sure APIC connectivity is fine

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

# Create user joe first
$urlforjoe = $baseurl + "/api/node/mo/uni/userext/user-joe.json"
$jsonpayload = @'
{"aaaUser":{"attributes":{"dn":"uni/userext/user-joe","name":"joe","pwd":"cisco123","rn":"user-joe","status":"created"},"children":[{"aaaUserDomain":{"attributes":{"dn":"uni/userext/user-joe/userdomain-all","name":"all","rn":"userdomain-all","status":"created,modified"},"children":[{"aaaUserRole":{"attributes":{"dn":"uni/userext/user-joe/userdomain-all/role-admin","name":"admin","privType":"writePriv","rn":"role-admin","status":"created,modified"},"children":[]}}]}}]}}
'@
$response = $web.UploadString($urlforjoe,$jsonpayload)

# Add Opflex cert to user Joe now
$newtenanturl = $baseurl + "/api/node/mo/uni/userext/user-joe/usercert-OpflexAgent.json"
$jsonpayload = @'
{"aaaUserCert":{"attributes":{"dn":"uni/userext/user-joe/usercert-OpflexAgent","data":"-----BEGIN CERTIFICATE-----\nMIIDqjCCApKgAwIBAgIQab7dhGQFVbxF55xfT0FlMjANBgkqhkiG9w0BAQ0FADBjMSEwHwYJKoZI\nhvcNAQkBFhJqb2V6ZXJza0BjaXNjby5jb20xDjAMBgNVBAoMBUlOU0JVMQswCQYDVQQIDAJOSDEL\nMAkGA1UEBhMCTkwxFDASBgNVBAMMC09wZmxleEFnZW50MB4XDTE1MDEwMTAwMDAwMFoXDTIwMDEw\nMTAwMDAwMFowYzEhMB8GCSqGSIb3DQEJARYSam9lemVyc2tAY2lzY28uY29tMQ4wDAYDVQQKDAVJ\nTlNCVTELMAkGA1UECAwCTkgxCzAJBgNVBAYTAk5MMRQwEgYDVQQDDAtPcGZsZXhBZ2VudDCCASIw\nDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANIJ9hRh+5+qNIWBWV1pHcDEDoF7L1udeaHLqL2W\n1C9s7xRSHz5tcmyWM83vxFWo1YSaOHX5XPA7feawjfTg5CWKyuAmDAXQOxmq5+atWcdoPCAiVNvk\nrtHniya/i8UVCXI2eKu5yZfVgWX3L3x95x8pjU1QOzQMxmbzXPBXG9NjdBL8rorPlRklsizW/9b1\nCdrEj2mVccZmbDXsZz+/UrgJprKVKLhR0olNwecQc+QrGrZ1ut/jKRjJQaWEhPfs/w9jxbAiEQqk\nnKbR6yOrWKxBbdBq6qUfnnXKUWfQTxvlcGfkwTedZKyXjA9YTWP/nzmbt0EISiou8mWC/+bai98C\nAwEAAaNaMFgwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEFBQcDATAdBgNVHQ4E\nFgQUXi6SxSaSX18jUcvL/877dVU4zXQwDgYDVR0PAQH/BAQDAgEGMA0GCSqGSIb3DQEBDQUAA4IB\nAQBwBSeHgDxUKkcpFaKBbU2trm1IHRUbRzAYm61I5jiHF0UVrVHQCnMDLGoZ5Sc7ixvtHBD1gZgK\ntPK35+jtH/CKPiXWX9hUE+7kd+79FvhhwcODk3oRy/ttaC8ImBF65wnsHUwbNrknhiTIEyHB0gig\nMMiXg0Qhr2aErCpHOgMd1Oi3zpSs673flT8XOoOqbf2z3YM2fcOns7OeUgCUMBVIN4AxU17mSsm2\nJzZ5I7cL0Po1SC3k+MD2panHTG7uLKM+IdHjILk/rpwUWMd6VrlLQ3CsvEUmron4jEJUSAIIbwfG\n61jkZ3EZIPpIGYDr2lQPJ4zhwjH8mJOpantyGNX7\n-----END CERTIFICATE-----\n\n","name":"OpflexAgent","rn":"usercert-OpflexAgent","status":"created"},"children":[]}}
'@
$response = $web.UploadString($newtenanturl,$jsonpayload)

