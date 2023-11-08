# Домашняя работа "Виртуализация Proxmox"

Цель работы - создание манифестов terraform для разворачивания виртуальных машин в Proxmox.

Для взаимодействия terraform и Proxmox используется провайдер pbg/proxmox (https://registry.terraform.io/providers/bpg/proxmox/0.37.0)

К сожалению, мне не удалось найти в документации провайдера возможность отключения аппаратной виртуализации kvm для виртуальной машины, поэтому пришлось схитрить и добавить скрипт изменения этого параметра с помощью командной строки Proxmox.

Для разворачивания проекта необходимо:
1. Создать пользователя в Proxmox в realm pam с правами создания администрирования ВМ, storages (в тестовых целях можно использовать root@pam)
2. Добавить этому пользователю ssh ключ пользователя, от имени которого запускается terraform

```
$ ssh-copy-id {proxmox_user}@{proxmox_host}
```
3. Изменить атрибуты скрипта start_vm.sh

```
chmod +x ./start_vm.sh
```

4. Заполнить значения переменных proxmox_ip, proxmox_user, proxmox_pass в файле **variables.tf**. Можно так же изменить параметры количества памяти и ядер создаваемой ВМ в **main.tf**

5. Инициализировать рабочую среду Terraform:

```
$ terraform init
```
В результате будет установлен провайдер для подключения к Proxmox.

6. Запустить разворачивание проекта:
```
$ terraform apply
```
По окончании работы скрипта в Proxmox будет создана и запущена ВМ  Ubuntu 20.04, через некоторое время после старта, необходимое для настройки параметров cloud-init, ВМ будет готова к работе. 

```
# Пример вывода terraform apply:

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

ubuntu_vm_password = <sensitive>
ubuntu_vm_private_key = <sensitive>
ubuntu_vm_public_key = <<EOT
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD5MCYrVFc/qB4lylCAHL4g+LFMtXv4Fu32InAupAMA37LmSZsj1V3ckYW9HbmuZPWT62x8bGHKsZY2w8cfKD91SPMy6G3TmqVlasobX2A+JAU7hAuOtM/zjRYMAaJ/PiicL7S6rQnMbz0M4PiPkDLrB9W76nRhhq8BANu3MDs9TmDyCRtSDxlDHoEkhSRyTJKDZOoZmYlmwlP0Ui6/XKXb2/A2+AoLI6r35i/7oPSR/ieMdcvZb2Qw6OweK6LoelyxuNMZpzL5jVFowpBdf2GqylTYc39qE/JRL3/CPV9ZEePV679aTsanlexeEw/AseA6ox4xhjayBKGjqdlrduBn

EOT
vm_id = 100
```

Можно открыть консоль ВМ в Proxmox и залогиниться в созданную виртуальную машину. Пользователь **ubuntu**, пароль можно посмотреть с помощью команды
```
$ terraform output ubuntu_vm_password
```