# Run Open WebUI, a self-hosted chat interface for Ollama and OpenAI-compatible APIs.
# The upstream image includes the embedding models, so the server can start offline.
FROM ghcr.io/open-webui/open-webui:latest

# Install the security updates of the base image. The official image can be days
# behind the security repository of the distribution.
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Upgrade the Python libraries that have known vulnerabilities in the upstream image.
# unstructured limits filelock to a release below 4.0.0, so filelock stays.
# The smoke test starts the server after the upgrade.
RUN pip install --no-cache-dir --root-user-action=ignore --upgrade \
      'cryptography>=50' 'setuptools>=78.1.1' \
      'transformers>=5.10' 'unstructured>=0.24' 'sentence-transformers>=5.6' \
      'pyarrow>=23.0.1' 'fsspec>=2026.6.0' 'black>=26.10.1' 'PyJWT>=2.14.0'

# Match the TorchAudio CPU wheel to the upstream Torch runtime.
# TorchAudio 2.11 uses the stable ABI of Torch 2.11 and later.
RUN torchaudio_spec=$(python -c 'from importlib.metadata import version; \
torch_version = version("torch"); \
torch_release = tuple(map(int, torch_version.split(".")[:2])); \
print("torchaudio~=2.11.0" if torch_release >= (2, 11) else f"torchaudio=={torch_version}")') \
 && pip install --no-cache-dir --root-user-action=ignore \
      --index-url https://download.pytorch.org/whl/cpu "$torchaudio_spec" \
 && python -c 'import torch, torchaudio; print(torch.__version__, torchaudio.__version__)'
