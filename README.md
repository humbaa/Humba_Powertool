# Humba_Powertool
Script PowerShell standalone com interface gráfica para automação de formatações, gestão de recursos do Windows e instalação em lote de centenas de programas via Winget e Chocolatey, incluindo pacotes do Microsoft Office 2024


Instalador Automático de Programas (PowerShell GUI) 🚀
Este script em PowerShell foi desenvolvido para otimizar e automatizar o processo de pós-formatação e preparação de ambientes de trabalho no Windows. O script é 100% standalone (não necessita de ficheiros externos) e conta com uma interface gráfica (GUI) baseada em Windows Forms.

✨ Funcionalidades Principais
🛡️ Auto-Elevação de Privilégios: O script deteta automaticamente se está sendo executado como Administrador. Caso não esteja, eleva os seus próprios privilégios e aplica o ExecutionPolicy Bypass de forma transparente.
📦 Instalação de Gerenciadores: Instalação e reparação automática dos módulos do Winget e Chocolatey com apenas um clique.
⚙️ Recursos do Windows: Ativação e desativação de recursos nativos (ex: WSL, Hyper-V, Sandbox, .NET Framework 3.5) diretamente pela interface, com aviso inteligente caso seja necessário reiniciar o sistema.
🏢 Microsoft Office 2024: Aba dedicada para instalação silenciosa e individual de aplitivos do Office 2024 (Excel, Word, Visio, Project, etc.) via Click-To-Run (Chocolatey).
🔑 Ativação de Sistemas: Integração de atalhos para os scripts de ativação seguros (MAS - Microsoft Activation Scripts) para Windows (HWID) e Office (Ohook).
📚 Instalação em Lote (JSON Embutido): Mais de 300 programas organizados por categorias (Navegadores, Utilitários, Desenvolvimento, Multimédia, etc.) em sub-separadores. O usuário pode marcar "Selecionar Tudo" por categoria e instalar dezenas de aplicativos de uma só vez, de forma silenciosa e em segundo plano.
🖥️ Console de Logs Integrado: Acompanhamento visual em tempo real do progresso das instalações, avisos e códigos de erro diretamente na interface.
🛠️ Como usar
Abra o Powershell como Administrador e digite o código:
irm https://tinyurl.com/463ywkez | iex
O script irá solicitar permissão de Administrador (UAC) e abrirá a interface gráfica pronta usar.
⚠️ Requisitos
Windows 10 ou Windows 11.
Acesso à Internet.
