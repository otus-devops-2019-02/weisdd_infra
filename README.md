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

## HW 8 (IaC - terraform-1)
В данной работе мы настроили деплой нашего приложения посредством terraform.
Структура конфигурации:
- main.tf - виртуальная машина, правило firewall, provisioners, ssh-ключи;
- variables.tf - переменные, используемые в main.tf;
- terraform.tfvars - значения, подставляемые в переменные;
- outputs.tf - переменные, значение у которых появляется уже после запуска машин (e.g. IP-адрес)

### Самостоятельные задания
Определите input переменную для приватного ключа, использующегося в определении подключения для провижинеров (connection);
```
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}
```

Определите input переменную для задания зоны в ресурсе "google_compute_instance" "app". У нее * должно быть значение по умолчанию*
```
variable "zone" {
  description = "Zone"
  default = "europe-west1-b"
}
```

### Задание со * (стр. 51)
Задание:
Опишите в коде терраформа добавление ssh ключа пользователя appuser1 в метаданные проекта.

Решение:
main.tf:
```
resource "google_compute_project_metadata_item" "default" {
  key   = "ssh-keys"
  value = "${chomp(file(var.public_key_path))}"
}
```

variables.tf:
```
variable "public_key_path" {
  description = "Path to the public key used for ssh access"

}
```

terraform.tfvars:
```
public_key_path = "~/.ssh/appuser.pub"
```

Важный момент: лучше использовать chomp при импорте содержимого файла, иначе в веб-интерфейсе GCP мы увидим два ключа: один нормальный, другой - пустой.

Задание:
Опишите в коде терраформа добавление ssh ключей нескольких пользователей в метаданные проекта (можно просто один и тот же публичный ключ, но с разными именами пользователей, например appuser1, appuser2 и т.д.).

Решение:
main.tf
```
resource "google_compute_project_metadata_item" "default" {
  key   = "ssh-keys"
  value = "${chomp(file(var.public_key_path))}\n${chomp(file(var.public_key_path2))}\n${chomp(file(var.public_key_path3))}"
}
```

variables.tf:
```
variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "public_key_path2" {
  description = "Path to the public key used for ssh access"
}

variable "public_key_path3" {
  description = "Path to the public key used for ssh access"
}
```

terraform.tfvars:
```
public_key_path = "~/.ssh/appuser.pub"

public_key_path2 = "~/.ssh/temp_keys/appuser2.pub"

public_key_path3 = "~/.ssh/temp_keys/appuser3.pub"
```

### Задание со * (стр. 52)
Задание:
Добавьте в веб интерфейсе ssh ключ пользователю appuser_web в метаданные проекта. Выполните terraform apply и проверьте результат. Какие проблемы вы обнаружили?

Решение:
Поскольку все ssh-ключи хранятся в одном элементе метаданных проекта, то при попытке внести изменения через Terraform, предыдущие данные удаляются. Соответственно, мы должны использовать только один способ добавления ключей - либо через terraform, либо вручную.

### Задание с ** (стр. 53)
Задание:
Создайте файл lb.tf и опишите в нем в коде terraform создание HTTP балансировщика, направляющего трафик на наше развернутое приложение на инстансе reddit-app.

Решение:
lb.tf
```
resource "google_compute_instance_group" "ig-reddit-app" {
  name        = "ig-reddit-app"
  description = "Reddit app instance group"

  instances = [
    //    "${google_compute_instance.app.self_link}",
    "${google_compute_instance.app.*.self_link}",
  ]

  named_port {
    name = "http"
    port = "9292"
  }

  zone = "${var.zone}"
}

resource "google_compute_http_health_check" "reddit-http-basic-check" {
  name         = "reddit-http-basic-check"
  request_path = "/"
  port         = 9292
}

resource "google_compute_backend_service" "bs-reddit-app" {
  name        = "bs-reddit-app"
  description = "Backend service for reddit-app"
  port_name   = "http"
  protocol    = "HTTP"
  enable_cdn  = false

  backend {
    group           = "${google_compute_instance_group.ig-reddit-app.self_link}"
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }

  health_checks = ["${google_compute_http_health_check.reddit-http-basic-check.self_link}"]
}

resource "google_compute_url_map" "urlmap-reddit-app" {
  name        = "urlmap-reddit-app"
  description = "URL-map to redirect traffic to the backend service"

  default_service = "${google_compute_backend_service.bs-reddit-app.self_link}"
}

resource "google_compute_target_http_proxy" "http-lb-proxy-reddit-app" {
  name        = "http-lb-proxy-reddit-app"
  description = "Target HTTP proxy"
  url_map     = "${google_compute_url_map.urlmap-reddit-app.self_link}"
}

resource "google_compute_global_forwarding_rule" "fr-reddit-app" {
  name        = "website-forwarding-rule"
  description = "Forwarding rule"
  target      = "${google_compute_target_http_proxy.http-lb-proxy-reddit-app.self_link}"
  port_range  = "80"
}
```
Это решение было основано на примере: https://cloud.google.com/load-balancing/docs/https/content-based-example (вариант с target-pools не рассматривался, т.к. он менее сложен и интересен. Сравнение: https://stackoverflow.com/questions/48895008/target-pools-vs-backend-services-vs-regional-backend-service-difference)
В последовательности для gcloud, оно будет выглядеть следующим образом:
1. Создаем Instance-group.
2. Добавляем Instance в Instance-group
3. Создаём named-порт, по которому балансировщик будет дальше обращаться к instance. При обращении по HTTP, лучше порт назвать http.
4. Создаём HTTP health-check.
5. Создаём backend service. Его функция состоит в том, чтобы измерять производительность и доступность (как самой машины, так и ресурсов) у всех instance в instance group. При необходимости, трафик перенаправляется на другую машину.
Важно:
Если мы выберем протокол HTTP и при этом забудем указать port-name, то backend всё равно автоматически привяжется к порту с именем http, даже если он не существует.
$ gcloud compute backend-services create video-service --protocol HTTP --health-checks reddit-http-basic-check --global --port-name http
6. Добавляем instance group как backend в backend-сервис, при этом указываем режим балансировки и триггер по нагрузке, который в потенциале может использоваться для autoscale.
7. Задаем URL-map для перенаправления входящих запросов к соответствующему backend-сервису. Есть возможность задавать path-rules. В нашем случае, весь трафик, не попавший под остальные url-maps будет уходить к video-service.
8. Создаем target HTTP proxy для перенаправления запросов, соответствующих URL map
9. Создаем правило для перенаправления входящего трафика к нашему прокси. При необходимости, можно в будущем добавить отдельное правило под IPv6 внутри GСP трафик уже в виде IPv4 будет маршрутизироваться).


Задание:
Добавьте в output переменные адрес балансировщика.

Решение:
outputs.tf
```
output "Global Forwarding Rule IP" {
  value = "${google_compute_global_forwarding_rule.fr-reddit-app.ip_address}"
}
```

### Задание с ** (стр. 54)
Задание:
Добавьте в код еще один terraform ресурс для нового инстанса приложения, например reddit-app2, добавьте его в балансировщик и проверьте, что при остановке на одном из инстансов приложения (например systemctl stop puma), приложение продолжает быть доступным по адресу балансировщика; Добавьте в output переменные адрес второго инстанса; Какие проблемы вы видите в такой конфигурации приложения?

Решение:
Основное неудобство состоит в том, что каждый раз приходится копировать большой объем кода (instance, output-переменные)

### Задание с ** (стр. 55)
Задание:
Как мы видим, подход с созданием доп. инстанса копированием кода выглядит нерационально, т.к. копируется много кода. Удалите описание reddit-app2 и попробуйте подход с заданием количества инстансов через параметр ресурса count. Переменная count должна задаваться в параметрах и по умолчанию равна 1.

Решение:
main.tf
```
resource "google_compute_instance" "app" {
  count        = "${var.number_of_instances}"
  name         = "reddit-app-${count.index}"
  [...]
}
```
=> Здесь основное отличие будет состоять в том, что мы будет к имени автоматически добавлять номер instance через ${count.index}

variables.tf
```
variable "number_of_instances" {
  description = "Number of reddit-app instances (count)"
}
```

terraform.tfvars
```
number_of_instances = 1
```

outputs.tf
```
output "app_external_ip2" {
  value = "${google_compute_instance.app.*.network_interface.0.access_config.0.nat_ip}"
}
```
=> Чтобы output-переменные генерировались для каждого созданного instance, после указания имени ресурса terraform, необходимо добавить .*. (google_compute_instance.app.*.).
