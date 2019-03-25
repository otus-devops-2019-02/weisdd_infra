# weisdd_infra
weisdd Infra repository

bastion_IP = 35.198.167.169
someinternalhost_IP = 10.156.0.3

## HW 5 (VPN)

### Подключение к someinternalhost одной командой:
Вариант №1: Можно указывать все необходимые параметры при каждом подключении:
```
ssh -i ~/.ssh/appuser <internal-host> -o "ProxyCommand ssh appuser@<bastion> -W %h:%p"
```
e.g.
```
ssh -i ~/.ssh/appuser 10.132.0.3 -o "ProxyCommand ssh appuser@35.210.37.87 -W %h:%p"
```
-W Requests that standard input and output on the client be forwarded to host on port over the secure channel.
-o Can be used to give options in the format used in the configuration file.
-i Selects a file from which the identity (private key) for public key authentication is read.

Вариант №2: Добавить информацию о бастионе и внутреннем узле в ~/.ssh/config:
```
Host 35.210.37.87
    User appuser
    IdentityFile ~/.ssh/appuser

Host 10.132.*
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh appuser@35.210.37.87 -W %h:%p
```
- В данном примере подключение к любому узлу из 10.132.0.0/16 (Host 10.132.*) перенаправляется через 35.210.37.87.

### Подключение по алиасу
В дополнение к предыдущей конфигурации, можно назначить алиас конкретному узлу:
```
Host someinternalhost
    Hostname 10.132.0.3
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh appuser@35.210.37.87 -W %h:%p
```

### Ещё одна вариация ~/.ssh/config
Как вариант, можно определить алиас для bastion и ссылаться на него при описании внутренних узлов - в таком случае не нужно постоянно ссылаться на identity bastion'а:
```
Host bastion
    Hostname 35.210.37.87
    User appuser
    IdentityFile ~/.ssh/appuser

Host 10.132.*
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh bastion -W %h:%p

Host someinternalhost
    Hostname 10.132.0.3
    User appuser
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh bastion -W %h:%p
```

### Информация о подключении к VPN
```
bastion_IP = 35.210.37.87
someinternalhost_IP = 10.132.0.3
```

