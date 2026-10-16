# Use the official Python image as the base image.
FROM python:latest
# Install the security updates of the base image and the tree command. The official
# image can be days behind the security repository of the distribution.
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends tree && rm -rf /var/lib/apt/lists/*
# Set the working directory in the container.
WORKDIR /x
# Copy the dependency file to the working directory.
COPY requirements.txt ./
# Install the libraries from requirements.txt.
RUN pip install --no-cache-dir -r requirements.txt
# Copy the files from the build context to the working directory.
COPY . .
# Run this command when the container starts.
CMD ["python", "./my-test.py"]
