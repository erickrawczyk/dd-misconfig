# Use an official Python runtime as a parent image
FROM python:3.9

# Set the working directory in the container
WORKDIR /usr/src/app

# Install deps
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl postgresql nano

# Install Flask, ddtrace for APM, and Datadog Python client
RUN pip install flask ddtrace datadog psycopg2 supervisor

# Copy application files
COPY . .

# Create log directory for the Flask app
RUN mkdir -p /var/log/flask

# Define build arguments to accept API key and site at build time
ARG DD_API_KEY

# Set environment variables for API key and site
ENV DD_API_KEY=${DD_API_KEY}
ENV DD_SITE="us5.datadoghq.com"
ENV DD_INSTALL_ONLY=true
ENV DD_ENV=development
ENV DD_SERVICE="misconfig5"
ENV DD_ENV="development" 
ENV DD_LOGS_INJECTION=true
ENV DD_TRACE_SAMPLE_RATE="1"
ENV DD_PROFILING_ENABLED=true
ENV DD_APPSEC_ENABLED=true
ENV DD_IAST_ENABLED=true 
ENV DD_APPSEC_SCA_ENABLED=true 
ENV DD_GIT_COMMIT_SHA=${DD_GIT_COMMIT_SHA}
ENV DD_GIT_REPOSITORY_URL=${DD_GIT_REPOSITORY_URL}

# Copy Datadog configuration files
COPY datadog.yaml /etc/datadog-agent/datadog.yaml
COPY misconfig5.d/conf.yaml /etc/datadog-agent/conf.d/misconfig5.d/conf.yaml
COPY postgres.d/conf.yaml /etc/datadog-agent/conf.d/postgres.d/conf.yaml


# Expose port 80 for the Flask app
EXPOSE 80

# Start the Datadog agent and the Flask app
CMD ["ddtrace-run", "python", "app.py"]
