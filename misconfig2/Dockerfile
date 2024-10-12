# Use an official Python runtime as a parent image
FROM python:3.9

# Set the working directory in the container
WORKDIR /usr/src/app

# Install deps
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl

# Install Flask, ddtrace for APM, and Datadog Python client
RUN pip install flask ddtrace datadog

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

RUN bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"

# Copy Datadog configuration files
COPY datadog.yaml /etc/datadog-agent/datadog.yaml
COPY misconfig2.d/conf.yaml /etc/datadog-agent/conf.d/misconfig2.d/conf.yaml
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 80 for the Flask app
EXPOSE 80

# Start the Datadog agent and the Flask app
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
