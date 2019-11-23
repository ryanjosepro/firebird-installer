unit InstallConfigs;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils,
  Zip,
  MySets, MyUtils;

type
  TInstallConfigs = class
  private
    FVersion: TVersion;
    FPath: string;
    FServiceName: string;
    FPort: string;
    FDllPaths: System.TArray<System.string>;
    procedure SetVersion(const Value: TVersion);
    procedure SetPath(const Value: string);
    procedure SetServiceName(const Value: string);
    procedure SetPort(const Value: string);
    procedure SetDllPaths(const Value: System.TArray<System.string>);

    function FolderName: string;
    function DllName: string;
    function ResourceName: string;
  public
    property Version: TVersion read FVersion write SetVersion;
    property Path: string read FPath write SetPath;
    property ServiceName: string read FServiceName write SetServiceName;
    property Port: string read FPort write SetPort;
    property DllPaths: System.TArray<System.string> read FDllPaths write SetDllPaths;

    function PathFb: string;
    function PathBin: string;
    function PathConf: string;
    function Source(Extract: boolean = true): string;
    function SourceBin: string;
    function SourceDll: string;
  end;

implementation

{ TInstallationConfigs }

procedure TInstallConfigs.SetVersion(const Value: TVersion);
begin
  FVersion := Value;
end;

procedure TInstallConfigs.SetPath(const Value: string);
begin
  if TUtils.GetLastFolder(Value) = FolderName then
  begin
    FPath := ExtractFileDir(Value);
  end
  else
  begin
    FPath := Value;
  end;
end;

procedure TInstallConfigs.SetServiceName(const Value: string);
begin
  FServiceName := Value;
end;

procedure TInstallConfigs.SetPort(const Value: string);
begin
  FPort := Value;
end;

procedure TInstallConfigs.SetDllPaths(const Value: System.TArray<System.string>);
begin
  FDllPaths := Value;
end;

//Pasta destino de instala��o
function TInstallConfigs.PathFb: string;
begin
  if TUtils.GetLastFolder(Path) = FolderName then
  begin
    Result := Path;
  end
  else
  begin
    Result := Path + FolderName;
  end;
end;

//Pasta destino dos utilit�rios
function TInstallConfigs.PathBin: string;
begin
  case Version of
  vrFb21, vrFb25:
    Result := PathFb + '\Bin';
  vrFb30:
    Result := PathFb;
  end;
end;

//Arquivo firebird.conf
function TInstallConfigs.PathConf: string;
begin
  Result := PathFb + '\firebird.conf';
end;

//Pasta fonte do firebird
function TInstallConfigs.Source(Extract: boolean): string;
begin
  if Extract then
  begin
    TUtils.DeleteIfExistsDir(TUtils.Temp + FolderName);

    TZipFile.ExtractZipFile(TUtils.AppPath + 'Data' + FolderName + '.zip', TUtils.Temp);
  end;
  Result := TUtils.Temp + FolderName;

  //Result := TUtils.AppPath + 'Data' + FolderName;
end;

//Pasta fonte dos utilitarios
function TInstallConfigs.SourceBin: string;
begin
  case Version of
  vrFb21, vrFb25:
    Result := Source(false) + '\Bin';
  vrFb30:
    Result := Source(false);
  end;
end;

function TInstallConfigs.SourceDll: string;
begin
  TUtils.DeleteIfExistsDir(TUtils.Temp + '\Dlls' + DllName);

  TZipFile.ExtractZipFile(TUtils.AppPath + 'Data\Dlls.zip', TUtils.Temp);

  Result := TUtils.Temp + '\Dlls' + DllName;
end;

//Nome da pasta pela vers�o
function TInstallConfigs.FolderName: string;
begin
  case Version of
  vrFb21:
    Result := '\Firebird_2_1';
  vrFb25:
    Result := '\Firebird_2_5';
  vrFb30:
    Result := '\Firebird_3_0';
  end;
end;

function TInstallConfigs.DllName: string;
begin
  case Version of
  vrFb21:
    Result := '\fbclient21.dll';
  vrFb25:
    Result := '\fbclient25.dll';
  vrFb30:
    Result := '\fbclient30.dll';
  end;
end;

//Coming Soon
function TInstallConfigs.ResourceName: string;
begin
  case Version of
  vrFb21:
    Result := 'DataFB21';
  vrFb25:
    Result := 'DataFB25';
  vrFb30:
    Result := 'DataFB30';
  end;
end;

end.
