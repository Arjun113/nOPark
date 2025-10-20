VM hosted on DigitalOcean under a project in Lachlan's Monash student account.

\$200 credit is provided to students for the first year, which is more than enough.

## Specs

- 4 vCPUs
- 8GB RAM
- 160GB SSD
- 4TB transfer

## VPS IP Address

`170.64.194.226`

## Domains

`nopark-api.lachlanmacphee.com`

This is the subdomain for the API

`nopark-tiles.lachlanmacphee.com`

This is the subdomain for the tile server https://github.com/CrunchyData/pg_tileserv

## SSH Access

Username/password combo is stored in Lachlan's Bitwarden vault.

## Domain

Both subdomains are A records on Lachlan's Namecheap domain.

## Setup

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```sh
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo apt install gh
gh auth login

sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
chmod o+r /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
sudo apt install make

git clone https://github.com/Arjun113/nOPark.git
```

## Setup Part Two

Installed golang with [this guide](https://www.cherryservers.com/blog/install-go-ubuntu-2404).

## Deployment

You may want to reboot the VM if nothing is working.

```sh
sudo reboot
```

If you just want to update the code, run the below:

```sh
cd nOPark/backend
git fetch --all
git reset --hard origin/main
pkill -f "bin/nOPark" # this may be wrong, but we don't want to stop the docker processes!
go mod download
make build
make migrate-up
mkdir -p logs
caddy stop
nohup ./bin/nOPark api > logs/api.log 2>&1 &
nohup ./bin/nOPark worker > logs/worker.log 2>&1 &
caddy start
```

If you want to reset everything, copy-paste all of the commands below at once and hit enter.

```sh
cd nOPark/backend
git fetch --all
git reset --hard origin/main
docker compose down --volumes --remove-orphans
pkill -f "nOPark"
sleep 5
docker compose up --detach --build --force-recreate
sleep 5
go mod download
make build
make migrate-up
mkdir -p logs
caddy stop
nohup ./bin/nOPark api > logs/api.log 2>&1 &
nohup ./bin/nOPark worker > logs/worker.log 2>&1 &
caddy start
```

### Managing Services

To check service status:

```sh
# Check if services are running
pgrep -f -l "nOPark"

# View logs
tail -f logs/api.log
tail -f logs/worker.log
```

To stop services:

```sh
# Stop all nOPark processes
pkill -f "nOPark"
```
