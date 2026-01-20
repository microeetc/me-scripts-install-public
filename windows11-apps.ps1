winget install -e --id Git.Git --accept-package-agreements
winget install -e --id JGraph.Draw --accept-package-agreements
winget install -e --id dbeaver.dbeaver --accept-package-agreements

winget install -e --id Google.Chrome --accept-package-agreements
winget install -e --id Mozilla.Firefox --accept-package-agreements
winget install -e --id Microsoft.PowerToys --accept-package-agreements
winget install -e --id Skillbrains.Lightshot --accept-package-agreements

winget install -e --id WireGuard.WireGuard --accept-package-agreements
winget install Microsoft.VisualStudioCode --accept-package-agreements
winget install --id Microsoft.Powershell --source winget --accept-package-agreements
winget install -e --id PuTTY.PuTTY  --accept-package-agreements
winget install -e --id 7zip.7zip --accept-package-agreements
winget install -e --id Postman.Postman --accept-package-agreements
winget install -e --id Mikrotik.Winbox
winget install -e --id=Microsoft.RemoteDesktopClient
winget install -e --id=OpenVPNTechnologies.OpenVPN

winget install -e --id Python.Python.3.11
winget list --name python

Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
Enable-WindowsOptionalFeature -FeatureName "Containers-DisposableClientVM" -All -Online

wsl --install
wsl --list --online
wsl --install -d Debian
wsl --install -d kali-linux
wsl -l -v


# Advanced settings configuration in WSL | Microsoft Learn
# C:\Users\aferreira> notepad .wslconfig

# [wsl2]
# memory=4GB
# processors=2
# swap=1GB
# localhostForwarding=true


# Winget install -e --id Docker.DockerDesktop --accept-package-agreements


winget uninstall --id Microsoft.GamingServices
winget uninstall --name 'Xbox'
winget uninstall --name 'Xbox TCUI'
winget uninstall --name 'Xbox Game Bar Plugin'
winget uninstall --name 'Game Bar'
winget uninstall --name 'Xbox Identity Provider'
winget uninstall --name 'Xbox Game Speech Window'
winget uninstall --name 'Cortana'
winget uninstall --id Microsoft.BingNews #Notícias
winget uninstall --id Microsoft.BingWeather #MSN Clima
winget uninstall --id Microsoft.WindowsFeedbackHub #Hub de Comentários
winget uninstall --id Microsoft.windowscommunicationsapps #Email e Calendário


winget uninstall --id WuhanNetPowerTechnologyCo.3322537A536FD_63m8b6nby1dvp #descompactar