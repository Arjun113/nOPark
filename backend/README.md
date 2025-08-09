See the make file for shortcut commands.

E.g. you can run `make api` to start the API.

To reset everything, copy paste all of these commands and hit enter:

```sh
docker compose down --volumes
docker compose up --detach
sleep 5
make migrate-up
make api
```

To test the api, download the Bruno API client and import the collection from `docs/bruno`
