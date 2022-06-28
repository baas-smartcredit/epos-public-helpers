#!/bin/bash -eu

do_install() {

[ $(id -u) -ne 0 ] && echo >&2 "FATAL: use sudo to run the script"
[ ! "$(cat /etc/os-release | awk -F '=' '/^ID_LIKE=/{print $2}')" = "debian" ] && echo >&2 "FATAL: script tested on debian family distros. Read the script to understand how it works"

: ${FULLNAME:?'FATAL: missing FULLNAME variable'}
: ${EMAIL:?'FATAL: missing EMAIL variable'}


export DEBIAN_FRONTEND=noninteractive

apt-get update  -qq
apt-get install -qq -y curl git gnupg rng-tools

# ========================================================= SSH

# https://www.ssi.gouv.fr/guide/recommandations-pour-un-usage-securise-dopenssh/
ssh-keygen -t ed25519 -b 256 -N "" -f ~/.ssh/id_ed25519

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

while [ $(ssh -o LogLevel=ERROR -o StrictHostKeyChecking=accept-new -o RequestTTY=no git@github.com) -eq 255 ]; do
    echo "Nope. Retry please."
    read
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

# ========================================================= DOCKER

curl https://get.docker.com | bash
service docker start
usermod -aG docker $SUDO_USER

# (switch back to normal user)
exec su -l $SUDO_USER

# ========================================================= ASDF

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2

cat >> ~/.bashrc <<EOF

source \$HOME/.asdf/asdf.sh
source \$HOME/.asdf/completions/asdf.bash
EOF

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

}

# wrapped up in a function so that we have some protection against only getting
# half the file during "curl | sh"
do_install
