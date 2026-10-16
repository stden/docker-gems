#!/bin/bash
# Start the MySQL container.
export DATA=/Users/x/Desktop/my-super-sql/
docker run --name my-super-sql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=my-secret-pw -v $DATA:/var/lib/mysql mysql:latest

# Options:
# --name mysql-x                - Set the container name.
# -e MYSQL_ROOT_PASSWORD=...    - Set the MYSQL_ROOT_PASSWORD environment variable.
#                                 This variable sets the password for the MySQL root user.
# -d                           - Run the container in the background.
# mysql:tag                    - Set the image name and tag, for example, 'latest'.
# -p 3306:3306                 - Connect to MySQL from the host.
# Mount a volume to keep data after the container restarts.