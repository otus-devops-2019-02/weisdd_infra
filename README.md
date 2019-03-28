# weisdd_infra
weisdd Infra repository

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

## HW 6 (GCP, cloud-testapp)

### Скрипты для настройки системы и деплоя приложения
Здесь, в общем-то, ничего не обычного - просто список команд в .sh файлах (install_ruby.sh, install_mongodb.sh, deploy.sh)

### Дополнительное задание: startup-script
Ключевые моменты:
- startup-скрипты запускаются от root'а (https://cloud.google.com/compute/docs/startupscript#startup_script_execution), соответственно нужно держать в голове, что и от чьего имени мы хотим исполнить. Для исполнения команд от имени другого пользователя подойдет runuser или su (https://www.cyberciti.biz/open-source/command-line-hacks/linux-run-command-as-different-user/). Пример:
```
runuser -l appuser -c 'git clone -b monolith https://github.com/express42/reddit.git'
runuser -l appuser -c 'cd reddit && bundle install'
runuser -l appuser -c 'cd reddit && puma -d'
```
```
appuser@reddit-app:~$ ps aux | grep 9292
appuser   9434  1.0  1.5 513788 26876 ?        Sl   21:53   0:00 puma 3.10.0 (tcp://0.0.0.0:9292) [reddit]
appuser   9459  0.0  0.0  12916  1088 pts/0    S+   21:54   0:00 grep --color=auto 9292
```
- обработчик startup-скриптов не поддерживает не-ascii символы - в /var/log/syslog сыпалось множество ошибок, когда я в скрипте оставил комментарии на русском;
- отслеживать выполнение startup-скрипта можно в /var/log/syslog
```
tail -f /var/log/syslog
Mar 27 21:53:34 reddit-app systemd[1]: Started Session c3 of user appuser.
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script:   Puma starting in single mode...
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: * Version 3.10.0 (ruby 2.3.1-p112), codename: Russell's Teapot
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: * Min threads: 0, max threads: 16
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: * Environment: development
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: * Daemonizing...
Mar 27 21:53:34 reddit-app startup-script: INFO startup-script: Return code 0.
Mar 27 21:53:34 reddit-app startup-script: INFO Finished running startup scripts.
Mar 27 21:53:34 reddit-app systemd[1]: Started Google Compute Engine Startup Scripts.
Mar 27 21:53:34 reddit-app systemd[1]: Startup finished in 2.857s (kernel) + 1min 31.747s (userspace) = 1min 34.605s.
```
- скрипт может храниться локально на машине с gcloud-клиентом (startup-script=), в bucket на Google Cloud Storage (startup-script-url=), в метаданных instance, а также может быть передан в виде текста. В качестве дополнительного параметра к gcloud также необходимо указать "--metadata-from-file".
```
gcloud compute instances create reddit-app --boot-disk-size=10GB --image-family ubuntu-1604-lts --image-project=ubuntu-os-cloud --machine-type=g1-small --tags puma-server --restart-on-failure --metadata-from-file startup-script=install_all.sh
```

### Дополнительное задание: создание firewall rule через gcloud
```
gcloud compute firewall-rules create default-puma-server --action=allow --rules tcp:9292 --direction=ingress --target-tags=puma-server
```
Source-сеть нет необходимости указывать явно - 0.0.0.0/0 - значение по умолчанию.

### Информация о подключении к testapp
```
testapp_IP = 35.241.192.113
testapp_port = 9292
```

## HW 7 (Packer)

### Основное задание
После установки Packer (https://www.packer.io/downloads.html) было необходимо настроить Application Default Credentials (ADC), чтобы Packer мог обращаться к GCP через API:
```
$ gcloud auth application-default login
```

В файле ubuntu16.json были описаны инструкции для packer builder для подготовки образа Ubuntu с предустановленными Ruby и MongoDB. Сама установка выполняется при помощи т.н. provisioners, в данном случае имеющих воплощение в виде скриптов:
```
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
```

Проверка .json-файла на ошибки:
```
$ packer validate ./ubuntu16.json```
```
Запуск создания образа:
```
$ packer build ubuntu16.json
```
Деплой приложения:
```
$ git clone -b monolith https://github.com/express42/reddit.git
$ cd reddit && bundle install
$ puma -d
```

Важный момент: в секции builders можно задать network tags (tags), но они будут применяться только для instance, в котором подготавливается образ.
Для всех машин, которые позднее будут использовать этот образ, тэги нужно задавать отдельно при создании этих машин.

### Самостоятельные задания
Параметризация шаблона с использованием пользовательских переменных (в т.ч. для описание образа, размера диска, названия сети, тэгов):
```
{
    "variables": {
        "project_id": null,
        "source_image_family": null,
        "machine_type": "f1-micro",
        "image_description": "no description",
        "disk_size": "10",
        "network": "default",
        "tags": "puma-server"
    },
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "{{ user `project_id` }}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "source_image_family": "{{ user `source_image_family` }}",
            "zone": "europe-west1-b",
            "ssh_username": "appuser",
            "machine_type": "{{ user `machine_type` }}",
            "image_description": "{{ user `image_description` }}",
            "disk_size": "{{ user `disk_size` }}",
            "network": "{{ user `network` }}",
            "tags": "{{ user `tags` }}"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```
Сами переменные заданы в variables.json:
```
{
  "project_id": "infra-12345",
  "source_image_family": "ubuntu-1604-lts",
  "machine_type": "f1-micro",
  "image_description": "base image for reddit",
  "disk_size": "10",
  "network": "default",
  "tags": "puma-server"
}
```
Проверить корректность можно следующим образом:
```
$ packer inspect -var-file=variables.json.example ubuntu16.json
```

### Задание со * №1
Подготовка baked-образа, который включает установленное приложение + systemd unit для puma.
Этот шаблон описан в двух файлах: immutable.json и variables_full.json.
Основные отличия по сравнению с предыдущим образом (reddit-base):
В builders изменилось image_name и image_family, чтобы мы могли отличить reddit-base от reddit-full:
```
    "builders": [
        {
            "image_name": "reddit-full-{{timestamp}}",
            "image_family": "reddit-full",
        }
    ],
```
Поскольку мы будем создавать шаблон поверх reddit-base, старые скрипты из секции provisioners дублировать не нужно.
На их смену пришли:
* деплой файла с описанием systemd unit (на основе: https://github.com/puma/puma/blob/master/docs/systemd.md). Packer рекомендует осуществлять последующую настройку привелегий и перенос файла при помощи скриптов;
* скрипт, который скачивает приложение в домашнюю директорию appuser;
* скрипт, который переносит puma.service в нужную директорию, меняет привилегии, активирует автозапуск демона.
```
    "provisioners": [
        {
            "type": "file",
            "source": "files/puma.service",
            "destination": "/home/appuser/puma.service"
        },
        {
            "type": "shell",
            "script": "scripts/deploy_app.sh"
        },
        {
            "type": "shell",
            "script": "scripts/install_puma_service.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
```
variables_full.json (см. source_image_family):
```
    {
      "project_id": "infra-12345",
      "source_image_family": "reddit-base",
      "machine_type": "f1-micro",
      "image_description": "baked image for reddit",
      "disk_size": "10",
      "network": "default",
      "tags": "puma-server"
    }
```

Создание образа:
```
$ packer build -var-file=variables_full.json immutable.json
```

### Задание со * №2
Скрипт create-reddit-vm.sh для создания VM с приложением при помощи gcloud.
Чтобы имя instance было уникальным, к reddit-app- добавляется текущая дата, время и случайное число:
```
#!/bin/bash
set -e

# generating random id
id=$(date +'%Y%m%d%H%M%S')$RANDOM
gcloud compute instances create reddit-app-$id --image-family=reddit-full --machine-type=f1-micro --tags=puma-server
```
