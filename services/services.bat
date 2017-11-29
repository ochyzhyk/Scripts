sc config aspnet_state start= demand //ASP.NET State Service
net stop aspnet_state
sc config dhcp start= auto //DHCP-������
sc config Dnscache start= auto //DNS-������
sc config MDM start= auto //Machine Debug Manager
net stop MDM
sc config SwPrv start= disabled //MS Software Shadow Copy Provider
sc config NetTcpPortSharing start= disabled //Net.Tcp Port Sharing Service
sc config mnmsrvc start= disabled //NetMeeting Remote Desktop Sharing
sc config ose start= demand //Office Source Engine x86
net stop ose
sc config ose64 start= demand //Office Source Engine x64
net stop ose64
sc config PlugPlay start= auto //Plug and Play
sc config RSVP start= disabled //QoS RSVP
sc config RServer3 start= auto //Remote Administrator Service
sc config TlntSvr start= disabled //Telnet
sc config AudioSrv start= auto //Windows Audio
sc config idsvc start= demand //Windows CardSpace
net stop idsvc
sc config MSIServer start= demand //Windows Installer
net stop MSIServer
sc config FontCache3.0.0.0 start= demand //Windows Presentation Foundation Font Cache 3.0.0.0
net stop FontCache3.0.0.0
sc config wuauserv start= auto //��⮬���᪮� ����������
sc config wmiApSrv start= disabled //������ �ந�����⥫쭮�� WMI
sc config WZCSVC start= auto //���஢����� ����ன��
net stop WZCSVC
sc config MpsSvc start= auto //�࠭������ Windows
sc config SharedAccess start= auto //��騩 ����� � ���୥��
sc config WebClient start= disabled //���-������
sc config seclogon start= auto //����� �室 � ��⥬�
sc config RasAuto start= demand //��ᯥ��� ���-������祭�� 㤠������� ����㯠
net stop RasAuto
sc config dmserver start= auto //��ᯥ��� �����᪨� ��᪮�
sc config Spooler start= auto //��ᯥ��� ��।� ����
sc config RasMan start= demand //��ᯥ��� ������祭�� 㤠������� ����㯠
net stop RasMan
sc config RDSessMgr start= disabled //��ᯥ��� ᥠ�� �ࠢ�� ��� 㤠������� ࠡ�祣� �⮫�
sc config NetDDEdsdm start= disabled //��ᯥ��� �⥢��� DDE
sc config SamSs start= auto //��ᯥ��� ����� ����ᥩ ������᭮��
sc config HidServ start= auto //����� � HID-���ன�⢠�
sc config eventlog start= auto //��ୠ� ᮡ�⨩
sc config pla start=disabled //��ୠ�� � �����饭�� �ந�����⥫쭮��
sc config SysmonLog start= disabled //��ୠ�� � �����饭�� �ந�����⥫쭮��
sc config DcomLaunch start= auto //����� �ࢥ��� ����ᮢ DCOM
sc config ProtectedStorage start= auto //���饭��� �࠭����
sc config Winmgmt start= auto //�����㬥��਩ �ࠢ����� Windows
sc config UPS start= demand //���筨� ��ᯥॡ������ ��⠭��
net stop UPS
sc config TrkWks start= demand //������ ��᫥������� ����������� �痢�
net stop TrkWks
sc config MSDTC start= demand //���न���� ��।������� �࠭���権
net stop MSDTC
sc config RpcLocator start= demand //������ 㤠������� �맮�� ��楤�� (RPC)
net stop RpcLocator
sc config RemoteAccess start= disabled //������⨧��� � 㤠����� �����
sc config lmhosts start= auto //����� �����প� NetBIOS �१ TCP/IP
sc config Browser start= auto //����ॢ�⥫� �������஢
sc config Alerter start= disabled //������⥫�
sc config ShellHWDetection start= auto //��।������ ����㤮����� �����窨
sc config Schedule start= auto //�����஢騪 �������
sc config NtLmSsp start= demand //���⠢騪 �����প� ������᭮�� NTLM
net stop NtLmSsp
sc config HTTPFilter start= demand //��⮪�� HTTP SSL
net stop HTTPFilter
sc config LanmanWorkstation start= auto //������ �⠭��
sc config Wmi start= demand //����७�� �ࠩ��஢ WMI
net stop Wmi
sc config LanmanServer start= auto //��ࢥ�
sc config ClipSrv start= disabled //��ࢥ� ����� ������
sc config Netlogon start= demand //��⥢�� �室 � ��⥬�
net stop Netlogon
sc config Netman start= demand //��⥢� ������祭��
net start Netman
sc config EventSystem start= demand //���⥬� ᮡ�⨩ COM+
net start EventSystem
sc config COMSysApp start= demand //���⥬��� �ਫ������ COM+
net stop COMSysApp
sc config ImapiService start= demand //��㦡� COM ����� �������-��᪮� IMAPI
net stop ImapiService
sc config dmadmin start= demand //��㦡� ���������஢���� ��ᯥ��� �����᪨� ��᪮�
net stop dmadmin
sc config srservice start= auto //��㦡� ����⠭������� ��⥬�
sc config W32Time start= auto //��㦡� �६��� Windows
sc config stisvc start= demand //��㦡� ����㧪� ����ࠦ���� (WIA)
net stop stisvc
sc config cisvc start= disabled //��㦡� ������஢����
sc config xmlprov start= demand //��㦡� ���ᯥ祭�� ��
net stop xmlprov
sc config SSDPSRV start= disabled //��㦡� �����㦥��� SSDP
sc config WMPNetworkSvc start= disabled //��㦡� ���� �⥢�� ����ᮢ �ந��뢠⥫� Windows Media
sc config WerSvc start= disabled //��㦡� ॣ����樨 �訡��
sc config ERSvc start= disabled //��㦡� ॣ����樨 �訡��
sc config WmdmPmSN start= demand //��㦡� �਩��� ����஢ ��७���� ���ன�� ���⨬����
net stop WmdmPmSN
sc config NetDDE start= disabled //��㦡� �⥢��� DDE
sc config Nla start= demand //��㦡� �⥢��� �ᯮ������� (NLA)
net start Nla
sc config Messenger start= auto //��㦡� ᮮ�饭��
sc config ALG start= demand //��㦡� � �஢�� �ਫ������
net stop ALG
sc config PolicyAgent start= auto //��㦡� IPSEC
sc config CryptSvc start= auto //��㦡� �ਯ⮣�䨨
sc config TermService start= demand //��㦡� �ନ�����
net start TermService
sc config SCardSvr start= disabled //�����-�����
sc config FastUserSwitchingCompatibility start= demand //������⨬���� ����ண� ��४��祭�� ���짮��⥫��
net stop FastUserSwitchingCompatibility
sc config FastUserSwitching Compatibility start= demand //������⨬���� ����ண� ��४��祭�� ���짮��⥫��
net stop FastUserSwitching Compatibility
sc config helpsvc start= auto //��ࠢ�� � �����প�
sc config NtmsSvc start= demand //�ꥬ�� ��
net stop NtmsSvc
sc config TapiSrv start= demand //����䮭��
net stop TapiSrv
sc config Themes start= auto //����
sc config VSS start= demand //������� ����஢���� ⮬�
net stop VSS
sc config SENS start= auto //����������� � ��⥬��� ᮡ����
sc config RpcSs start= auto //�������� �맮� ��楤�� (RPC)
sc config RemoteRegistry start= disabled //�������� ॥���
sc config upnphost start= demand //���� 㭨���ᠫ��� PnP-���ன��
net stop upnphost
sc config AppMgmt start= demand //��ࠢ����� �ਫ�����ﬨ
net stop AppMgmt
sc config BITS start= demand //������� ��⥫����㠫쭠� �㦡� ��।��
net start BITS
sc config wscsvc start= auto //����� ���ᯥ祭�� ������᭮��
pause