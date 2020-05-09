{*
    UltraStar WorldParty - Karaoke Game

	UltraStar WorldParty is the legal property of its developers,
	whose names	are too numerous to list here. Please refer to the
	COPYRIGHT file distributed with this source distribution.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. Check "LICENSE" file. If not, see
	<http://www.gnu.org/licenses/>.
 *}

unit UWebServer;

interface

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{$I switches.inc}

uses
  Classes,
  SysUtils,
  blcksock,
  sockets,
  Synautil;


type
  TPassMessage = procedure(AMsg: string) of object;

  TWebServer = class(TThread)
  private
    _PassMessage: TPassMessage;
    procedure AttendConnection(ASocket: TTCPBlockSocket);
    procedure TriggerMessage(AMsg: string);
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    property OnPassMessage: TPassMessage read _PassMessage write _PassMessage;
  end;
  implementation

  constructor TWebServer.Create;
  begin
    inherited Create(False);
  end;

  procedure TWebServer.Execute;
  var
    ListenerSocket, ConnectionSocket: TTCPBlockSocket;

  begin
    try
      ListenerSocket := TTCPBlockSocket.Create;
      ConnectionSocket := TTCPBlockSocket.Create;

      ListenerSocket.CreateSocket;
      ListenerSocket.setLinger(True, 10);
      ListenerSocket.bind('0.0.0.0', '80');
      ListenerSocket.listen;

      repeat
        if ListenerSocket.canread(1000) then
        begin
          ConnectionSocket.Socket := ListenerSocket.accept;
          //WriteLn('Attending Connection. Error code (0=Success): ', ConnectionSocket.lasterror);
          AttendConnection(ConnectionSocket);
          ConnectionSocket.CloseSocket;
        end;
      until Terminated;

    finally
      FreeAndNil(ListenerSocket);
      FreeAndNil(ConnectionSocket);
    end;
  end;

  procedure TWebServer.AttendConnection(ASocket: TTCPBlockSocket);
  var
    timeout: integer;
    s: string;
    OutputDataString: string;

  begin
    timeout := 120000;

    try
      try
        //WriteLn('Received headers+document from browser:');
        s := ASocket.RecvString(timeout);
        //WriteLn(s);


        //read request headers
        repeat
          s := ASocket.RecvString(Timeout);
          //WriteLn(s);
          TriggerMessage(s);
        until s = '';

        // Write the output document to the stream
        OutputDataString := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"' + ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' +
          CRLF + '<html><h1>UltraStar WorldParty</h1></html>' + CRLF;

        // Write the headers back to the client
        ASocket.SendString('HTTP/1.0 200' + CRLF);
        ASocket.SendString('Content-type: Text/Html' + CRLF);
        ASocket.SendString('Content-length: ' + IntToStr(Length(OutputDataString)) + CRLF);
        ASocket.SendString('Connection: close' + CRLF);
        ASocket.SendString('Date: ' + Rfc822DateTime(now) + CRLF);
        ASocket.SendString('Server: Lazarus Synapse' + CRLF);
        ASocket.SendString('' + CRLF);

        //if ASocket.lasterror <> 0 then HandleError;
        ASocket.SendString(OutputDataString);
      except
        on E: Exception do
        begin

        end;
      end;
    finally
    end;
  end;

  procedure TWebServer.TriggerMessage(AMsg: string);
  begin
    if Assigned(_PassMessage) then
      _PassMessage(AMsg);
  end;

  destructor TWebServer.Destroy();
  begin
    inherited Destroy;
  end;

  end.
