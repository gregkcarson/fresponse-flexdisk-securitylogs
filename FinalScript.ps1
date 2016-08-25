#
#Create Web Client object and setup credentials. SSL/TLS validation callback set to true to avoid error interrupting program.
$wc = New-Object System.Net.WebClient
$username = "test"
$password = "testing123456"
$wc.credentials = new-object system.net.networkcredential($username, $password)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}



Function ConvertFrom-JSON {
    param(
        $json,
        [switch]$raw  
    )

    Begin
    {
    	$script:startStringState = $false
    	$script:valueState = $false
    	$script:arrayState = $false	
    	$script:saveArrayState = $false

    	function scan-characters ($c) {
    		switch -regex ($c)
    		{
    			"{" { 
    				"(New-Object PSObject "
    				$script:saveArrayState=$script:arrayState
    				$script:valueState=$script:startStringState=$script:arrayState=$false				
    			    }
    			"}" { ")"; $script:arrayState=$script:saveArrayState }

    			'"' {
    				if($script:startStringState -eq $false -and $script:valueState -eq $false -and $script:arrayState -eq $false) {
    					'| Add-Member -Passthru NoteProperty "'
    				}
    				else { '"' }
    				$script:startStringState = $true
    			}

    			"[a-z0-9A-Z@.\-\/\&\=\? ]" { $c }

    			":" {" " ;$script:valueState = $true}
    			"," {
    				if($script:arrayState) { "," }
    				else { $script:valueState = $false; $script:startStringState = $false }
    			}	
    			"\[" { "@("; $script:arrayState = $true }
    			"\]" { ")"; $script:arrayState = $false }
    			"[\t\r\n]" {}
    		}
    	}
    	
    	function parse($target)
    	{
    		$result = ""
    		ForEach($c in $target.ToCharArray()) {	
    			$result += scan-characters $c
    		}
    		$result 	
    	}
    }

    Process { 
        if($_) { $result = parse $_ } 
    }

    End { 
        If($json) { $result = parse $json }

        If(-Not $raw) {
            $result | Invoke-Expression
        } else {
            $result 
        }
    }
}


Function Get-Flexds {
   param( 
      $urlstring,
      $username,
      $pass
   )
   Start-Sleep -Seconds 10
   $flexds = Get-WebString $urlstring $username $pass 
   #Converts the JSON listing of volumes to a custom PSCustomObject that has a property for each field in the JSON string.
   $flexdps = ConvertFrom-JSON $flexds 
   $flexdps
}


Function Get-WebString {
  param(
        $url,
        $username,
        $password
        )
		
   $req = [System.Net.HttpWebRequest]::Create($url);
   $req.Credentials = new-object system.net.networkcredential($username, $pass);
   $req.Timeout = -1;
   $res = $req.GetResponse();
   
   if ($res.StatusCode -eq 200){
        [string]$output = ""
        $reader = $res.GetResponseStream()
        [byte[]] $buffer = new-object byte[] 4096
        $encoding = [System.Text.Encoding]::GetEncoding( $res.CharacterSet )
        [int]$total = [int]$count = 0
      do
      {
         $count = $reader.Read($buffer, 0, $buffer.Length);
         $output += $encoding.GetString($buffer,0,$count);
        
         
      } while ($count -gt 0)
      
      $reader.Close()
           
   }
   $res.Close();
   $output;
}




#List of machines to scan
$MachineArray = Get-Content 'C:\Users\admin\Desktop\fresponsestuff\machines.txt'
foreach ($machine in $MachineArray) {
#download initial directory from root volume

$urlstring = "https://"+ $machine + ":3261/flexd?enc=json"

#Passes the URL request to retrieve list of volumes with a username and password for the FResponse service test/testing123456
$flexdps = Get-Flexds $urlstring $username $password

foreach ($fdisk in $flexdps.response.contents){
$tgt = $fdisk.name

#Get listing of Disks
$wc.DownloadFile( "https://"+ $machine + ":3261/flexd?tgt="+$tgt,"rawUNIQUEFILENAME.txt")
$a = [IO.File]::ReadAllText(".\rawUNIQUEFILENAME.txt")
#parse out html values
$a.split('&') > temp.txt

######################Find Windows directory
Select-String .\temp.txt -Pattern name=Windows > temp2.txt
#Get the &node= value preceding the &name=Windows matched line
Get-Content .\temp2.txt | ForEach-Object { $_.split(":")[1]} > rows.txt
#Pull the line number out
$row = Get-Content .\rows.txt -First 1
#Use the line number to find our node value and store the value to craft next URL string
$node = Get-Content .\temp.txt | Select -index $row
$node > final.txt

#####################Find System32 Directory

$wc.DownloadFile( "https://"+ $machine + ":3261/flexd?tgt="+$tgt+"&"+$node+"&name=Windows","rawUNIQUEFILENAME.txt")
$a = [IO.File]::ReadAllText(".\rawUNIQUEFILENAME.txt")
#parse out html values
$a.split('&') > temp.txt
Select-String .\temp.txt -Pattern name=System32 > temp2.txt
#Get the &node= value preceding the &name=Windows matched line
Get-Content .\temp2.txt | ForEach-Object { $_.split(":")[1]} > rows.txt
#Pull the line number out
$row = Get-Content .\rows.txt -First 1
#Use the line number to find our node value and store the value to craft next URL string
$node = Get-Content .\temp.txt | Select -index $row
$node > final.txt

#####################Find winevt Directory

$wc.DownloadFile( "https://"+ $machine + ":3261/flexd?tgt="+$tgt+"&"+$node+"&name=System32","rawUNIQUEFILENAME.txt")
$a = [IO.File]::ReadAllText(".\rawUNIQUEFILENAME.txt")
#parse out html values
$a.split('&') > temp.txt
Select-String .\temp.txt -Pattern name=winevt > temp2.txt
#Get the &node= value preceding the &name=Windows matched line
Get-Content .\temp2.txt | ForEach-Object { $_.split(":")[1]} > rows.txt
#Pull the line number out
$row = Get-Content .\rows.txt -First 1
#Use the line number to find our node value and store the value to craft next URL string
$node = Get-Content .\temp.txt | Select -index $row
$node > final.txt

#####################Find Logs directory

$wc.DownloadFile( "https://"+ $machine + ":3261/flexd?tgt="+$tgt+"&"+$node+"&name=winevt","rawUNIQUEFILENAME.txt")
$a = [IO.File]::ReadAllText(".\rawUNIQUEFILENAME.txt")
#parse out html values
$a.split('&') > temp.txt
Select-String .\temp.txt -Pattern name=Logs > temp2.txt
#Get the &node= value preceding the &name=Windows matched line
Get-Content .\temp2.txt | ForEach-Object { $_.split(":")[1]} > rows.txt
#Pull the line number out
$row = Get-Content .\rows.txt -First 1
#Use the line number to find our node value and store the value to craft next URL string
$node = Get-Content .\temp.txt | Select -index $row
$node > final.txt

#####################Download security log
$wc.DownloadFile( "https://"+ $machine + ":3261/flexd?tgt="+$tgt+"&"+$node+"&name=Logs","rawUNIQUEFILENAME.txt")
$a = [IO.File]::ReadAllText(".\rawUNIQUEFILENAME.txt")
#parse out html values
$a.split('&') > temp.txt
Select-String .\temp.txt -Pattern name=Security.evtx > temp2.txt
#Get the &node= value preceding the &name=Windows matched line
Get-Content .\temp2.txt | ForEach-Object { $_.split(":")[1]} > rows.txt
#Pull the line number out
$row = Get-Content .\rows.txt -First 1
#Use the line number to find our node value and store the value to craft next URL string
$node = Get-Content .\temp.txt | Select -index $row
$node > final.txt

$wc.DownloadFile( "https://"+ $machine + ":3261/flexd?tgt="+$tgt+"&type=data&"+$node+"&name=Security.evtx",$machine + "Security.evtx")
}
}
