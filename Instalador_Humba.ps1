# ==============================================================================
# 1. ELEVAÇÃO AUTOMÁTICA DE PRIVILÉGIOS E POLÍTICA DE EXECUÇÃO
# ==============================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) { $scriptPath = $PSCommandPath }

    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        Exit 
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Falha ao elevar privilégios. Execute como Administrador.", "Erro de Permissão", 0, 16)
        Exit
    }
}

Set-ExecutionPolicy Bypass -Scope Process -Force

# Identifica o diretório atual de forma robusta
$diretorioScript = $PSScriptRoot
if (-not $diretorioScript) { 
    if ($MyInvocation.MyCommand.Path) { $diretorioScript = Split-Path $MyInvocation.MyCommand.Path } 
    else { $diretorioScript = (Get-Location).Path }
}

# ==============================================================================
# 2. INÍCIO DA INTERFACE GRÁFICA
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Humba Automações - Instalador Mestre"
$form.Size = New-Object System.Drawing.Size(540, 780)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# --- CABEÇALHO FIXO COM LOGO ---
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object System.Drawing.Size(540, 100)
$headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$headerPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($headerPanel)

$logoBox = New-Object System.Windows.Forms.PictureBox
$logoBox.Size = New-Object System.Drawing.Size(80, 80)
$logoBox.Location = New-Object System.Drawing.Point(20, 10)
$logoBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage

$caminhoLogo = Join-Path -Path $diretorioScript -ChildPath "util\logo.jpg"
if (Test-Path $caminhoLogo) {
    $logoBox.Image = [System.Drawing.Image]::FromFile($caminhoLogo)
}
$headerPanel.Controls.Add($logoBox)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Humba | Automação e Setup"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::Teal
$lblTitle.Location = New-Object System.Drawing.Point(120, 35)
$lblTitle.AutoSize = $true
$headerPanel.Controls.Add($lblTitle)

# Controle de Abas
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(0, 100)
$tabControl.Size = New-Object System.Drawing.Size(525, 640)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($tabControl)

# ==============================================================================
# ABA 1: PREPARAÇÃO (Gerenciadores)
# ==============================================================================
$tabPrep = New-Object System.Windows.Forms.TabPage
$tabPrep.Text = "1. Preparação"
$tabPrep.BackColor = [System.Drawing.Color]::White
$tabControl.Controls.Add($tabPrep)

$lblPrepInfo = New-Object System.Windows.Forms.Label
$lblPrepInfo.Text = "Instale os gerenciadores de pacotes necessários antes de prosseguir."
$lblPrepInfo.Location = New-Object System.Drawing.Point(15, 15)
$lblPrepInfo.AutoSize = $true
$tabPrep.Controls.Add($lblPrepInfo)

$btnWinget = New-Object System.Windows.Forms.Button
$btnWinget.Text = "Instalar Winget"
$btnWinget.Location = New-Object System.Drawing.Point(15, 45)
$btnWinget.Size = New-Object System.Drawing.Size(480, 45)
$btnWinget.BackColor = [System.Drawing.Color]::LightBlue
$btnWinget.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$tabPrep.Controls.Add($btnWinget)

$btnChoco = New-Object System.Windows.Forms.Button
$btnChoco.Text = "Instalar Chocolatey"
$btnChoco.Location = New-Object System.Drawing.Point(15, 100)
$btnChoco.Size = New-Object System.Drawing.Size(480, 45)
$btnChoco.BackColor = [System.Drawing.Color]::BurlyWood
$btnChoco.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$tabPrep.Controls.Add($btnChoco)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(15, 160)
$txtLog.Size = New-Object System.Drawing.Size(480, 430)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.BackColor = [System.Drawing.Color]::Black
$txtLog.ForeColor = [System.Drawing.Color]::LightGreen
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Text = "Aguardando comandos...`r`n"
$tabPrep.Controls.Add($txtLog)

$btnWinget.Add_Click({
    $btnWinget.Enabled = $false
    $txtLog.AppendText("`r`n[+] Iniciando instalação do módulo Winget...`r`n"); $form.Refresh()
    try {
        $ProgressPreference = 'SilentlyContinue'
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -AcceptLicense | Out-Null
        Repair-WinGetPackageManager -AllUsers | Out-Null
        $txtLog.AppendText("[SUCESSO] Winget instalado/reparado com sucesso!`r`n")
    } catch { $txtLog.AppendText("[ERRO] Falha ao instalar Winget: $_`r`n") }
    $btnWinget.Enabled = $true
})

$btnChoco.Add_Click({
    $btnChoco.Enabled = $false
    $txtLog.AppendText("`r`n[+] Iniciando instalação do Chocolatey...`r`n"); $form.Refresh()
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) | Out-Null
        $txtLog.AppendText("`r`n[SUCESSO] Chocolatey instalado com sucesso!`r`n")
    } catch { $txtLog.AppendText("[ERRO] Falha ao instalar Chocolatey: $_`r`n") }
    $btnChoco.Enabled = $true
})

# ==============================================================================
# ABA 2: RECURSOS DO WINDOWS
# ==============================================================================
$tabRecursos = New-Object System.Windows.Forms.TabPage
$tabRecursos.Text = "2. Recursos do Windows"
$tabRecursos.BackColor = [System.Drawing.Color]::White
$tabControl.Controls.Add($tabRecursos)

$lblRecursos = New-Object System.Windows.Forms.Label
$lblRecursos.Text = "Selecione os recursos que deseja ativar ou desativar:"
$lblRecursos.Location = New-Object System.Drawing.Point(15, 15)
$lblRecursos.AutoSize = $true
$tabRecursos.Controls.Add($lblRecursos)

$recursosWindows = [ordered]@{
    ".NET Framework 3.5 (Inclui .NET 2.0 e 3.0)" = "NetFx3"
    "Subsistema do Windows para Linux (WSL)"    = "Microsoft-Windows-Subsystem-Linux"
    "Plataforma de Máquina Virtual (Para WSL2)" = "VirtualMachinePlatform"
    "Hyper-V (Plataforma e Ferramentas)"        = "Microsoft-Hyper-V-All"
    "Área Restrita do Windows (Sandbox)"        = "Containers-DisposableClientVM"
    "Serviços de Informações da Internet (IIS)" = "IIS-WebServerRole"
}

$chkRecursos = New-Object System.Windows.Forms.CheckedListBox
$chkRecursos.Location = New-Object System.Drawing.Point(15, 45)
$chkRecursos.Size = New-Object System.Drawing.Size(480, 480)
$chkRecursos.CheckOnClick = $true
foreach ($rec in $recursosWindows.Keys) { $chkRecursos.Items.Add($rec) | Out-Null }
$tabRecursos.Controls.Add($chkRecursos)

$btnAtivarRecurso = New-Object System.Windows.Forms.Button
$btnAtivarRecurso.Text = "Ativar Selecionados"
$btnAtivarRecurso.Location = New-Object System.Drawing.Point(15, 545)
$btnAtivarRecurso.Size = New-Object System.Drawing.Size(235, 45)
$btnAtivarRecurso.BackColor = [System.Drawing.Color]::LightGreen
$btnAtivarRecurso.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$tabRecursos.Controls.Add($btnAtivarRecurso)

$btnDesativarRecurso = New-Object System.Windows.Forms.Button
$btnDesativarRecurso.Text = "Desativar Selecionados"
$btnDesativarRecurso.Location = New-Object System.Drawing.Point(260, 545)
$btnDesativarRecurso.Size = New-Object System.Drawing.Size(235, 45)
$btnDesativarRecurso.BackColor = [System.Drawing.Color]::LightCoral
$btnDesativarRecurso.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$tabRecursos.Controls.Add($btnDesativarRecurso)

function Processar-Recursos ($Acao) {
    $selecionados = $chkRecursos.CheckedItems
    if ($selecionados.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Selecione ao menos um recurso.", "Aviso", 0, 48)
        return
    }

    $btnAtivarRecurso.Enabled = $false
    $btnDesativarRecurso.Enabled = $false
    $chkRecursos.Enabled = $false
    $precisaReiniciar = $false

    foreach ($nome in $selecionados) {
        $featureName = $recursosWindows[$nome]
        try {
            if ($Acao -eq "Ativando") {
                $resultado = Enable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -All
            } else {
                $resultado = Disable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart
            }
            if ($resultado.RestartNeeded) { $precisaReiniciar = $true }
        } catch { Write-Host "Erro: $_" }
    }
    
    $msgFinal = "Processo concluído!"
    if ($precisaReiniciar) { $msgFinal += " Você precisará reiniciar o computador." }
    [System.Windows.Forms.MessageBox]::Show($msgFinal, "Aviso", 0, 64)

    $btnAtivarRecurso.Enabled = $true
    $btnDesativarRecurso.Enabled = $true
    $chkRecursos.Enabled = $true
}

$btnAtivarRecurso.Add_Click({ Processar-Recursos "Ativando" })
$btnDesativarRecurso.Add_Click({ Processar-Recursos "Desativando" })


# ==============================================================================
# ABA 3: INSTALAÇÃO DE PROGRAMAS (Corrigido Escopo e Adicionado Terminal)
# ==============================================================================
$tabApps = New-Object System.Windows.Forms.TabPage
$tabApps.Text = "3. Instalar Programas"
$tabApps.BackColor = [System.Drawing.Color]::White
$tabControl.Controls.Add($tabApps)

$btnCarregar = New-Object System.Windows.Forms.Button
$btnCarregar.Text = "Carregar Lista (util\programas.json)"
$btnCarregar.Location = New-Object System.Drawing.Point(15, 15)
$btnCarregar.Size = New-Object System.Drawing.Size(480, 40)
$btnCarregar.BackColor = [System.Drawing.Color]::LightGoldenrodYellow
$tabApps.Controls.Add($btnCarregar)

# Reduzimos um pouco as abas para caber o log abaixo
$tabCategorias = New-Object System.Windows.Forms.TabControl
$tabCategorias.Location = New-Object System.Drawing.Point(15, 65)
$tabCategorias.Size = New-Object System.Drawing.Size(480, 275)
$tabApps.Controls.Add($tabCategorias)

# Terminal de Logs da Aba 4
$txtLogApps = New-Object System.Windows.Forms.TextBox
$txtLogApps.Location = New-Object System.Drawing.Point(15, 350)
$txtLogApps.Size = New-Object System.Drawing.Size(480, 150)
$txtLogApps.Multiline = $true
$txtLogApps.ScrollBars = "Vertical"
$txtLogApps.ReadOnly = $true
$txtLogApps.BackColor = [System.Drawing.Color]::Black
$txtLogApps.ForeColor = [System.Drawing.Color]::LightGreen
$txtLogApps.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLogApps.Text = "Aguardando inicialização do painel de instalações...`r`n"
$tabApps.Controls.Add($txtLogApps)

$btnInstalar = New-Object System.Windows.Forms.Button
$btnInstalar.Text = "Instalar Programas Selecionados"
$btnInstalar.Location = New-Object System.Drawing.Point(15, 510)
$btnInstalar.Size = New-Object System.Drawing.Size(480, 45)
$btnInstalar.BackColor = [System.Drawing.Color]::LightSkyBlue
$btnInstalar.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnInstalar.Enabled = $false
$tabApps.Controls.Add($btnInstalar)

$statusApps = New-Object System.Windows.Forms.Label
$statusApps.Location = New-Object System.Drawing.Point(15, 570)
$statusApps.Size = New-Object System.Drawing.Size(480, 40)
$statusApps.Text = "Status: Aguardando lista..."
$statusApps.ForeColor = [System.Drawing.Color]::Gray
$tabApps.Controls.Add($statusApps)

# [CORREÇÃO AQUI]: Declarando as variáveis com $script: para não se perderem!
$script:globalAppMap = @{}
$script:listaCheckboxes = @()

$appToolTip = New-Object System.Windows.Forms.ToolTip
$appToolTip.AutoPopDelay = 10000
$appToolTip.InitialDelay = 500
$appToolTip.ReshowDelay = 100
$appToolTip.ShowAlways = $true

$btnCarregar.Add_Click({
    $caminhoJSON = Join-Path -Path $diretorioScript -ChildPath "util\programas.json"

    if (Test-Path $caminhoJSON) {
        try {
            $jsonContent = Get-Content -Path $caminhoJSON -Raw -Encoding UTF8
            $appsData = $jsonContent | ConvertFrom-Json
            
            $tabCategorias.TabPages.Clear()
            
            # Limpa e reinicia as variáveis globais do script
            $script:listaCheckboxes = @()
            $script:globalAppMap.Clear()
            
            $categorias = $appsData | Select-Object -ExpandProperty Categoria -Unique | Where-Object { ![string]::IsNullOrWhiteSpace($_) -and $_ -ne '-' }

            foreach ($cat in $categorias) {
                $tabPageCat = New-Object System.Windows.Forms.TabPage
                $tabPageCat.Text = $cat
                $tabPageCat.BackColor = [System.Drawing.Color]::White
                $tabCategorias.Controls.Add($tabPageCat)
                
                $btnCheckAll = New-Object System.Windows.Forms.Button
                $btnCheckAll.Text = "Marcar/Desmarcar Tudo nesta Aba"
                $btnCheckAll.Dock = [System.Windows.Forms.DockStyle]::Top
                $btnCheckAll.Height = 30
                $btnCheckAll.BackColor = [System.Drawing.Color]::LightGray
                $tabPageCat.Controls.Add($btnCheckAll)

                $chkList = New-Object System.Windows.Forms.CheckedListBox
                $chkList.Dock = [System.Windows.Forms.DockStyle]::Fill
                $chkList.CheckOnClick = $true
                $chkList.Tag = New-Object PSObject -Property @{ LastIndex = -1 }
                $tabPageCat.Controls.Add($chkList)
                $chkList.BringToFront()
                
                # Salvando a lista atual no escopo do SCRIPT
                $script:listaCheckboxes += $chkList

                $chkList.add_MouseMove({
                    param($sender, $e)
                    $idx = $sender.IndexFromPoint($e.Location)
                    if ($idx -ne -1 -and $idx -ne $sender.Tag.LastIndex) {
                        $sender.Tag.LastIndex = $idx
                        $itemText = $sender.Items[$idx].ToString()
                        $desc = $script:globalAppMap[$itemText].Descricao
                        if ([string]::IsNullOrWhiteSpace($desc) -or $desc -eq '-') { $desc = "Sem descrição disponível." }
                        $appToolTip.SetToolTip($sender, $desc)
                    } elseif ($idx -eq -1 -and $sender.Tag.LastIndex -ne -1) {
                        $sender.Tag.LastIndex = -1
                        $appToolTip.SetToolTip($sender, "")
                    }
                })

                $btnCheckAll.Add_Click({
                    param($sender, $e)
                    $lista = $sender.Parent.Controls | Where-Object { $_.GetType().Name -eq 'CheckedListBox' }
                    if ($lista.Items.Count -gt 0) {
                        $novoEstado = -not $lista.GetItemChecked(0)
                        for ($i = 0; $i -lt $lista.Items.Count; $i++) { $lista.SetItemChecked($i, $novoEstado) }
                    }
                })

                $appsDaCat = $appsData | Where-Object { $_.Categoria -eq $cat }
                foreach ($app in $appsDaCat) {
                    $nome = $app.Nome
                    $cmdWinget = $app.'Comando Winget'
                    $cmdChoco = $app.'Comando Chocolatey'

                    if ($cmdWinget -ne "-" -and ![string]::IsNullOrWhiteSpace($cmdWinget)) {
                        $id = $cmdWinget -replace '(?i)winget install\s+', '' -replace '"', ''
                        $nomeDisplay = "$nome (Winget)"
                        $script:globalAppMap[$nomeDisplay] = @{ Tipo = 'Winget'; ID = $id.Trim(); Descricao = $app.Descrição }
                        $chkList.Items.Add($nomeDisplay) | Out-Null
                    }
                    elseif ($cmdChoco -ne "-" -and ![string]::IsNullOrWhiteSpace($cmdChoco)) {
                        $id = $cmdChoco -replace '(?i)choco install\s+', '' -replace '"', ''
                        $nomeDisplay = "$nome (Choco)"
                        $script:globalAppMap[$nomeDisplay] = @{ Tipo = 'Choco'; ID = $id.Trim(); Descricao = $app.Descrição }
                        $chkList.Items.Add($nomeDisplay) | Out-Null
                    }
                }
            }
            $btnInstalar.Enabled = $true
            $statusApps.Text = "Pronto para instalar."
            $statusApps.ForeColor = [System.Drawing.Color]::Green
            $txtLogApps.AppendText("JSON carregado com sucesso!`r`nSelecione os programas e clique em Instalar.`r`n")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erro ao ler JSON.", "Erro", 0, 16)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Arquivo JSON não encontrado na pasta 'util'!", "Erro de Arquivo", 0, 48)
    }
})

$form.Add_Load({
    $caminhoJSON = Join-Path -Path $diretorioScript -ChildPath "util\programas.json"
    if (Test-Path $caminhoJSON) { $btnCarregar.PerformClick() }
})

$btnInstalar.Add_Click({
    $selecionados = 0
    foreach ($chkList in $script:listaCheckboxes) { $selecionados += $chkList.CheckedItems.Count }

    if ($selecionados -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Selecione ao menos um programa.", "Aviso", 0, 48)
        return
    }

    $btnInstalar.Enabled = $false
    $tabCategorias.Enabled = $false
    $txtLogApps.AppendText("`r`n[=] INICIANDO FILA DE INSTALAÇÃO ($selecionados programas) [=]`r`n")

    foreach ($chkList in $script:listaCheckboxes) {
        foreach ($item in $chkList.CheckedItems) {
            $nomeDisplay = $item.ToString()
            $dados = $script:globalAppMap[$nomeDisplay]
            
            if ($dados) {
                $id = $dados.ID
                $statusApps.Text = "Instalando: $nomeDisplay..."
                $statusApps.ForeColor = [System.Drawing.Color]::Blue
                $txtLogApps.AppendText("`r`n[+] Instalando: $nomeDisplay... ")
                $txtLogApps.ScrollToCaret()
                $form.Refresh()

                try {
                    if ($dados.Tipo -eq 'Winget') {
                        $proc = Start-Process -FilePath "winget" -ArgumentList "install --id `"$id`" --exact --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru -NoNewWindow
                    }
                    elseif ($dados.Tipo -eq 'Choco') {
                        $proc = Start-Process -FilePath "choco" -ArgumentList "install `"$id`" -y" -Wait -PassThru -NoNewWindow
                    }
                    
                    if ($proc.ExitCode -in 0, 1641, 3010) { $txtLogApps.AppendText("OK!") }
                    else { $txtLogApps.AppendText("Aviso/Erro (Código: $($proc.ExitCode))") }
                } catch {
                    $txtLogApps.AppendText("FALHA DE EXECUÇÃO!")
                }
            }
        }
    }
    
    $statusApps.Text = "Fila de instalações concluída!"
    $statusApps.ForeColor = [System.Drawing.Color]::Green
    $txtLogApps.AppendText("`r`n`r`n[=] TODAS AS TAREFAS FINALIZADAS! [=]`r`n")
    $txtLogApps.ScrollToCaret()
    
    [System.Windows.Forms.MessageBox]::Show("Processo de instalação em lote finalizado!", "Concluído", 0, 64)
    
    $btnInstalar.Enabled = $true
    $tabCategorias.Enabled = $true
})

$form.ShowDialog() | Out-Null
