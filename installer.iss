[Setup]
AppId={{8A2D6A62-3B4F-4C8B-9CE3-1A7B9C4D2E10}}
AppName=Loyalty App
AppVersion=1.0.0
AppPublisher=Loyalty App
AppPublisherURL=https://example.com
DefaultDirName={autopf}\Loyalty App
DefaultGroupName=Loyalty App
UninstallDisplayIcon={app}\loyalty_app.exe
OutputDir=installer_output
OutputBaseFilename=LoyaltyApp_Setup_{#SetupSetting("AppVersion")}
SetupIconFile=windows\runner\resources\app_icon.ico
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
Compression=lzma2
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
