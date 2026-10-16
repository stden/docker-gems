# Docker Gems Repository Requirements

## Acceptance Criteria

- AC-1: Given all top-level directories with a Dockerfile, when each image overview "README.md" is checked, then each file starts with "# stden/<directory>", has a blank second line, has a third line of at most 100 bytes, and is smaller than 25000 bytes.
- AC-2: Given all top-level directories with a Dockerfile, when "ci/hub-categories.json" is checked, then every image has between 1 and 3 Docker Hub categories.
- AC-3: Given the Java LTS image configurations, when the Java version is checked across "java/Dockerfile", "java-eks/pom.xml", "java-run-swing/Dockerfile", and "android/Dockerfile", then all four files use Java 25.
- AC-4: Given the service image "java-eks/Dockerfile", when the runtime user configuration is checked, then it sets "USER 10001:10001".
- AC-5: Given all top-level Dockerfiles in the repository, when package repository instructions are checked, then no Dockerfile contains "--allow-insecure-repositories" or "--allow-unauthenticated".
