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
  curl https://get.docker.com | sudo bash
  sudo service docker start
  sudo usermod -aG docker $USER
fi

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

# ========================================================= GPG

GPG_PASSPHRASE="$(</dev/urandom tr -dc A-Za-z0-9 | head -c10)"

umask 177
cat > ~/gpg.conf <<EOF
%echo Generating a default key
Key-Type: RSA
Subkey-Type: RSA
Name-Real: ${FULLNAME}
Name-Comment: ${FULLNAME}'s key
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

sleep 1
source ~/.bashrc

# ========================================================= GOLANG

asdf plugin add golang
asdf install golang latest
asdf global golang latest

# ========================================================= GOPASS

go install github.com/gopasspw/gopass@v1.14.3
asdf reshim golang

gopass version

cat >> ~/.bashrc <<EOF

source <(gopass completion bash)
export EDITOR=vi
au BufNewFile,BufRead /dev/shm/gopass.* setlocal noswapfile nobackup noundofile
EOF

source ~/.bashrc

gopass clone git@github.com:baas-smartcredit/password-store.git
