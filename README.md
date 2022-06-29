# epos-public-helpers

Setup a fresh linux environment

The `setup.sh` script works from a brand *new* linux install, it will configure GIT and generate new SSH and GPG keys.

If you want to install it on an *existing* linux install, please read the script and exec the relevant parts for you.

## The whole process...

From windows, right click on the start meny and open `Windows PowerShell (Admin)`

In the console exec the following commands

```powershell
# see https://chocolatey.org/install if you need some explanation about this command
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# upon successful completion you'll be able to install arbitrary packages using `choco`
# here we'll install wget 
choco install wget

# see http://aka.ms/wslinstall 
wsl --install
```

Now reboot your computer

Then right click on the start meny and open `Windows PowerShell (Admin)` again

```powershell
# see https://docs.microsoft.com/en-us/windows/wsl/use-custom-distro for more details
# see https://aka.ms/terminal-documentation if you want to install a more user-friendly and higly customisable terminal
# use http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-amd64.tar.gz image if you want a very minimal base os

wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64-wsl.rootfs.tar.gz

wsl --import wsl-ubuntu c:\wsl\wsl-ubuntu ubuntu-22.04-server-cloudimg-amd64-wsl.rootfs.tar.gz --version 2

wsl -d wsl-ubuntu
```

You are now in Ubuntu, exec this command to setup the bare minimal about yourself

```bash
export USERNAME=mfronton && apt autoremove -y -qq && apt update -qq && apt upgrade -y -qq && apt install -y -qq sudo && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$USERNAME && useradd $USERNAME -s /bin/bash -d /home/$USERNAME && mkdir -p /home/$USERNAME && chown $USERNAME:$USERNAME /home/$USERNAME && echo -e "[user]\ndefault=$USERNAME" | tee /etc/wsl.conf && exit
```

You are now back in PowerShell, exec the following command to restart the VM

```powershell
wsl -t wsl-ubuntu
wsl -d wsl-ubuntu
```

Finally you are now back in Ubuntu, exec the following command to 

```bash
export FULLNAME="Matthieu FRONTON" && export EMAIL="matthieu.fronton@capgemini.com" && cd && wget https://raw.githubusercontent.com/baas-smartcredit/epos-public-helpers/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

## Extras

Something went wrong ? You want to restart from scratch ?

You can delete your VM and VM image :

```powershell
wsl --unregister wsl-ubuntu
```
