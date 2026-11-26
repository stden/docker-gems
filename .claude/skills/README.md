# Claude Code skills

Each subdirectory is an Agent Skill with one `SKILL.md` file. The format follows the
[Agent Skills specification](https://agentskills.io/specification). The rules for all
work in this repository are in [AGENTS.md](../../AGENTS.md). The skills give the
procedures step by step.

| Skill | Use it to |
| --- | --- |
| [add-docker-image](add-docker-image/SKILL.md) | Add a new image directory and connect it to the tests, CI, and documentation |
| [publish-docker-images](publish-docker-images/SKILL.md) | Push to `main`, watch GitHub Actions, and check the result on Docker Hub |
| [code-graphs](code-graphs/SKILL.md) | Map a codebase, find callers and impact, and find affected tests with the Graphify and CodeGraph images |
| [copy-images-to-ecr](copy-images-to-ecr/SKILL.md) | Copy tested images to Amazon ECR with the same digest, and configure the GitHub Actions workflow |
| [deploy-images-to-eks](deploy-images-to-eks/SKILL.md) | Create the EKS cluster, deploy the applications, test the manifests in kind, and delete the resources |
| [crossplane-install](crossplane-install/SKILL.md) | Install, upgrade, check, and remove Crossplane with the restricted Pod Security settings |
| [crossplane-aws-providers](crossplane-aws-providers/SKILL.md) | Install AWS providers with EKS Pod Identity, add AWS services, and create managed resources |
| [crossplane-compositions](crossplane-compositions/SKILL.md) | Write XRDs and Compositions, and test them without a cluster with validate and render |
| [crossplane-packages](crossplane-packages/SKILL.md) | Build, push (for example to ECR), and install Configuration packages |
| [crossplane-troubleshooting](crossplane-troubleshooting/SKILL.md) | Find why a package, provider, or resource is not healthy, synced, or ready |
