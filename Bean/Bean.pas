unit Bean;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils,
  Sets;

type
  TInstallationConfigs = class
  private
    FVersion: TVersion;
    FPath: string;
    FServiceName: string;
    FPort: string;
    FOptions: TInstallationOptions;
    FDllPaths: System.TArray<System.string>;
    procedure SetVersion(const Value: TVersion);
    procedure SetPath(const Value: string);
    procedure SetServiceName(const Value: string);
    procedure SetPort(const Value: string);
    procedure SetOptions(const Value: TInstallationOptions);
    procedure SetDllPaths(const Value: System.TArray<System.string>);

  public
    property Version: TVersion read FVersion write SetVersion;
    property Path: string read FPath write SetPath;
    property ServiceName: string read FServiceName write SetServiceName;
    property Port: string read FPort write SetPort;
    property Options: TInstallationOptions read FOptions write SetOptions;
    property DllPaths: System.TArray<System.string> read FDllPaths write SetDllPaths;
  end;

implementation

{ TInstallationConfigs }

procedure TInstallationConfigs.SetVersion(const Value: TVersion);
begin
  FVersion := Value;
end;

procedure TInstallationConfigs.SetPath(const Value: string);
begin
  FPath := Value;
end;

procedure TInstallationConfigs.SetServiceName(const Value: string);
begin
  FServiceName := Value;
end;

procedure TInstallationConfigs.SetPort(const Value: string);
begin
  FPort := Value;
end;

procedure TInstallationConfigs.SetOptions(const Value: TInstallationOptions);
begin
  FOptions := Value;
end;

procedure TInstallationConfigs.SetDllPaths(const Value: System.TArray<System.string>);
begin
  FDllPaths := Value;
end;

end.
