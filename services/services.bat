sc config aspnet_state start= demand //ASP.NET State Service
net stop aspnet_state
sc config dhcp start= auto //DHCP-клиент
sc config Dnscache start= auto //DNS-клиент
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
sc config wuauserv start= auto //Автоматическое обновление
sc config wmiApSrv start= disabled //Адаптер производительности WMI
sc config WZCSVC start= auto //Беспроводная настройка
net stop WZCSVC
sc config MpsSvc start= auto //Брандмауэр Windows
sc config SharedAccess start= auto //Общий доступ к Интернету
sc config WebClient start= disabled //Веб-клиент
sc config seclogon start= auto //Вторичный вход в систему
sc config RasAuto start= demand //Диспетчер авто-подключений удаленного доступа
net stop RasAuto
sc config dmserver start= auto //Диспетчер логических дисков
sc config Spooler start= auto //Диспетчер очереди печати
sc config RasMan start= demand //Диспетчер подключений удаленного доступа
net stop RasMan
sc config RDSessMgr start= disabled //Диспетчер сеанса справки для удаленного рабочего стола
sc config NetDDEdsdm start= disabled //Диспетчер сетевого DDE
sc config SamSs start= auto //Диспетчер учетных записей безопасности
sc config HidServ start= auto //Доступ к HID-устройствам
sc config eventlog start= auto //Журнал событий
sc config pla start=disabled //Журналы и оповещения производительности
sc config SysmonLog start= disabled //Журналы и оповещения производительности
sc config DcomLaunch start= auto //Запуск серверных процессов DCOM
sc config ProtectedStorage start= auto //Защищенное хранилище
sc config Winmgmt start= auto //Инструментарий управления Windows
sc config UPS start= demand //Источник бесперебойного питания
net stop UPS
sc config TrkWks start= demand //Клиент отслеживания изменившихся связей
net stop TrkWks
sc config MSDTC start= demand //Координатор распределенных транзакций
net stop MSDTC
sc config RpcLocator start= demand //Локатор удаленного вызова процедур (RPC)
net stop RpcLocator
sc config RemoteAccess start= disabled //Маршрутизация и удаленный доступ
sc config lmhosts start= auto //Модуль поддержки NetBIOS через TCP/IP
sc config Browser start= auto //Обозреватель компьютеров
sc config Alerter start= disabled //Оповещатель
sc config ShellHWDetection start= auto //Определение оборудования оболочки
sc config Schedule start= auto //Планировщик заданий
sc config NtLmSsp start= demand //Поставщик поддержки безопасности NTLM
net stop NtLmSsp
sc config HTTPFilter start= demand //Протокол HTTP SSL
net stop HTTPFilter
sc config LanmanWorkstation start= auto //Рабочая станция
sc config Wmi start= demand //Расширения драйверов WMI
net stop Wmi
sc config LanmanServer start= auto //Сервер
sc config ClipSrv start= disabled //Сервер папки обмена
sc config Netlogon start= demand //Сетевой вход в систему
net stop Netlogon
sc config Netman start= demand //Сетевые подключения
net start Netman
sc config EventSystem start= demand //Система событий COM+
net start EventSystem
sc config COMSysApp start= demand //Системное приложение COM+
net stop COMSysApp
sc config ImapiService start= demand //Служба COM записи компакт-дисков IMAPI
net stop ImapiService
sc config dmadmin start= demand //Служба администрирования диспетчера логических дисков
net stop dmadmin
sc config srservice start= auto //Служба восстановления системы
sc config W32Time start= auto //Служба времени Windows
sc config stisvc start= demand //Служба загрузки изображений (WIA)
net stop stisvc
sc config cisvc start= disabled //Служба индексирования
sc config xmlprov start= demand //Служба обеспечения сети
net stop xmlprov
sc config SSDPSRV start= disabled //Служба обнаружения SSDP
sc config WMPNetworkSvc start= disabled //Служба общих сетевых ресурсов проигрывателя Windows Media
sc config WerSvc start= disabled //Служба регистрации ошибок
sc config ERSvc start= disabled //Служба регистрации ошибок
sc config WmdmPmSN start= demand //Служба серийных номеров переносных устройств мультимедиа
net stop WmdmPmSN
sc config NetDDE start= disabled //Служба сетевого DDE
sc config Nla start= demand //Служба сетевого расположения (NLA)
net start Nla
sc config Messenger start= auto //Служба сообщений
sc config ALG start= demand //Служба шлюза уровня приложения
net stop ALG
sc config PolicyAgent start= auto //Службы IPSEC
sc config CryptSvc start= auto //Службы криптографии
sc config TermService start= demand //Службы терминалов
net start TermService
sc config SCardSvr start= disabled //Смарт-карты
sc config FastUserSwitchingCompatibility start= demand //Совместимость быстрого переключения пользователей
net stop FastUserSwitchingCompatibility
sc config FastUserSwitching Compatibility start= demand //Совместимость быстрого переключения пользователей
net stop FastUserSwitching Compatibility
sc config helpsvc start= auto //Справка и поддержка
sc config NtmsSvc start= demand //Съемные ЗУ
net stop NtmsSvc
sc config TapiSrv start= demand //Телефония
net stop TapiSrv
sc config Themes start= auto //Темы
sc config VSS start= demand //Теневое копирование тома
net stop VSS
sc config SENS start= auto //Уведомление о системных событиях
sc config RpcSs start= auto //Удаленный вызов процедур (RPC)
sc config RemoteRegistry start= disabled //Удаленный реестр
sc config upnphost start= demand //Узел универсальных PnP-устройств
net stop upnphost
sc config AppMgmt start= demand //Управление приложениями
net stop AppMgmt
sc config BITS start= demand //Фоновая интеллектуальная служба передачи
net start BITS
sc config wscsvc start= auto //Центр обеспечения безопасности
pause