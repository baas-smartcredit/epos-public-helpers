#!/bin/bash -eux

[ ! "$(cat /etc/os-release | awk -F '=' '/^ID_LIKE=/{print $2}')" = "debian" ] && echo >&2 "FATAL: script tested on debian family distros. Read the script to understand how it works" && exit 255

: ${FULLNAME:?'FATAL: missing FULLNAME variable'}
: ${EMAIL:?'FATAL: missing EMAIL variable'}

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y curl vim git gnupg rng-tools

# ========================================================= DOCKER

if ! command -v "docker" > /dev/null 2>&1
then
  
  sudo update-alternatives --set iptables  /usr/sbin/iptables-legacy
  sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

  curl https://get.docker.com | sudo bash
  sudo service docker start
  sudo usermod -aG docker $USER
fi

sleep 1
exec sudo su -l $USER
docker ps

docker pull postman/newman:alpine
docker images

# ========================================================= SSH

# https://www.ssi.gouv.fr/guide/recommandations-pour-un-usage-securise-dopenssh/
[ ! -f ~/.ssh/id_ed25519 ] && ssh-keygen -t ed25519 -C "$EMAIL" -b 256 -N "" -f ~/.ssh/id_ed25519

echo "
Now do the following before continuing :
 - Go to github.com
 - Create an account

 - Ask the Tech Lead to add your account to github.com/baas-smartcredit organisation
 - Wait for him to confirm you've been successfully added

 - On github.com head into 'settings -> SSH and GPG keys'
 - Add the following SSH key :

    $(cat ~/.ssh/id_ed25519.pub)

"

while [ $(ssh -o LogLevel=ERROR -o StrictHostKeyChecking=accept-new -o RequestTTY=no git@github.com 2>&1 | grep -c 'successfully authenticated') -eq 0 ]
do
    echo
    echo "github.com does not (yet) recognize the key"
    echo "Please follow the above instruction"
    echo "Waiting 30s before retry"
    echo
    sleep 30
done

mkdir -p /home/$USER/lab/github.com/baas-smartcredit/
git clone git@github.com:baas-smartcredit/epos.git /home/$USER/lab/github.com/baas-smartcredit/epos

# ========================================================= GPG

GPG_PASSPHRASE="$(</dev/urandom tr -dc A-Za-z0-9 | head -c10)"

umask 177
cat > ~/gpg.conf <<EOF
%echo Generating a default key
Key-Type: RSA
Subkey-Type: RSA
Name-Real: ${FULLNAME}
Name-Comment: gopass key
Name-Email: ${EMAIL}
Expire-Date: 0
Passphrase: ${GPG_PASSPHRASE}
%commit
%echo done
EOF
umask 022

echo "
Before continuing, here is your GPG passphrase: $GPG_PASSPHRASE
(It won't be displayed again)
"
read

gpg --batch --gen-key ~/gpg.conf

shred -fuz ~/gpg.conf

# ========================================================= GIT

git config --global user.name  "$FULLNAME"
git config --global user.email "$EMAIL"
git config --global advice.detachedHead "false"

# ========================================================= ASDF
sleep 1
if [ ! -d ~/.asdf ]
then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2

    cat >> ~/.bashrc <<EOF

source \$HOME/.asdf/asdf.sh
source \$HOME/.asdf/completions/asdf.bash
EOF
fi

echo "Wait 5s before reloading .bashrc and installing golang"
sleep 5
source $HOME/.asdf/asdf.sh
source $HOME/.asdf/completions/asdf.bash

# ========================================================= GOLANG

sleep 1
asdf plugin add golang
asdf install golang latest
asdf global golang latest

# ========================================================= GOPASS

go install github.com/gopasspw/gopass@v1.14.3
asdf reshim golang

gopass version

cat >> ~/.bashrc <<EOF

export EDITOR=nano
source <(gopass completion bash)
au BufNewFile,BufRead /dev/shm/gopass.* setlocal noswapfile nobackup noundofile
EOF

gopass clone git@github.com:baas-smartcredit/password-store.git

gopass ls

# ========================================================= FINISH

echo "
Congrats

[1/4]

A little recap what the script have just done :
- Create SSH keys (and import it to your github account)
- Create GPG keys (and install gnupg dependency)
- Configure git username and email (and install git dependency)
- Install and setup gopass (and install asdf+golang dependencies)
- Install and setup docker

[2/4]

Also the following git repositories have been cloned :
- Testing automation : /home/$USER/lab/github.com/baas-smartcredit/epos

You're all almost done...

[3/4]

Now ask the Tech Lead to import your GPG public keys to the shared encrypted password repository :

$(gpg --export --armor $EMAIL)

[4/4]

Finally, confirm you're key has successfully been imported with the following command :

gopass sync && gopass success
"
