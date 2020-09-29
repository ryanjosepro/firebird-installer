unit Installation;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, Vcl.Dialogs, Vcl.Controls, IniFiles,
  IOUtils, ShellApi, Windows, Zip, Vcl.Forms, Vcl.StdCtrls,
  MyUtils, MyDialogs;

type
  TVersion = (vrFb21 = 0, vrFb25 = 1, vrFb30 = 2, vrFb40 = 3);

  TInstallConfig = class
  strict private
    FVersion: TVersion;
    FPath: string;
    FServiceName: string;
    FPort: string;
    FDllPaths: TStringList;
    FLog: TMemo;
    procedure SetVersion(const Value: TVersion);
    procedure SetPath(const Value: string);
    procedure SetServiceName(const Value: string);
    procedure SetPort(const Value: string);
    procedure SetDllPaths(const Value: TStringList);
    procedure SetLog(const Value: TMemo);

    function FolderName: string;
    function DllName: string;
    function ResourceName: string;
  public
    property Version: TVersion read FVersion write SetVersion;
    property Path: string read FPath write SetPath;
    property ServiceName: string read FServiceName write SetServiceName;
    property Port: string read FPort write SetPort;
    property DllPaths: TStringList read FDllPaths write SetDllPaths;
    property Log: TMemo read FLog write SetLog;

    function PathBin: string;
    function PathConf: string;
    function Source(Extract: boolean = true): string;
    function SourceBin(Extract: boolean = false): string;
    function SourceDll: string;
  end;

  TInstallation = class
  private
    Configs: TInstallConfig;
    procedure Log(Text: string);
  public
    constructor Create(Configs: TInstallConfig);
    procedure CopyDll;
    procedure DeleteDll;
    procedure Install;
    procedure Uninstall;
  end;

implementation

{ TInstallationConfigs }

procedure TInstallConfig.SetVersion(const Value: TVersion);
begin
  FVersion := Value;
end;

procedure TInstallConfig.SetPath(const Value: string);
begin
  FPath := Value;
end;

procedure TInstallConfig.SetServiceName(const Value: string);
begin
  FServiceName := Value;
end;

procedure TInstallConfig.SetPort(const Value: string);
begin
  FPort := Value;
end;

procedure TInstallConfig.SetDllPaths(const Value: TStringList);
begin
  FDllPaths := Value;
end;

procedure TInstallConfig.SetLog(const Value: TMemo);
begin
  FLog := Value;
end;

//Destinos
function TInstallConfig.PathBin: string;
begin
  case Version of
  vrFb21, vrFb25:
    Result := Path + '\Bin';
  vrFb30, vrFb40:
    Result := Path;
  end;
end;

function TInstallConfig.PathConf: string;
begin
  Result := Path + '\firebird.conf';
end;

//Fontes
function TInstallConfig.Source(Extract: boolean = true): string;
begin
  if Extract then
  begin
    TUtils.DeleteIfExistsDir(TUtils.Temp + FolderName);

    //TZipFile.ExtractZipFile(TUtils.AppPath + 'Data' + FolderName + '.zip', TUtils.Temp);

    TUtils.ExtractResourceZip(ResourceName, TUtils.Temp);
  end;

  Result := TUtils.Temp + FolderName;
end;

function TInstallConfig.SourceBin(Extract: boolean = false): string;
begin
  case Version of
  vrFb21, vrFb25:
    Result := Source(Extract) + '\Bin';
  vrFb30, vrFb40:
    Result := Source(Extract);
  end;
end;

function TInstallConfig.SourceDll: string;
begin
  TUtils.DeleteIfExistsDir(TUtils.Temp + '\Dlls' + DllName);

  //TZipFile.ExtractZipFile(TUtils.AppPath + 'Data\Dlls.zip', TUtils.Temp);

  TUtils.ExtractResourceZip('DataDlls', TUtils.Temp);

  Result := TUtils.Temp + '\Dlls' + DllName;
end;

//Nome da pasta pela vers�o
function TInstallConfig.FolderName: string;
begin
  case Version of
  vrFb21:
    Result := '\Firebird_2_1';
  vrFb25:
    Result := '\Firebird_2_5';
  vrFb30:
    Result := '\Firebird_3_0';
  vrFb40:
    Result := '\Firebird_4_0';
  end;
end;

function TInstallConfig.DllName: string;
begin
  case Version of
  vrFb21:
    Result := '\fbclient21.dll';
  vrFb25:
    Result := '\fbclient25.dll';
  vrFb30:
    Result := '\fbclient30.dll';
  vrFb40:
    Result := '\fbclient40.dll';
  end;
end;

//Nome do resource pela vers�o
function TInstallConfig.ResourceName: string;
begin
  case Version of
  vrFb21:
    Result := 'DataFB21';
  vrFb25:
    Result := 'DataFB25';
  vrFb30:
    Result := 'DataFB30';
  vrFb40:
    Result := 'DataFB40';
  end;
end;



{ TInstallation }

constructor TInstallation.Create(Configs: TInstallConfig);
begin
  self.Configs := Configs;
end;

procedure TInstallation.Log(Text: string);
begin
  if Configs.Log <> nil then
  begin
    Configs.Log.Lines.Add(Text);

    Application.ProcessMessages;
  end;
end;

procedure TInstallation.CopyDll;
var
  DllFolder: string;
begin
  for DllFolder in Configs.DllPaths do
  begin
    TUtils.DeleteIfExistsFile(DllFolder + '\fbclient.dll');
    TFile.Copy(Configs.SourceDll, DllFolder + '\fbclient.dll');
  end;
end;

procedure TInstallation.DeleteDll;
var
  DllFolder: string;
begin
  for DllFolder in Configs.DllPaths do
  begin
    TUtils.DeleteIfExistsFile(DllFolder + '\fbclient.dll');
  end;
end;

procedure TInstallation.Install;
var
  Cancel: boolean;
  ConfFile: TStringList;
  PathFiles: TArray<string>;
  PathFileName, FilesInUse, CdBin: string;
begin
  try
    if Configs.Log <> nil then
      Configs.Log.Clear;

    Application.ProcessMessages;

    Log('Iniciando instala��o');
    Log('');
    Log('*******************************');
    Log('Path: ' + Configs.Path);
    Log('Service: ' + Configs.ServiceName);
    Log('Port: ' + Configs.Port);
    Log('*******************************');
    Log('');

    Log('Verificando se o diret�rio j� existe');

    if TDirectory.Exists(Configs.Path) then
    begin
      if TDialogs.YesNo('A pasta de instala��o "' + Configs.Path + '" j� existe, deseja sobreescrev�-la?' +
      TUtils.BreakLine + 'Tenha certeza de que a pasta n�o est� em uso!') = mrYes then
      begin

        Log('Verificando se os arquivos est�o em uso');

        //Verifica��o aquivos em uso
        PathFiles := TDirectory.GetFiles(Configs.Path);

        for PathFileName in PathFiles do
        begin
          if TUtils.IsFileInUse(PathFileName) then
          begin
            FilesInUse := FilesInUse + TUtils.BreakLine + PathFileName;
          end;
        end;

        if FilesInUse <> '' then
        begin
          Cancel := true;

          ShowMessage('Erro ao sobreescrever a pasta de instala��o, os seguintes arquivos est�o em uso '+
          TUtils.BreakLine + FilesInUse);
        end;

        Log('Deletando diret�rio');

        TDirectory.Delete(Configs.Path, true);

        Application.ProcessMessages;
      end
      else
      begin
        Cancel := true;
      end;
    end;

    if not Cancel then
    begin
      if TDirectory.Exists(Configs.Path) then
      begin
        Log('Desinstala��o cancelada');

        ShowMessage('Erro na pasta de instala��o, verifique se a '+
        'vers�o do Firebird que voc� est� tentando instalar j� '+
        'est� instalada, ou se a pasta de instala��o est� em uso!');
      end
      else
      begin
        Log('Copiando arquivos de instala��o para ' + Configs.Path);

        TDirectory.Copy(Configs.Source, Configs.Path);

        Log('Configurando porta');

        ConfFile := TStringList.Create;

        ConfFile.LoadFromFile(Configs.PathConf);

        ConfFile.Insert(0, 'RemoteServicePort = ' + Configs.Port);

        ConfFile.SaveToFile(Configs.PathConf);

        CdBin := 'cd ' + Configs.PathBin;

        Log('Instalando registro');

        TUtils.ExecDos(CdBin + ' && instreg r');

        Log('Instalando servi�o');

        TUtils.ExecDos(CdBin + ' && instsvc i -a -g -n ' + Configs.ServiceName);

        Log('Iniciando servi�o');

        TUtils.ExecDos(CdBin + ' && instsvc start -n ' + Configs.ServiceName);

        Log('Copiando Dlls');

        CopyDll;

        Log('Adicionando ao firewall');

        TUtils.AddFirewallPort('Firebird ' + Configs.ServiceName, Configs.Port);

        Log('Instala��o conclu�da');

        ShowMessage('Instala��o Conclu�da!');
      end;
    end
    else
    begin
      Log('Instala��o cancelada')
    end;
  Except on E: Exception do
    Log('Erro: ' + E.Message);
  end;
end;

procedure TInstallation.Uninstall;
var
  ConfFile: TStringList;
  PathFiles: TArray<string>;
  PathFileName, FilesInUse, CdBin: string;
begin
  try
    if Configs.Log <> nil then
      Configs.Log.Clear;

    Application.ProcessMessages;

    Log('Iniciando instala��o');
    Log('');
    Log('*******************************');
    Log('Path: ' + Configs.Path);
    Log('Service: ' + Configs.ServiceName);
    Log('Port: ' + Configs.Port);
    Log('*******************************');
    Log('');

    if TDialogs.YesNo('Tem certeza que deseja desinstalar o firebird no diret�rio "' + Configs.Path + '"?') = mrYes then
    begin
      Log('Verificando se o diret�rio existe');

      if DirectoryExists(Configs.Path) then
      begin
        Log('Verificando se a pasta bin existe');

        if DirectoryExists(Configs.PathBin) then
        begin
          Log('Repondo arquivos de desinstala��o caso n�o existam');

          if not FileExists(Configs.PathBin + '\instsvc.exe') then
            TFile.Copy(Configs.SourceBin(true) + '\instsvc.exe', Configs.PathBin + '\instsvc.exe');
          if not FileExists(Configs.PathBin + '\instreg.exe') then
            TFile.Copy(Configs.SourceBin + '\instreg.exe', Configs.PathBin + '\instreg.exe');

          CdBin := 'cd ' + Configs.PathBin;

          Log('Parando servi�o');

          TUtils.ExecDos(CdBin + ' && instsvc stop -n ' + Configs.ServiceName);

          Log('Desinstalando servi�o');

          TUtils.ExecDos(CdBin + ' && instsvc r -n ' + Configs.ServiceName);

          Log('Desinstalando registro');

          TUtils.ExecDos(CdBin + ' && instreg r');
        end;

        Application.ProcessMessages;

        Log('Verificando se os arquivos est�o em uso');

        //Verifica��o aquivos em uso
        PathFiles := TDirectory.GetFiles(Configs.Path);

        for PathFileName in PathFiles do
        begin
          if TUtils.IsFileInUse(PathFileName) then
          begin
            FilesInUse := FilesInUse + TUtils.BreakLine + PathFileName;
          end;
        end;

        if FilesInUse <> '' then
        begin
          Log('Desinstala��o cancelada');

          ShowMessage('Erro ao desinstalar, os seguintes arquivos est�o em uso '+
          TUtils.BreakLine + FilesInUse);
        end
        else
        begin
          Log('Deletando pasta de instala��o');

          TDirectory.Delete(Configs.Path, true);

          Application.ProcessMessages;

          if DirectoryExists(Configs.Path) then
          begin
            Log('Desinstala��o cancelada');

            ShowMessage('Erro ao desinstalar, verifique se o '+
            'nome do servi�o � o referente ao da pasta de '+
            'instala��o, ou se a pasta de instala��o est� em uso!');
          end
          else
          begin
            Log('Deletando Dlls');

            DeleteDll;

            Log('Removendo do firewall');

            TUtils.DeleteFirewallPort('Firebird ' + Configs.ServiceName, Configs.Port);

            Log('Desinstala��o conclu�da');

            ShowMessage('Desinstala��o Conclu�da');
          end;
        end;
      end
      else
      begin
        Log('Desinstala��o cancelada');
        ShowMessage('Erro ao desinstalar, diret�rio inexistente!');
      end;
    end
    else
    begin
      Log('Desinstala��o cancelada');
    end;
  except on E: Exception do
    Log('Erro: ' + E.Message);
  end;
end;

end.
