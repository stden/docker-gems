// 🐋 Docker for Competitors — full slide deck
// Compile: typst compile docker-tutorial.typ docker-tutorial.pdf
// Images: docker-gems (stden/*)   Theme: metropolis   Diagrams: fletcher

#import "@preview/touying:0.8.0": *
#import themes.metropolis: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import fletcher.shapes: pill, diamond, hexagon

// ── Colour palette ───────────────────────────────────────────────────────────
#let docker-blue   = rgb("#0db7ed")
#let docker-dark   = rgb("#384d54")
#let ok-green      = rgb("#22c55e")
#let warn-yellow   = rgb("#facc15")
#let layer-colors  = (
  rgb("#dbeafe"), rgb("#bfdbfe"), rgb("#93c5fd"),
  rgb("#60a5fa"), rgb("#3b82f6"),
)

// ── Helper functions ─────────────────────────────────────────────────────────
#let tip(body) = block(
  fill: docker-blue.lighten(85%),
  stroke: (left: 3pt + docker-blue),
  inset: (x: 12pt, y: 8pt), radius: 4pt, body,
)
#let joke(body) = block(
  fill: rgb("#fef9c3"),
  stroke: (left: 3pt + rgb("#eab308")),
  inset: (x: 12pt, y: 8pt), radius: 4pt,
  text(style: "italic", body),
)
#let card(emoji, title, body) = rect(
  fill: docker-blue.lighten(90%),
  stroke: 0.5pt + docker-blue.lighten(50%),
  radius: 8pt, inset: 12pt, width: 100%,
)[
  #text(size: 20pt)[#emoji] *#title* \ #v(4pt) #body
]

// ── Theme ────────────────────────────────────────────────────────────────────
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title:       [🐋 Docker for Competitors],
    subtitle:    [Images · Containers · Volumes · Networks · Registries],
    date:        [November 2026],
    institution: [docker-gems],
  ),
  config-colors(
    primary:          docker-blue,
    secondary:        docker-dark,
    neutral-lightest: rgb("#f8fafc"),
    neutral-darkest:  rgb("#0f172a"),
  ),
  config-methods(new-section-slide-fn: none),
)

#set text(font: ("Segoe UI", "Segoe UI Emoji", "Arial"), size: 13pt)

#title-slide[]

// ─────────────────────────────────────────────────────────────────────────────
//  1. WHY DOCKER?
// ─────────────────────────────────────────────────────────────────────────────

== 🔥 The Problem: "Works on My Machine"

#grid(columns: (1fr, 1fr), gutter: 32pt)[
  #align(center)[
    *❌ Without Docker*
    #v(8pt)
    #diagram(
      node-stroke: 1pt, spacing: (4em, 2.5em),
      node((0,0), [💻 Laptop\ Python 3.9 · lib v1.2],
           fill: warn-yellow.lighten(60%), shape: rect, width: 9em),
      edge("d", "->", label: [send code], label-side: right),
      node((0,1), [🖥️ Server\ Python 3.11 · lib v2.0],
           fill: rgb("#fee2e2"), shape: rect, width: 9em),
      edge("d", "->"),
      node((0,2), [💥 Error!],
           fill: rgb("#fecaca"), shape: pill, width: 9em),
    )
  ]
][
  #align(center)[
    *✅ With Docker*
    #v(8pt)
    #diagram(
      node-stroke: 1pt, spacing: (4em, 2.5em),
      node((0,0), [💻 Laptop],
           fill: ok-green.lighten(70%), shape: rect, width: 9em),
      edge("d", "->", label: [`docker push`], label-side: right),
      node((0,1), [☁️ Registry],
           fill: docker-blue.lighten(70%), shape: rect, width: 9em),
      edge("d", "->", label: [`docker pull`], label-side: right),
      node((0,2), [🖥️ Server],
           fill: ok-green.lighten(70%), shape: rect, width: 9em),
      edge("d", "->"),
      node((0,3), [✅ It works!],
           fill: ok-green.lighten(60%), shape: pill, width: 9em),
    )
  ]
]

#v(6pt)
#grid(columns: (1fr, auto, 1fr, auto, 1fr), gutter: 6pt, align: horizon)[
  #rect(fill: ok-green.lighten(70%), radius: 6pt, inset: 8pt)[
    👨‍💻 Developer:\ *"Works on my machine!"*
  ]
][#text(size: 20pt)[→]][
  #rect(fill: warn-yellow.lighten(70%), radius: 6pt, inset: 8pt)[
    🕴️ Manager:\ *"Then ship your machine."*
  ]
][#text(size: 20pt)[→]][
  #rect(fill: docker-blue.lighten(70%), radius: 6pt, inset: 8pt)[
    🐋 Docker:\ *"Wait, I know what to do."*
  ]
]
#joke[😄 *Irony:* Docker solved "works on my machine" and created a new problem — "works in my container". Progress.]

== 🎯 Three Reasons to Use Docker

#grid(columns: (1fr, 1fr, 1fr), gutter: 16pt)[
  #card("🔒", "Isolation")[
    Each container sees only its own environment. Version conflicts disappear.
  ]
][
  #card("♻️", "Reproducibility")[
    One image — the same behavior on any host. No more environment surprises.
  ]
][
  #card("⚡", "Speed")[
    Start in seconds. A container is 10–100× lighter than a virtual machine.
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  2. DOCKER OBJECTS
// ─────────────────────────────────────────────────────────────────────────────

== 🗺️ Docker Objects: The Big Picture

#align(center)[
  #diagram(
    node-stroke: 2pt, spacing: (10em, 6em),

    node((0,0), [📄\ *Dockerfile*],   fill: layer-colors.at(0),        shape: rect, width: 9em),
    node((1,0), [🖼️\ *Image*],        fill: docker-blue.lighten(60%),  shape: rect, width: 9em),
    node((2,0), [☁️\ *Registry*],      fill: docker-blue.lighten(85%),  shape: rect, width: 9em),
    node((1,1), [📦\ *Container*],     fill: ok-green.lighten(60%),     shape: rect, width: 9em),
    node((0,1), [💾\ *Volume*],        fill: warn-yellow.lighten(60%),  shape: rect, width: 9em),
    node((2,1), [🌐\ *Network*],       fill: rgb("#e9d5ff"),             shape: rect, width: 9em),

    edge((0,0),(1,0), "->",               label: [`build`],  label-side: center),
    edge((1,0),(2,0), "->", bend:  30deg, label: [`push`],   label-side: center),
    edge((2,0),(1,0), "->", bend: -30deg, label: [`pull`],   label-side: center),
    edge((1,0),(1,1), "->",               label: [`run`],    label-side: right),
    edge((1,1),(0,1), "->", bend:  30deg, label: [write],    label-side: center),
    edge((0,1),(1,1), "->", bend: -30deg, label: [read],     label-side: center),
    edge((1,1),(2,1), "<->",              label: [ports],    label-side: center),
  )
]

== 🖼️ Image: The Blueprint

#grid(columns: (1fr, 1fr), gutter: 24pt)[
  An image is a *read-only template* for a container. It has *layers* — each layer is one `Dockerfile` instruction.

  Layers are *immutable* and *cached*. Change one line — Docker rebuilds only that layer and the ones below it.

  #tip[Image ≈ class in OOP.\ Container ≈ instance of that class.]

  #joke[🧅 A Docker image is like an onion: it has layers, and it can make you cry.]
][
  #align(center)[
    #diagram(
      node-stroke: 0.5pt, spacing: (0em, 1.5em),
      node((0,4), [`FROM debian:stable-slim`],    fill: layer-colors.at(0), shape: rect, width: 15em),
      node((0,3), [`RUN apt-get install ...`],     fill: layer-colors.at(1), shape: rect, width: 15em),
      node((0,2), [`COPY . /app`],                fill: layer-colors.at(2), shape: rect, width: 15em),
      node((0,1), [`WORKDIR /app`],               fill: layer-colors.at(3), shape: rect, width: 15em),
      node((0,0), [`CMD ["python", "app.py"]`],   fill: layer-colors.at(4), shape: rect, width: 15em),
      node((1,0), [← top layer\ _(writable)_],    stroke: none),
      node((1,4), [← base layer],                 stroke: none),
    )
  ]
]

== 📦 Container Lifecycle

#grid(columns: (5fr, 7fr), gutter: 28pt)[
  *Image → Container → Gone*

  #v(6pt)
  #diagram(
    node-stroke: 1pt, spacing: (0em, 2.8em),
    node((0,0), [🖼️ Image\ _(read-only)_],         fill: docker-blue.lighten(60%), shape: rect, width: 9em),
    edge("d", "->", label: [`docker run`],           label-side: right),
    node((0,1), [📦 Container\ _(+ thin RW layer)_], fill: ok-green.lighten(60%),  shape: rect, width: 9em),
    edge("d", "->", label: [`stop` + `rm`],          label-side: right),
    node((0,2), [🗑️ Gone\ _(RW layer erased)_],      fill: rgb("#fee2e2"),          shape: rect, width: 9em),
  )
  #v(8pt)
  #tip[💾 Use a *Volume* (`-v`) to keep data alive after `docker rm`.]
][
  *State machine*

  #v(6pt)
  #diagram(
    node-stroke: 1.5pt, spacing: (5.5em, 5em),

    node((0,0), [🆕\ *Created*],   fill: layer-colors.at(1),       shape: pill, width: 7em),
    node((1,0), [▶️\ *Running*],   fill: ok-green.lighten(60%),    shape: pill, width: 7em),
    node((2,0), [⏸️\ *Paused*],    fill: warn-yellow.lighten(60%), shape: pill, width: 7em),
    node((1,1), [⏹️\ *Stopped*],   fill: rgb("#fde68a"),            shape: pill, width: 7em),
    node((2,1), [🗑️\ *Removed*],   fill: rgb("#fecaca"),            shape: pill, width: 7em),

    // Created → Running
    edge((0,0),(1,0), "->", label: [`start`], label-side: center),

    // Running ↔ Paused (horizontal — bends separate labels)
    edge((1,0),(2,0), "->", bend:  30deg, label: [`pause`],   label-side: center),
    edge((2,0),(1,0), "->", bend: -30deg, label: [`unpause`], label-side: center),

    // Running ↔ Stopped (horizontal — node (1,1) placed below (1,0))
    // Use large bend to keep stop/start labels apart
    edge((1,0),(1,1), "->", bend:  55deg, label: [`stop`],  label-side: right),
    edge((1,1),(1,0), "->", bend: -55deg, label: [`start`], label-side: left),

    // Stopped → Removed
    edge((1,1),(2,1), "->", label: [`rm`], label-side: center),

    // Created → Stopped shortcut
    edge((0,0),(1,1), "->", label: [`run --rm`], label-side: left),
  )
]

== 💾 Volumes and 🌐 Networks

#grid(columns: (1fr, 1fr), gutter: 24pt)[
  *💾 Volume — persistent storage*

  #diagram(
    node-stroke: 1pt, spacing: (3em, 2em),
    node((0,0), [📦 Container v1], fill: ok-green.lighten(70%),   shape: rect, width: 7em),
    node((0,2), [📦 Container v2], fill: ok-green.lighten(70%),   shape: rect, width: 7em),
    node((1,1), [💾 Volume `/data`], fill: warn-yellow.lighten(60%), shape: rect, width: 7em),
    edge((0,0),(1,1), "<->"),
    edge((0,2),(1,1), "<->"),
  )
  ```sh
  docker volume create mydata
  docker run -v mydata:/data image
  ```
][
  *🌐 Network — container communication*

  #diagram(
    node-stroke: 1pt, spacing: (3em, 2em),
    node((0,0), [📦 app],    fill: ok-green.lighten(70%),    shape: rect, width: 5em),
    node((1,0), [🐬 db],     fill: docker-blue.lighten(70%), shape: rect, width: 5em),
    node((0,1), [💻 Host],   fill: layer-colors.at(0),       shape: rect, width: 5em),
    edge((0,0),(1,0), "<->", label: [`db:3306`], label-side: center),
    edge((0,1),(0,0), "->",  label: [`:8080`],  label-side: right),
  )
  ```sh
  docker network create mynet
  docker run --network mynet --name db postgres
  docker run --network mynet -p 8080:8080 app
  ```
]

// ─────────────────────────────────────────────────────────────────────────────
//  3. DOCKERFILE
// ─────────────────────────────────────────────────────────────────────────────

== 📋 Dockerfile: Anatomy

```dockerfile
# 1. Base image — always the first instruction
FROM python:slim

# 2. Working directory inside the container
WORKDIR /app

# 3. Dependencies first — before code, so the cache works
COPY requirements.txt .
RUN pip --no-cache-dir install -r requirements.txt

# 4. Application code
COPY . .

# 5. Start command (JSON form — passes signals correctly)
CMD ["python", "app.py"]
```

#tip[*Cache rule:* put stable layers first, changing layers last. Dependencies change less often than code — so install them earlier.]

#joke[😂 "I became a DevOps engineer!" — "Really? What do you do?" — "I write a list of packages in a Dockerfile and wait for it to build."]

== 🏗️ Multi-Stage Build

Use one stage to *build* and another to *run* — the final image is small.

```dockerfile
# ── Stage 1: build ───────────────────────────────────────────────────────────
FROM maven:3-amazoncorretto-25 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline       # Download dependencies separately — cache
COPY src ./src
RUN mvn package -DskipTests

# ── Stage 2: run ─────────────────────────────────────────────────────────────
FROM amazoncorretto:25-alpine        # Only JRE — no Maven, no source files
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

The final image has only `app.jar` + JRE — without source code, Maven, or caches.

== ❌ Common Mistakes vs ✅ Correct Patterns

#grid(columns: (1fr, 1fr), gutter: 20pt)[
  *❌ Wrong*

  ```dockerfile
  # apt-get update in one RUN,
  # install in another
  RUN apt-get update
  RUN apt-get install -y curl
  # Problem: apt-get update is cached
  # but curl is stale
  ```

  ```dockerfile
  # Copy everything before dependencies
  COPY . .
  RUN pip install -r requirements.txt
  # Problem: any code change
  # reinstalls all dependencies
  ```
][
  *✅ Correct*

  ```dockerfile
  # update + install + cleanup — always together
  RUN apt-get update \
   && apt-get install -y --no-install-recommends curl \
   && rm -rf /var/lib/apt/lists/*
  ```

  ```dockerfile
  # Dependencies before code
  COPY requirements.txt .
  RUN pip install -r requirements.txt
  COPY . .
  ```
]

// ─────────────────────────────────────────────────────────────────────────────
//  4. DOCKER COMPOSE
// ─────────────────────────────────────────────────────────────────────────────

== 🎼 Docker Compose: Run Multiple Services Together

`docker-compose.yml` describes all application services in one file.

```yaml
services:
  # Database service
  db:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: myapp
    volumes:
      - db-data:/var/lib/mysql    # Data persists in a volume

  # Application service
  app:
    build: .                       # Build from the local Dockerfile
    ports:
      - "8080:8080"                # host:container
    depends_on:
      - db                         # Start db before app

volumes:
  db-data:                         # Named volume — data survives restarts
```
```sh
docker compose up      # Start everything
docker compose down    # Stop and remove containers
```

== 🔗 Services Find Each Other · 🚀 Image Journey

#grid(columns: (1fr, 1fr), gutter: 28pt)[
  *Inside a Compose network — use service name as hostname*

  #v(6pt)
  #align(center)[
    #diagram(
      node-stroke: 1.5pt, spacing: (5.5em, 3.5em),
      node((0,0), [💻 Host\ `localhost:8080`],  fill: layer-colors.at(0),       shape: rect, width: 9em),
      edge((0,0),(1,0), "<->", label: [port 8080],         label-side: center),
      node((1,0), [📦 app\ `app:8080`],         fill: ok-green.lighten(60%),    shape: rect, width: 7.5em),
      edge((1,0),(1,1), "<->", label: [`mysql://db:3306`], label-side: right),
      node((1,1), [🐬 db\ `db:3306`],           fill: docker-blue.lighten(60%), shape: rect, width: 7.5em),
      edge((1,1),(0,1), "<->", label: [volume],            label-side: center),
      node((0,1), [💾 db-data],                 fill: warn-yellow.lighten(60%), shape: rect, width: 7.5em),
    )
  ]
][
  *Code → Registry → Running container*

  #v(6pt)
  #align(center)[
    #diagram(
      node-stroke: 1.5pt, spacing: (0em, 3.2em),
      node((0,0), [📄 Code +\ Dockerfile],   fill: layer-colors.at(0),       shape: rect, width: 10em),
      edge("d", "->", label: [`docker build`], label-side: right),
      node((0,1), [🖼️ Image (local)],         fill: docker-blue.lighten(60%), shape: rect, width: 10em),
      edge("d", "->", label: [`docker push`],  label-side: right),
      node((0,2), [☁️ Docker Hub / ECR],        fill: docker-blue.lighten(85%), shape: rect, width: 10em),
      edge("d", "->", label: [`docker pull`],  label-side: right),
      node((0,3), [🖼️ Image (server)],         fill: docker-blue.lighten(60%), shape: rect, width: 10em),
      edge("d", "->", label: [`docker run`],   label-side: right),
      node((0,4), [📦 Container running ✅],   fill: ok-green.lighten(60%),   shape: rect, width: 10em),
    )
  ]
]

// ─────────────────────────────────────────────────────────────────────────────
//  5. REGISTRIES
// ─────────────────────────────────────────────────────────────────────────────

== ☁️ Registries: Docker Hub and Image Publication

#grid(columns: (1fr, 1fr), gutter: 24pt)[
  A registry stores images and lets you share them.

  Docker Hub is the most popular public registry. An image name has this format:

  `username/image-name:tag`

  The tag `latest` is the default. For production, pin an exact tag or a digest `@sha256:…`.
][
  ```sh
  # Log in to Docker Hub
  docker login

  # Build and tag the image
  docker build -t myuser/myapp:1.0 .

  # Push to the registry
  docker push myuser/myapp:1.0

  # Pull on another host
  docker pull myuser/myapp:1.0

  # Run without pulling manually
  docker run myuser/myapp:1.0
  ```
]

// ─────────────────────────────────────────────────────────────────────────────
//  6. DOCKER-GEMS COURSE MAP
// ─────────────────────────────────────────────────────────────────────────────

== 📚 docker-gems Course Map

#let badge(label, color) = box(
  fill: color, stroke: color.darken(20%),
  radius: 4pt, inset: (x: 6pt, y: 3pt),
  text(size: 9pt, label),
)

#table(
  columns: (auto, 1fr, auto),
  stroke: 0.5pt + docker-dark.lighten(60%),
  fill: (_, row) => if calc.odd(row) { docker-blue.lighten(92%) } else { white },
  inset: 8pt,
  [*Image*], [*Teaches this concept*], [*Level*],

  [`python`],        [Simple container, testing tools],                badge([🟢 Beginner], ok-green.lighten(60%)),
  [`java`],          [Multi-stage build, Maven],                       badge([🟢 Beginner], ok-green.lighten(60%)),
  [`rust`],          [Rust tools in a container],                      badge([🟢 Beginner], ok-green.lighten(60%)),
  [`my-python-app`], [Docker Compose: app + MySQL],                    badge([🟡 Intermediate], warn-yellow.lighten(40%)),
  [`web-qa`],        [Playwright, browser testing],                    badge([🟡 Intermediate], warn-yellow.lighten(40%)),
  [`allure`],        [Test reports],                                   badge([🟡 Intermediate], warn-yellow.lighten(40%)),
  [`code-quality`],  [Static analysis, linters],                      badge([🟡 Intermediate], warn-yellow.lighten(40%)),
  [`java-eks`],      [Spring Boot → Kubernetes (EKS)],                 badge([🔴 Advanced], rgb("#fca5a5")),
  [`argocd`],        [GitOps: ArgoCD + Kubernetes],                    badge([🔴 Advanced], rgb("#fca5a5")),
  [`crossplane`],    [Infrastructure as Code from the cluster],        badge([🔴 Advanced], rgb("#fca5a5")),
  [`android`],       [Mobile build in CI],                             badge([🔴 Advanced], rgb("#fca5a5")),
  [`graphify`],      [Knowledge graph, MCP server],                    badge([🔴 Advanced], rgb("#fca5a5")),
)

== 📈 Learning Progression

#align(center)[
  #diagram(
    node-stroke: 1.5pt, spacing: (5em, 2.5em),
    node((0,0), [*🟢 Basic Images*\ python · java · rust],          fill: ok-green.lighten(60%),   shape: rect, width: 12em),
    edge("d", "->"),
    node((0,1), [*🟡 Compose*\ my-python-app],                      fill: warn-yellow.lighten(50%), shape: rect, width: 12em),
    edge("d", "->"),
    node((0,2), [*🟡 Testing*\ web-qa · allure · code-quality],     fill: docker-blue.lighten(60%), shape: rect, width: 12em),
    edge("d", "->"),
    node((0,3), [*🔴 Kubernetes*\ java-eks · argocd · crossplane],  fill: rgb("#e9d5ff"),            shape: rect, width: 12em),
    edge("d", "->"),
    node((0,4), [*🔴 Advanced*\ android · cuda · graphify],         fill: rgb("#fecaca"),            shape: rect, width: 12em),
  )
]

#joke[🚢 *Kubernetes* is like Docker Compose — except you stop pretending you are in control.]

// ─────────────────────────────────────────────────────────────────────────────
//  7. CHEAT SHEET
// ─────────────────────────────────────────────────────────────────────────────

== 📋 Cheat Sheet: Key Commands

#grid(columns: (1fr, 1fr), gutter: 20pt)[
  *🖼️ Images*
  ```sh
  docker build -t name:tag .   # Build
  docker images                # List
  docker rmi name:tag          # Delete
  docker pull name:tag         # Download
  docker push name:tag         # Upload
  ```

  *☁️ Registry*
  ```sh
  docker login
  docker logout
  docker search python
  ```
][
  *📦 Containers*
  ```sh
  docker run -it name bash       # Run interactively
  docker run -d -p 80:8080 name  # In background, with port
  docker ps                      # Running containers
  docker ps -a                   # All containers
  docker stop id                 # Stop
  docker rm id                   # Delete
  docker logs id                 # View logs
  docker exec -it id bash        # Enter container
  ```
]

*🎼 Compose*
```sh
docker compose up -d           # Start all services in background
docker compose down            # Stop and remove containers
docker compose logs -f app     # Follow service logs
docker compose ps              # Service status
```
#joke[⏳ "`docker build` takes 10 minutes" — the only legitimate reason to make coffee, eat a snack, and have an existential crisis at your desk.]

== 🎯 Next Steps

#grid(columns: (1fr, 1fr, 1fr), gutter: 16pt)[
  #card("1️⃣", "Run the images")[
    Clone `docker-gems` and run any image from the table. Start with `python` or `java`.

    ```sh
    git clone https://github.com/\
      stden/docker-gems
    cd docker-gems/python
    ./up.sh
    ```
  ]
][
  #card("2️⃣", "Write a Dockerfile")[
    Package your competitive programming solution in a Docker image. Goal: `docker run` → result.
  ]
][
  #card("3️⃣", "Build a pipeline")[
    Add `.github/workflows/docker.yml` so the image builds automatically on each `git push`.
  ]
]

#v(8pt)
#tip[*Good practice:* always test with `docker run --rm image command` before publishing. The `--rm` flag removes the container after it exits — useful for quick checks.]

#joke[🏆 *Levels of DevOps enlightenment:*
1. "Works on my machine" — developer on a laptop
2. "Works in my container" — discovered Docker
3. "Works in the cluster" — learned Kubernetes
4. "Something works, I have no idea what" — Senior DevOps Engineer]
