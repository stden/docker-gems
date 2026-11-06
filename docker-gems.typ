// 🐋 Docker for Competitors — 7 slides
// Compile: typst compile docker-gems.typ docker-gems.pdf
// Images: docker-gems (stden/*)   Theme: metropolis   Diagrams: fletcher

#import "@preview/touying:0.8.0": *
#import themes.metropolis: *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import fletcher.shapes: pill

// ── Colour palette ────────────────────────────────────────────────────────────
#let docker-blue  = rgb("#0db7ed")
#let docker-dark  = rgb("#384d54")
#let ok-green     = rgb("#22c55e")
#let warn-yellow  = rgb("#facc15")
#let layer-colors = (
  rgb("#dbeafe"), rgb("#bfdbfe"), rgb("#93c5fd"),
  rgb("#60a5fa"), rgb("#3b82f6"),
)

// ── Helpers ───────────────────────────────────────────────────────────────────
#let tip(body)  = block(fill: docker-blue.lighten(85%),
  stroke: (left: 3pt + docker-blue), inset: (x: 10pt, y: 6pt), radius: 4pt, body)
#let joke(body) = block(fill: rgb("#fef9c3"),
  stroke: (left: 3pt + rgb("#eab308")), inset: (x: 10pt, y: 6pt), radius: 4pt,
  text(style: "italic", body))
#let badge(label, color) = box(fill: color, stroke: color.darken(20%),
  radius: 4pt, inset: (x: 6pt, y: 3pt), text(size: 9pt, label))

// ── Theme ─────────────────────────────────────────────────────────────────────
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title:       [🐋 Docker for Competitors],
    subtitle:    [7 slides — Images · Containers · Dockerfile · Compose · docker-gems],
    date:        [November 2026],
    institution: [docker-gems],
  ),
  config-colors(primary: docker-blue, secondary: docker-dark,
    neutral-lightest: rgb("#f8fafc"), neutral-darkest: rgb("#0f172a")),
  config-methods(new-section-slide-fn: none),
)
#set text(font: ("Segoe UI", "Segoe UI Emoji", "Arial"), size: 12pt)

// ═════════════════════════════════════════════════════════════════════════════
//  1. WHY DOCKER?   Problem + 3 reasons
// ═════════════════════════════════════════════════════════════════════════════

== 🐋 Docker for Competitors

#align(center)[
  #text(size: 9pt, fill: docker-dark.lighten(40%))[
    Images · Containers · Dockerfile · Compose · docker-gems · November 2026
  ]
]
#v(4pt)
#grid(columns: (1fr, 1fr, 1fr), gutter: 16pt)[
  *❌ Without Docker*
  #align(center)[
    #diagram(node-stroke: 1pt, spacing: (3em, 2em),
      node((0,0), [💻 Laptop\ Python 3.9], fill: warn-yellow.lighten(60%), shape: rect, width: 8em),
      edge("d", "->", label: [ship code], label-side: right),
      node((0,1), [🖥️ Server\ Python 3.11], fill: rgb("#fee2e2"), shape: rect, width: 8em),
      edge("d", "->"),
      node((0,2), [💥 Error!], fill: rgb("#fecaca"), shape: pill, width: 8em),
    )
  ]
][
  *✅ With Docker*
  #align(center)[
    #diagram(node-stroke: 1pt, spacing: (3em, 2em),
      node((0,0), [💻 Laptop], fill: ok-green.lighten(70%), shape: rect, width: 8em),
      edge("d", "->", label: [`push`], label-side: right),
      node((0,1), [☁️ Registry], fill: docker-blue.lighten(70%), shape: rect, width: 8em),
      edge("d", "->", label: [`pull`], label-side: right),
      node((0,2), [🖥️ Server], fill: ok-green.lighten(70%), shape: rect, width: 8em),
      edge("d", "->"),
      node((0,3), [✅ Works!], fill: ok-green.lighten(60%), shape: pill, width: 8em),
    )
  ]
][
  *3 reasons*
  #v(4pt)
  #block(fill: ok-green.lighten(80%), radius: 6pt, inset: 8pt, width: 100%)[
    🔒 *Isolation* \ Each container sees only its own environment.
  ]
  #v(4pt)
  #block(fill: docker-blue.lighten(80%), radius: 6pt, inset: 8pt, width: 100%)[
    ♻️ *Reproducibility* \ Same image — same behavior on any host.
  ]
  #v(4pt)
  #block(fill: warn-yellow.lighten(70%), radius: 6pt, inset: 8pt, width: 100%)[
    ⚡ *Speed* \ Starts in seconds. 10–100× lighter than a VM.
  ]
  #v(4pt)
  #joke[😄 Docker solved "works on my machine" — and created "works in my container". Progress.]
]

// ═════════════════════════════════════════════════════════════════════════════
//  2. DOCKER OBJECTS + IMAGE LAYERS
// ═════════════════════════════════════════════════════════════════════════════

== 🗺️ Docker Objects + Image Layers

#grid(columns: (3fr, 2fr), gutter: 24pt)[
  #align(center)[
    #diagram(node-stroke: 1.5pt, spacing: (7em, 4.5em),
      node((0,0), [📄\ *Dockerfile*], fill: layer-colors.at(0), shape: rect, width: 8em),
      node((1,0), [🖼️\ *Image*],      fill: docker-blue.lighten(60%), shape: rect, width: 8em),
      node((2,0), [☁️\ *Registry*],   fill: docker-blue.lighten(85%), shape: rect, width: 8em),
      node((1,1), [📦\ *Container*],  fill: ok-green.lighten(60%), shape: rect, width: 8em),
      node((0,1), [💾\ *Volume*],     fill: warn-yellow.lighten(60%), shape: rect, width: 8em),
      node((2,1), [🌐\ *Network*],    fill: rgb("#e9d5ff"), shape: rect, width: 8em),

      edge((0,0),(1,0), "->",               label: [`build`], label-side: center),
      edge((1,0),(2,0), "->", bend:  30deg, label: [`push`],  label-side: center),
      edge((2,0),(1,0), "->", bend: -30deg, label: [`pull`],  label-side: center),
      edge((1,0),(1,1), "->",               label: [`run`],   label-side: right),
      edge((1,1),(0,1), "->", bend:  30deg, label: [write],   label-side: center),
      edge((0,1),(1,1), "->", bend: -30deg, label: [read],    label-side: center),
      edge((1,1),(2,1), "<->", bend: 20deg, label: [ports],   label-side: center),
    )
  ]
][
  *Image = stacked layers*

  #align(center)[
    #diagram(node-stroke: 0.5pt, spacing: (0em, 1.4em),
      node((0,4), [`FROM debian:slim`],       fill: layer-colors.at(0), shape: rect, width: 13em),
      node((0,3), [`RUN apt-get install`],    fill: layer-colors.at(1), shape: rect, width: 13em),
      node((0,2), [`COPY . /app`],            fill: layer-colors.at(2), shape: rect, width: 13em),
      node((0,1), [`WORKDIR /app`],           fill: layer-colors.at(3), shape: rect, width: 13em),
      node((0,0), [`CMD ["python","app.py"]`],fill: layer-colors.at(4), shape: rect, width: 13em),
      node((1,0), [← top _(RW)_],  stroke: none),
      node((1,4), [← base],        stroke: none),
    )
  ]
  #v(6pt)
  #tip[Image ≈ class. Container ≈ instance. \ Layers are *immutable* and *cached*.]
  #joke[🧅 Like an onion: layers, and it can make you cry.]
]

// ═════════════════════════════════════════════════════════════════════════════
//  3. CONTAINER LIFECYCLE + VOLUMES + NETWORKS
// ═════════════════════════════════════════════════════════════════════════════

== 📦 Container: Lifecycle · Volumes · Networks

#grid(columns: (3fr, 2fr), gutter: 20pt)[
  *State machine*
  #align(center)[
    #diagram(node-stroke: 1.5pt, spacing: (2em, 3.5em),
      node((0,0), [🆕\ *Created*],  fill: layer-colors.at(1), shape: pill, width: 5em),
      node((1,0), [▶️\ *Running*],  fill: ok-green.lighten(60%), shape: pill, width: 5em),
      node((2,0), [⏹️\ *Stopped*],  fill: rgb("#fde68a"), shape: pill, width: 5em),
      node((3,0), [🗑️\ *Removed*],  fill: rgb("#fecaca"), shape: pill, width: 5em),
      node((1,1), [⏸️\ *Paused*],   fill: warn-yellow.lighten(60%), shape: pill, width: 5em),

      edge((0,0),(1,0), "->", label: [`start`], label-side: center),
      edge((1,0),(2,0), "->", bend:  25deg, label: [`stop`],    label-side: center),
      edge((2,0),(1,0), "->", bend: -25deg, label: [`start`],   label-side: center),
      edge((2,0),(3,0), "->", label: [`rm`], label-side: center),
      edge((1,0),(1,1), "->", bend:  25deg, label: [`pause`],   label-side: right),
      edge((1,1),(1,0), "->", bend: -25deg, label: [`unpause`], label-side: left),
      edge((0,0),(2,0), "->", bend: -20deg, label: [`run --rm`], label-side: right),
    )
  ]
][
  *💾 Volume*

  Data survives `docker rm`.

  #align(center)[
    #diagram(node-stroke: 1pt, spacing: (2.5em, 2em),
      node((0,0), [📦 v1], fill: ok-green.lighten(70%), shape: rect, width: 5em),
      node((0,2), [📦 v2], fill: ok-green.lighten(70%), shape: rect, width: 5em),
      node((1,1), [💾 `/data`], fill: warn-yellow.lighten(60%), shape: rect, width: 5em),
      edge((0,0),(1,1), "<->"),
      edge((0,2),(1,1), "<->"),
    )
  ]
  ```sh
  docker run \
    -v mydata:/data \
    image
  ```
][
  *🌐 Network*

  Services use each other's *name* as hostname.

  #align(center)[
    #diagram(node-stroke: 1pt, spacing: (3.5em, 2.5em),
      node((0,0), [📦 app], fill: ok-green.lighten(70%), shape: rect, width: 5em),
      node((1,0), [🐬 db],  fill: docker-blue.lighten(70%), shape: rect, width: 5em),
      node((0,1), [💻 Host],fill: layer-colors.at(0), shape: rect, width: 5em),
      edge((0,0),(1,0), "<->", bend: 25deg, label: [`db:3306`], label-side: center),
      edge((0,1),(0,0), "->",  label: [`:8080`], label-side: right),
    )
  ]
  ```sh
  docker run \
    --network mynet \
    --name db postgres
  ```
]

// ═════════════════════════════════════════════════════════════════════════════
//  4. DOCKERFILE
// ═════════════════════════════════════════════════════════════════════════════

== 📋 Dockerfile: Write It Right

#grid(columns: (1fr, 1fr), gutter: 20pt)[
  *Anatomy*
  ```dockerfile
  # 1. Base image — always first
  FROM python:slim
  WORKDIR /workspace
  # 2. Dependencies before code — cache stays valid
  COPY requirements.txt .
  RUN pip --no-cache-dir install -r requirements.txt
  # 3. Code last — changes here don't reinstall deps
  COPY . .
  CMD ["python", "app.py"]
  ```
  *Multi-stage — final image has only what runs*
  ```dockerfile
  FROM maven:3-amazoncorretto-25 AS build
  RUN mvn package -DskipTests
  # ── Only JRE in the final image ──────────────────
  FROM amazoncorretto:25-alpine
  COPY --from=build /app/target/*.jar app.jar
  CMD ["java", "-jar", "app.jar"]
  ```
][
  *❌ Wrong → ✅ Right*

  ```dockerfile
  # ❌ Two RUN — apt-get update is cached, curl is stale
  RUN apt-get update
  RUN apt-get install -y curl

  # ✅ Always one RUN: update + install + cleanup
  RUN apt-get update \
   && apt-get install -y --no-install-recommends curl \
   && rm -rf /var/lib/apt/lists/*
  ```

  ```dockerfile
  # ❌ Copy code first — any change reinstalls deps
  COPY . .
  RUN pip install -r requirements.txt

  # ✅ Copy requirements first — deps are cached
  COPY requirements.txt .
  RUN pip install -r requirements.txt
  COPY . .
  ```
  #joke[😂 "I became a DevOps engineer!" — "I write a list of packages and wait for it to build."]
]

// ═════════════════════════════════════════════════════════════════════════════
//  5. DOCKER COMPOSE + IMAGE JOURNEY
// ═════════════════════════════════════════════════════════════════════════════

== 🎼 Docker Compose + Image Journey

#grid(columns: (1fr, auto, 1fr), gutter: 20pt)[
  *`docker-compose.yml`*
  ```yaml
  services:
    db:
      image: mysql:8
      volumes:
        - db-data:/var/lib/mysql
    app:
      build: .
      ports: ["8080:8080"]
      depends_on: [db]
  volumes:
    db-data:
  ```
  ```sh
  docker compose up   # start all
  docker compose down # stop all
  ```
][
  #align(center)[
    #diagram(node-stroke: 1.5pt, spacing: (4.5em, 3em),
      node((0,0), [💻 Host\ `:8080`], fill: layer-colors.at(0), shape: rect, width: 8em),
      edge((0,0),(1,0), "<->", bend: 20deg, label: [8080], label-side: center),
      node((1,0), [📦 app], fill: ok-green.lighten(60%), shape: rect, width: 6em),
      edge((1,0),(1,1), "<->", label: [`db:3306`], label-side: right),
      node((1,1), [🐬 db], fill: docker-blue.lighten(60%), shape: rect, width: 6em),
      edge((1,1),(0,1), "<->", bend: 20deg, label: [vol], label-side: center),
      node((0,1), [💾 db-data], fill: warn-yellow.lighten(60%), shape: rect, width: 6em),
    )
  ]
][
  *Code → container in 4 steps*
  #align(center)[
    #diagram(node-stroke: 1.5pt, spacing: (0em, 2.8em),
      node((0,0), [📄 Code +\ Dockerfile],  fill: layer-colors.at(0), shape: rect, width: 10em),
      edge("d", "->", label: [`docker build`], label-side: right),
      node((0,1), [🖼️ Image (local)],        fill: docker-blue.lighten(60%), shape: rect, width: 10em),
      edge("d", "->", label: [`docker push`],  label-side: right),
      node((0,2), [☁️ Registry],              fill: docker-blue.lighten(85%), shape: rect, width: 10em),
      edge("d", "->", label: [`docker run`],   label-side: right),
      node((0,3), [📦 Running ✅],            fill: ok-green.lighten(60%), shape: rect, width: 10em),
    )
  ]
]

// ═════════════════════════════════════════════════════════════════════════════
//  6. DOCKER-GEMS COURSE MAP + PROGRESSION
// ═════════════════════════════════════════════════════════════════════════════

== 📚 docker-gems + Cheat Sheet

#grid(columns: (2fr, 3fr, 2fr), gutter: 14pt)[
  #table(
    columns: (auto, 1fr, auto),
    stroke: 0.5pt + docker-dark.lighten(60%),
    fill: (_, row) => if calc.odd(row) { docker-blue.lighten(92%) } else { white },
    inset: 7pt,
    [*Image*], [*Concept*], [*Level*],
    [`python`],        [Simple container, testing tools],         badge([🟢], ok-green.lighten(60%)),
    [`java`],          [Multi-stage build, Maven],                badge([🟢], ok-green.lighten(60%)),
    [`rust`],          [Rust tools in a container],               badge([🟢], ok-green.lighten(60%)),
    [`my-python-app`], [Compose: app + MySQL],                    badge([🟡], warn-yellow.lighten(40%)),
    [`web-qa`],        [Playwright, browser testing],             badge([🟡], warn-yellow.lighten(40%)),
    [`allure`],        [Test reports],                            badge([🟡], warn-yellow.lighten(40%)),
    [`code-quality`],  [Static analysis, linters],               badge([🟡], warn-yellow.lighten(40%)),
    [`java-eks`],      [Spring Boot → Kubernetes],                badge([🔴], rgb("#fca5a5")),
    [`argocd`],        [GitOps],                                  badge([🔴], rgb("#fca5a5")),
    [`crossplane`],    [Infrastructure as Code],                  badge([🔴], rgb("#fca5a5")),
    [`android`],       [Mobile build in CI],                      badge([🔴], rgb("#fca5a5")),
    [`graphify`],      [Knowledge graph, MCP],                    badge([🔴], rgb("#fca5a5")),
  )
][
  *Learning path*

  #diagram(node-stroke: 1.5pt, spacing: (3em, 2em),
    node((0,0), [🟢 *Basics*\ python · java · rust],        fill: ok-green.lighten(60%), shape: rect, width: 11em),
    edge("d", "->"),
    node((0,1), [🟡 *Compose*\ my-python-app],              fill: warn-yellow.lighten(50%), shape: rect, width: 11em),
    edge("d", "->"),
    node((0,2), [🟡 *Testing*\ web-qa · allure · quality],  fill: docker-blue.lighten(60%), shape: rect, width: 11em),
    edge("d", "->"),
    node((0,3), [🔴 *Kubernetes*\ java-eks · argocd],       fill: rgb("#e9d5ff"), shape: rect, width: 11em),
    edge("d", "->"),
    node((0,4), [🔴 *Advanced*\ android · graphify],        fill: rgb("#fecaca"), shape: rect, width: 11em),
  )
  #v(6pt)
  #joke[🚢 *Kubernetes* is like Compose — except you stop pretending you are in control.]
][
  #grid(columns: (1fr, 1fr), gutter: 12pt)[
    *🖼️ Images*
    ```sh
    docker build -t name:tag .
    docker images
    docker pull name:tag
    docker push name:tag
    docker rmi name:tag
    ```
    *☁️ Registry*
    ```sh
    docker login
    docker push name:tag
    docker pull name:tag
    ```
  ][
    *📦 Containers*
    ```sh
    docker run -it name bash
    docker run -d -p 80:8080 name
    docker ps / docker ps -a
    docker stop id / docker rm id
    docker logs id
    docker exec -it id bash
    ```
    *🎼 Compose*
    ```sh
    docker compose up -d
    docker compose down
    docker compose logs -f app
    ```
  ]
][
  *🎯 Next steps*

  *1️⃣ Run the images*
  ```sh
  git clone https://github.com/\
    stden/docker-gems
  cd docker-gems/python && ./up.sh
  ```

  *2️⃣ Write a Dockerfile*

  Package your solution. Goal: `docker run` → result.

  *3️⃣ Build a pipeline*

  Add `.github/workflows/docker.yml` — auto-build on every `git push`.

  #v(4pt)
  #tip[`docker run --rm` removes the container after it exits — great for quick tests.]

  #joke[🏆 *DevOps enlightenment:* 1. "Works on my machine" 2. "Works in my container" 3. "Works in the cluster" 4. "Something works, I have no idea what."]
]

// ═════════════════════════════════════════════════════════════════════════════
//  7. AI PROMPTS + ONE-LINERS
// ═════════════════════════════════════════════════════════════════════════════

== 🤖 AI Prompts + ⚡ One-liners

#grid(columns: (1fr, 1fr), gutter: 20pt)[
  *🤖 Give these prompts to Claude / ChatGPT*

  #let prompt(body) = block(
    fill: rgb("#f0f4ff"),
    stroke: (left: 3pt + docker-blue),
    inset: (x: 10pt, y: 6pt), radius: 4pt,
    text(size: 10pt, style: "italic", body),
  )

  #prompt["Write a Dockerfile for a *[Python / Java / Rust]* app. Use multi-stage build. Keep the final image small."]

  #v(4pt)
  #prompt["My Docker container exits immediately. Find the problem and fix it:\n`[paste your Dockerfile]`"]

  #v(4pt)
  #prompt["Convert this `docker run` command to `docker-compose.yml`:\n`docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=secret postgres`"]

  #v(4pt)
  #prompt["My image is *[X] MB*. Reduce its size. Here is the Dockerfile:\n`[paste Dockerfile]`"]

  #v(4pt)
  #prompt["Explain this Docker error and show how to fix it:\n`[paste error message]`"]

][
  *⚡ Useful one-liners*

  ```sh
  # Live CPU and memory usage for all containers
  docker stats

  # Remove all stopped containers, unused images, networks
  docker system prune -f

  # Enter a running container
  docker exec -it <name> bash

  # Explore any image without installing anything
  docker run --rm -it <image> sh

  # Run a tool on the current directory
  docker run --rm -v "$PWD":/workspace \
    stden/code-quality hadolint Dockerfile

  # Follow the last 50 log lines
  docker logs -f --tail 50 <name>

  # Copy a file out of a container
  docker cp <name>:/app/config.json .

  # Show image sizes sorted
  docker image ls \
    --format "{{.Repository}}:{{.Tag}} {{.Size}}" \
    | sort -k2 -h

  # Show all open ports
  docker ps --format "{{.Names}}: {{.Ports}}"
  ```
]
