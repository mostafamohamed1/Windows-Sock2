program Server;

uses
  JwaWS2tcpip,JwaWinsock2;

const
  DEFAULT_PORT    = '27015';
  DEFAULT_BUFLEN  = 512;


var
  recbuf : array[0..DEFAULT_BUFLEN] of Byte;
  ret, recbuflen : Integer;
  SocketData : TWsaData;
  hints : TAddrInfo;
  res, ptr : PAddrInfo;
  ListenSocket, ClientSocket : TSocket;
  iResult, iSendResult : Integer;


begin

  Initialize(SocketData);
  ret := WSAStartup(WINSOCK_VERSION, SocketData);
  if ret <> 0 then
  begin
    WriteLn('WSAStartup failed: ', ret);
    Exit;
	end
  else
     WriteLn('WSAStartup OK: ', ret);

  Initialize(hints);


  hints.ai_family   := AF_INET ;
  hints.ai_socktype := SOCK_STREAM;
  hints.ai_protocol := IPPROTO_TCP;
  hints.ai_flags    := AI_PASSIVE;

  res := nil;

  iResult := getaddrinfo(nil, DEFAULT_PORT, @hints, res);

  if iResult <> 0 then
  begin
    WriteLn('getaddrinfo failed: ', iResult);
    WSACleanup();
    Exit;
	end;

  if res = nil then
  begin
    WriteLn('MemAlloc Error');
    Exit;
	end;

  ptr := res;
  ListenSocket := INVALID_SOCKET;
  ListenSocket := socket(ptr^.ai_family,ptr^.ai_socktype, ptr^.ai_protocol);

  if ListenSocket = INVALID_SOCKET then
  begin
    WriteLn('Error at socket(): ', WSAGetLastError);
    freeaddrinfo(res);
    WSACleanup();
    Exit;
	end;

  iResult := bind(ListenSocket,ptr^.ai_addr, Integer(ptr^.ai_addrlen));


  if iResult = SOCKET_ERROR then
  begin
    WriteLn('Bind Failed With Errot! ', WSAGetLastError);
    freeaddrinfo(res);
    closesocket(ListenSocket);
    WSACleanup();
    Exit;
	end;

  if listen(ListenSocket, SOMAXCONN) = SOCKET_ERROR then
  begin
    WriteLn('listen failed with error! ', WSAGetLastError);
    closesocket(ListenSocket);
    WSACleanup();
    Exit;
  end;

  ClientSocket := INVALID_SOCKET;
  ClientSocket := accept(ListenSocket, nil, nil);
  if ClientSocket = INVALID_SOCKET then
  begin
    WriteLn('accpet failed ', WSAGetLastError);
    closesocket(ListenSocket);
    WSACleanup();
    Exit;
  end;

  recbuflen := DEFAULT_BUFLEN;

  Initialize(recbuf);

  repeat

    iResult := recv(ClientSocket, recbuf, recbuflen, 0);

    if iResult > 0 then
    begin
      WriteLn('Bytes received: ', iResult);

      iSendResult := send(ClientSocket, recbuf, iResult ,0);

      if iSendResult = SOCKET_ERROR then
      begin
        WriteLn('send failed ', WSAGetLastError);
        closesocket(ClientSocket);
		    WSACleanup();
		    Exit;
      end;

      WriteLn('Bytes sent: ', iSendResult);
		end
    else if iResult = 0 then
    begin
      WriteLn('Connection closing...');
		end
    else
    begin
      WriteLn('recv faild: ', WSAGetLastError);
      closesocket(ClientSocket);
		  WSACleanup();
		  Exit;
		end;


	until iResult <= 0;


  iResult:= shutdown(ClientSocket,SD_SEND);
  if iResult = SOCKET_ERROR then
  begin

    WriteLn('shutsoen failed with error: ', WSAGetLastError);
    closesocket(ClientSocket);
    WSACleanup();
    Exit;

  end;

  closesocket(ClientSocket);
  WSACleanup();

  Exit;
end.

