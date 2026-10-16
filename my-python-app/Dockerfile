# Use the official Python image as the base image.
FROM python:latest
# Install the tree command in the image.
RUN apt-get update && apt-get install -y tree && rm -rf /var/lib/apt/lists/*
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
