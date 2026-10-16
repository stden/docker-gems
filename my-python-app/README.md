# stden/my-python-app

Learn Docker networking with a Python website check and a MySQL query.

## Contents

- Python with Requests, Flask, NumPy, and MySQL Connector/Python
- A sample script that checks a website and reads rows from MySQL
- SQL files that create and fill the sample database
- The `tree` command to show the directory structure

The working directory is `/x`. The default command runs `python ./my-test.py`.
It requests `https://www.google.com`, then queries the `user` table in the database.
Requests use a 15-second timeout. A failed website check stops the program before the database query.

It runs once and exits. It does not start a web server.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/my-python-app/tags).

## Pull and run

```sh
docker pull stden/my-python-app:latest
docker run --rm stden/my-python-app:latest \
  python -c 'import requests, flask, numpy, mysql.connector; print("Libraries are ready.")'
```

To run the full example, prepare a MySQL database with the
[sample SQL](https://github.com/stden/docker-gems/blob/main/my-python-app/my-db.sql).
The database must accept connections before you start the application.

In this example, a MySQL container named `db` is on the `course-net` Docker network.
Set the database user and password to match your database. `change-me` is a placeholder.

```sh
docker run --rm --network course-net \
  -e DB_HOST=db -e DB_USER=user -e DB_PASSWORD=change-me -e DB_NAME=my_db \
  stden/my-python-app:latest
```

## Run the full course example

The repository includes a Compose file that starts MySQL, creates the sample data,
waits for MySQL, and builds the Python application:

```sh
git clone https://github.com/stden/docker-gems.git
cd docker-gems
docker compose up --build --abort-on-container-exit --exit-code-from app
docker compose down
```

The Compose file uses example passwords. The named database volume keeps its data after
`docker compose down`. Use a separate project and credentials for your own application.

## Checks and source

GitHub Actions runs the Compose example twice: first with a new volume, then with the same volume.

[Dockerfile](https://github.com/stden/docker-gems/blob/main/my-python-app/Dockerfile) ·
[Compose file](https://github.com/stden/docker-gems/blob/main/docker-compose.yml) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)
