See the make file for shortcut commands.

E.g. you can run `make api` to start the API.

To reset everything, copy paste all of these commands and hit enter:

**On macOS:**

```sh
cp -n .env.example .env
docker compose down --volumes
docker compose up --detach --build --force-recreate
sleep 5
make migrate-up
make api
```

**On Windows**

```sh
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
}

docker compose down --volumes
docker compose up --detach --build --force-recreate
Start-Sleep -Seconds 5
make migrate-up
make api
```

To test the api, download the Bruno API client and import the collection from `docs/bruno`
