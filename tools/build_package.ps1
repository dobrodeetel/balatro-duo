# Build the player package dist\BalatroDuo-<version>.zip from this repo:
#   package\ (installers, readmes, install.ps1) + BalatroDuo\ (the mod) + Lovely 0.9.0.
# Lovely is downloaded from its official GitHub release and checked by SHA-256; its MIT
# license (package\files\LOVELY-LICENSE.md) ships next to it.
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$lovelyUrl = "https://github.com/ethangreen-dev/lovely-injector/releases/download/v0.9.0/lovely-x86_64-pc-windows-msvc.zip"
$lovelySha = "40b994a055ee75e5f2aba81e7ae06f2c17460e18cc346483089921899fadd1f7"
$version = ([regex]::Match((Get-Content "$repo\BalatroDuo\duo.lua" -Raw), "D.VERSION = '([^']+)'")).Groups[1].Value
$name = "BalatroDuo-$version"
$dist = "$repo\dist"
$out = "$dist\$name"
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force $out | Out-Null
Copy-Item "$repo\package\*" $out -Recurse
Copy-Item "$repo\BalatroDuo" "$out\files\BalatroDuo" -Recurse
$zip = "$out\files\lovely-0.9.0-x86_64-pc-windows-msvc.zip"
Invoke-WebRequest $lovelyUrl -OutFile $zip -UseBasicParsing
$sha = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($sha -ne $lovelySha) { throw "Lovely zip SHA-256 $sha, expected $lovelySha" }
if (Test-Path "$dist\$name.zip") { Remove-Item "$dist\$name.zip" }
Compress-Archive -Path $out -DestinationPath "$dist\$name.zip"
"$dist\$name.zip"
