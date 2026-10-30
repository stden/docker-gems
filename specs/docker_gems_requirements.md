# Docker Gems Repository Requirements

## Acceptance Criteria

- AC-1: Given all top-level directories with a Dockerfile, when each image overview "README.md" is checked, then each file starts with "# stden/<directory>", has a blank second line, has a third line of at most 100 bytes, and is smaller than 25000 bytes.
- AC-2: Given all top-level directories with a Dockerfile, when "ci/hub-categories.json" is checked, then every image has between 1 and 3 Docker Hub categories.
- AC-3: Given the Java LTS image configurations, when the Java version is checked across "java/Dockerfile", "java-eks/pom.xml", "java-run-swing/Dockerfile", and "android/Dockerfile", then all four files use Java 25.
- AC-4: Given the service image "java-eks/Dockerfile", when the runtime user configuration is checked, then it sets "USER 10001:10001".
- AC-5: Given all top-level Dockerfiles in the repository, when package repository instructions are checked, then no Dockerfile contains "--allow-insecure-repositories" or "--allow-unauthenticated".
- AC-6: Given all top-level directories with a Dockerfile, when "ci/hub-categories.json" is checked, then every image has "languages-and-frameworks" in its category list.
- AC-7: Given all top-level directories with a Dockerfile, when the "up.sh" and "up.cmd" files are checked, then every image except "compilers", "latex", and "java-eks" has both "up.sh" and "up.cmd".
- AC-8: Given all top-level Dockerfiles in the repository, when ENV instructions are checked for secret patterns, then no Dockerfile sets a secret value in an ENV instruction.
- AC-9: Given "argocd/Dockerfile" and "argocd/kubernetes/kustomization.yaml", when the Argo CD version is checked in both files, then both files reference the same Argo CD version.
- AC-10: Given "java-ui-browser/Dockerfile" and "android/Dockerfile", when the Gradle version is checked in both, then both files pin the same Gradle version.
