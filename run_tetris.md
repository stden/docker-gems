# Run Tetris with Docker

Image: [Tetris on Docker Hub](https://hub.docker.com/r/bsord/tetris).

The `docker run` command starts a new container from an image.

The command uses these options:

- `-d`: run the container in the background (detached mode).
  You can use the command line while the container runs.
- `-p 81:80`: connect port 81 on the host to port 80 in the container (port mapping).
  This makes the web server in the container available through the host.
  The web server in the container uses port 80, the standard HTTP port.
- `--name tetris`: give the container the name `tetris`.

The scripts `run_tetris.sh` and `run_tetris.cmd` run this command:
`docker run -d -p 81:80 --name tetris bsord/tetris`.
It creates and starts a container from the `bsord/tetris` image in the background.
The game is then available at `http://localhost:81`.

Then `run_tetris.sh` runs `open http://localhost:81`.
This command shows the page in the default browser.
If your system does not have the `open` command, open the address in a browser yourself.
`run_tetris.cmd` starts Google Chrome with the same address.
