[Setup]
AppName=Loyalty App
AppVersion=1.0.0
AppPublisher=Your Company
DefaultDirName={autopf}\LoyaltyApp
DefaultGroupName=Loyalty App
OutputDir=installer_output
OutputBaseFilename=LoyaltyApp_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Loyalty App"; Filename: "{app}\loyalty_app.exe"
Name: "{group}\Uninstall Loyalty App"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Loyalty App"; Filename: "{app}\loyalty_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\loyalty_app.exe"; Description: "Launch Loyalty App"; Flags: nowait postinstall skipifsilent