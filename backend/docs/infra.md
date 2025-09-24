VM hosted on DigitalOcean under a project in Lachlan's Monash student account.

\$200 credit is provided to students for the first year, which is more than enough.

## Specs

- 4 vCPUs
- 8GB RAM
- 160GB SSD
- 4TB transfer

## VPS IP Address

`170.64.194.226`

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

Copy-paste all of the commands below at once and hit enter.

```sh
cd nOPark/backend
git pull
pkill -f "go run cmd/nOPark/main.go" || true
docker compose down --volumes --remove-orphans
docker compose up --detach --build --force-recreate
sleep 5
make migrate-up
mkdir -p logs
nohup make api > logs/api.log 2>&1 &
nohup make worker > logs/worker.log 2>&1 &
echo "Services started in background. Check logs in logs/ directory."
```

### Managing Services

To check service status:

```sh
# Check if services are running
pgrep -f "go run cmd/nOPark/main.go"

# View logs
tail -f logs/api.log
tail -f logs/worker.log
```

To stop services:

```sh
# Stop all Go processes
pkill -f "go run cmd/nOPark/main.go"
```
