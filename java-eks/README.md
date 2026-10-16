# stden/java-eks

Run a Spring Boot REST API with Java 25 LTS, OpenAPI, and Kubernetes examples.

Use this application to learn how to run a Java service in Docker or Amazon Elastic
Kubernetes Service (EKS). The container listens on port `8080`.

## Tags

| Tag | Meaning | Platform |
| --- | --- | --- |
| `latest` | Latest successful `main` build | `linux/amd64` |

[View tags and image digests](https://hub.docker.com/r/stden/java-eks/tags).

## Pull and run

```sh
docker pull stden/java-eks:latest
docker run --rm --name docker-gems-java -p 127.0.0.1:8080:8080 stden/java-eks:latest
```

After the application starts, run this command in another terminal:

```sh
curl --fail http://localhost:8080/api/health
```

Open `http://localhost:8080/swagger-ui/index.html` to use the API documentation.
The working directory is `/app`. The image starts its application JAR with `JAVA_OPTS`.

[Application source](https://github.com/stden/docker-gems/tree/main/java-eks) ·
[Dockerfile](https://github.com/stden/docker-gems/blob/main/java-eks/Dockerfile) ·
[Docker tutorial](https://github.com/stden/docker-gems/blob/main/README.md) ·
[Build results](https://github.com/stden/docker-gems/actions)

## Features

- A REST API to create, read, update, and delete products
- API documentation with Swagger/OpenAPI 3.1
- Spring Boot 4.1 on Java 25 (LTS)
- A Docker container based on Amazon Corretto 25
- An `/api/health` endpoint to check the application
- Test coverage above 95% with JaCoCo
- Kubernetes manifests to deploy the application

## Project layout

```
java-eks/
│
├── src/main/java/com/example/demo/      # Application source
│   ├── controller/                      # REST controllers
│   │   ├── HealthController.java        # Health-check endpoint
│   │   └── ProductController.java       # Product API
│   ├── model/                           # Data models
│   │   └── Product.java                 # Product model
│   └── DemoApplication.java             # Application entry point
│
├── src/main/resources/                  # Application resources
│   └── application.yml                  # Spring Boot configuration
│
├── src/test/                            # Tests
│   ├── java/...                         # Test classes
│   └── resources/application.yml        # Test configuration
│
├── kubernetes/                          # Kubernetes configuration
│   ├── kustomization.yaml               # kubectl apply -k kubernetes
│   ├── namespace.yaml                   # Namespace eks-demo
│   ├── deployment.yaml                  # Deployment
│   └── service.yaml                     # Service and Ingress
│
├── .mvn/wrapper/, mvnw, mvnw.cmd       # Maven Wrapper: downloads Maven 3.10.0
├── Dockerfile                           # Docker image build
├── pom.xml                              # Maven configuration
└── README.md                            # Project documentation
```

## Requirements

- JDK 25 or newer
- Docker
- kubectl (to deploy to Kubernetes)
- AWS CLI (to deploy to AWS EKS)

It is not necessary to install Maven. `./mvnw` downloads the necessary version. On Windows, use `mvnw.cmd`.

## Quick start

### Build and run the project locally

1. If necessary, clone the project repository.

   ```bash
   git clone https://github.com/stden/docker-gems.git
   ```

2. Open the project directory.

   ```bash
   cd docker-gems/java-eks
   ```

3. Build the project with Maven.

   ```bash
   ./mvnw clean package
   ```

4. Start the application.

   ```bash
   java -jar target/eks-demo-0.0.1-SNAPSHOT.jar
   ```

The application is available at http://localhost:8080.

### Run the tests and check coverage

1. Run the tests with a coverage report.

   ```bash
   ./mvnw clean test jacoco:report
   ```

2. Open the report at `target/site/jacoco/index.html`.

3. Check that the coverage meets the 95% minimum.

   ```bash
   ./mvnw clean verify
   ```

### Build and run the Docker image

These steps do not use a JDK or Maven on the host.

1. Build the Docker image.

   ```bash
   docker build -t stden/java-eks:latest .
   ```

2. Start the container.

   ```bash
   docker run -p 8080:8080 stden/java-eks:latest
   ```

3. Publish the image only after its tests pass. GitHub Actions runs the tests and publishes
   the image from `main`. To build, test, and publish it manually, run this command from
   the `java-eks` directory:

   ```bash
   ../ci/publish-image.sh java-eks
   ```

   [test-images.sh](https://github.com/stden/docker-gems/blob/main/test-images.sh) runs
   `mvn -B verify` with the 95% JaCoCo check in `maven:3-amazoncorretto-25`. Then it starts
   the container and checks HTTP 200 from `/api/health`, `/api-docs`, and
   `/swagger-ui/index.html`.

### Deploy to AWS EKS

The [AWS guide](https://github.com/stden/docker-gems/blob/main/aws/README.md) shows how to
copy the image to Amazon ECR. It also shows how to create an EKS cluster with Auto Mode. The
`alb` IngressClass from that guide is necessary for the Ingress.

1. Apply the namespace, the Deployment, the Service, and the Ingress.

   ```bash
   kubectl apply -k kubernetes
   ```

2. Wait until both pods are ready.

   ```bash
   kubectl -n eks-demo rollout status deployment/eks-demo
   ```

3. Check the pods, the Service, and the address of the Ingress.

   ```bash
   kubectl -n eks-demo get pods,services,ingress
   ```

The pods run as a non-root user with a read-only root filesystem, and the namespace
enforces the `restricted` Pod Security Standard. The image platform is linux/amd64, so
the pods run only on amd64 nodes.

## API endpoints

Use these endpoints after the application starts.

### API documentation

- **Swagger UI**: `/swagger-ui.html`
- **OpenAPI specification**: `/api-docs`

### Product endpoints

- **GET /api/products** — list all products
- **GET /api/products/{id}** — get a product by ID
- **POST /api/products** — create a product
- **PUT /api/products/{id}** — update a product
- **DELETE /api/products/{id}** — delete a product
- **GET /api/products/categories/{category}** — list products in a category

### Monitoring and health

- **GET /api/health** — check the application. The response includes JVM and system information.

## API examples

### Create a product

```bash
curl -X POST "http://localhost:8080/api/products" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New product",
    "description": "Product description",
    "price": 299.99,
    "category": "Electronics",
    "stockQuantity": 10
  }'
```

### List the products

```bash
curl -X GET "http://localhost:8080/api/products"
```

## Application settings

### Environment variables

- `JAVA_OPTS` — JVM options (default: `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError`)
- `SPRING_PROFILES_ACTIVE` — the active Spring profile (for example `dev`, `prod`, or `test`)

### Kubernetes configuration

The `kubernetes/` directory contains these files:

- **deployment.yaml** defines the Deployment:
  - 2 replicas for availability
  - resource settings (CPU and memory)
  - readiness and liveness probes

- **service.yaml** defines the Service and the Ingress:
  - a ClusterIP Service for access inside the cluster
  - an Ingress with an Application Load Balancer for access from outside the cluster

## Testing

The project includes these tests and coverage checks:

- **Unit tests** for every controller and model
- **Integration tests** for how the components work together
- **Coverage** above 95%, which JaCoCo checks
