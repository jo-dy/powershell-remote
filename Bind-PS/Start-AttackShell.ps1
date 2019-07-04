Function Start-AttackShell{
  $rhost = "localhost"
  $rport = "4444"
  $keep_going = $true
  $buffer_size = 4096
  try{
    $client = New-Object System.Net.Sockets.TCPClient($rhost, $rport)
    Write-Host " [*] Connected"
  }catch{
    Write-Host " [*] Connection Failed"
    return
  }
  $stream = $client.GetStream()
  $bytes = New-Object System.Byte[] $buffer_size
  while($keep_going){
    Start-Sleep -Milliseconds 250
    while($stream.DataAvailable){
      $n_recv = $stream.Read($bytes, 0, $buffer_size)
      $data = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $n_recv)
      Write-Host -NoNewLine $data
    }
    $command = Read-Host
    if($command -eq "quit"){
      $keep_going = $false
    }
    $command = [System.Text.Encoding]::ASCII.GetBytes($command)
    $stream.Write($command, 0, $command.Length)
    $stream.Flush()
  }
  $stream.Close()
  $client.Close()
}

 Start-AttackShell
