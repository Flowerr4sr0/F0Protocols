param (
    [string]$url
)

# Paths
$allowedFolder = "C:\F0Protocols"
$chromePath    = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Decode function for both %20 and normal spaces
function Decode-Value($value) {
    if ($null -ne $value) {
        return [System.Uri]::UnescapeDataString($value).Replace('+',' ')
    }
    return ""
}

# Function to show notification
function Show-Notification($title, $desc) {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $toastXml = $template
    $toastTextElements = $toastXml.GetElementsByTagName("text")
    $toastTextElements.Item(0).AppendChild($toastXml.CreateTextNode($title)) > $null
    $toastTextElements.Item(1).AppendChild($toastXml.CreateTextNode($desc)) > $null
    $toast = [Windows.UI.Notifications.ToastNotification]::new($toastXml)
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("f0-or Protocol")
    $notifier.Show($toast)
}

# --- Handle query notifications ---
if ($url -match "\?(.*)$") {
    $queryString = $matches[1]
    $params = @{ }
    foreach ($pair in $queryString -split "&") {
        $kv = $pair -split "=",2
        if ($kv.Count -eq 2) {
            $params[$kv[0]] = Decode-Value $kv[1]
        }
    }

    $title = if ($params.ContainsKey("title")) { $params["title"] } else { "Flower_r4sr0 Protocols" }
    $desc  = if ($params.ContainsKey("desc"))  { $params["desc"]  } else { "This is still being built" }

    Show-Notification $title $desc
}
# --- Handle pages ---
elseif ($url -match "f0-or://pages/(.+)$") {
    $relativePath = $matches[1]
    $relativePath = $relativePath -replace "/", "\"  # convert to Windows path

    $fullPath = Join-Path $allowedFolder $relativePath

    # Security: only allow files inside allowed folder
    $fullPath = (Resolve-Path -Path $fullPath -ErrorAction SilentlyContinue)
    if ($fullPath -and $fullPath.Path.StartsWith($allowedFolder)) {
        Start-Process $chromePath $fullPath.Path
    }
    else {
        Show-Notification "f0-or Error" "File not found or not allowed"
    }
}
# --- Default: open index.html ---
else {
    $indexHtml = Join-Path $allowedFolder "index.html"
    Start-Process $chromePath $indexHtml
}
