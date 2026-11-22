$root = Join-Path $PSScriptRoot "reels-studyosu"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:8765/")
$listener.Start()
Write-Host "Serving $root on http://127.0.0.1:8765/"
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response
  try {
    $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath).TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($path)) { $path = "index.html" }
    $file = Join-Path $root $path
    if (Test-Path -LiteralPath $file -PathType Leaf) {
      $bytes = [IO.File]::ReadAllBytes($file)
      switch ([IO.Path]::GetExtension($file).ToLowerInvariant()) {
        ".html" { $res.ContentType = "text/html; charset=utf-8" }
        ".js"   { $res.ContentType = "application/javascript; charset=utf-8" }
        ".css"  { $res.ContentType = "text/css; charset=utf-8" }
        ".json" { $res.ContentType = "application/json; charset=utf-8" }
        ".webmanifest" { $res.ContentType = "application/manifest+json; charset=utf-8" }
        ".png"  { $res.ContentType = "image/png" }
        ".jpg"  { $res.ContentType = "image/jpeg" }
        ".jpeg" { $res.ContentType = "image/jpeg" }
        ".svg"  { $res.ContentType = "image/svg+xml" }
        default { $res.ContentType = "application/octet-stream" }
      }
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $msg = [Text.Encoding]::UTF8.GetBytes("Not found")
      $res.ContentLength64 = $msg.Length
      $res.OutputStream.Write($msg, 0, $msg.Length)
    }
  } catch {
    try { $res.StatusCode = 500 } catch {}
  } finally {
    try { $res.Close() } catch {}
  }
}
