# Get Push Notifications on `ssh` Login

I configured a linux server to send me push notifications whenever someone logs in over `ssh`. This explains how I did it

## Summary
1. Make a [Pushover.net](https://pushover.net) account and install the Pushover app on your devices.
2. Install the CLI app called `ntf`. It's what sends notifications.
3. Create a bash script that sends a push notification with the login details.
4. Configure `pam` to run the script on login

## Setup Pushover
Create a [Pushover.net](https://pushover.net) account. Install the apps on your devices... Or use a different backend...

## Install `ntf`

You can find `ntf` at https://github.com/hrntknr/ntf

It's easy to follow the [ntf Quickstart guide](https://github.com/hrntknr/ntf#quickstart). It shows you how to download the binary, create a config file, and test that it works. You'll need to install the binary to `/root/bin/`. 

If you prefer, you can compile `ntf` from source.  On my system, I created a temporary debian container to build it from source. If you have `lxd` you can follow along:
```bash
# create the container
lxc launch  images:debian/bullseye build-ntf

# launch a shell in the container
lxc exec build-ntf bash
```

Then on the debian system, install go, clone the repo, and build the binary:

```bash
apt-get install --yes wget git

# install go
wget https://go.dev/dl/go1.19.5.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.5.linux-amd64.tar.gz
export PATH="$PATH:/usr/local/go/bin"

# build ntf
git clone https://github.com/hrntknr/ntf.git
cd ntf
go build

# test ntf
./ntf help
```

If you built `ntf` from source, copy the binary to your server:
```bash
# copy the file out of the lxc container:
sudo lxc file pull build-ntf/root/ntf/ntf .

# upload it to the sever
scp ./ntf user@server.example.com:/root/bin/ntf
```

Make sure the binary is at `/root/bin/ntf`

## Install the bash script

Copy the bash script, called `notify-ssh-login.sh`, from this repo to your server.

```bash
scp notify-ssh-login.sh user@server.example.com:/root/bin/notify-ssh-login.sh
```

Note: the script uses `jq`. So you might need to install that. On debian run:
```bash
sudo apt-get install jq
```

## Configure PAM

Edit `/etc/pam.d/sshd`
```bash
vim /etc/pam.d/sshd
```

Add this to the end:
```
# Send notification when someone logs in
session    optional    pam_exec.so    seteuid    /root/bin/notify-ssh-login.sh
```

And that's it! Now when someone logs in you should get a push notification. The benefit of using `pam_exec.so` over invoking the script in your `.profile` file is that you'll get the notification when someone:
- uses `scp`
- skips the regular login routine using the optional `command` argument. For example: `ssh me@host bash`.
