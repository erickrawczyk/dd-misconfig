# Datadog Misconfigurations Demo

This repository contains Docker configurations and applications designed to demonstrate common misconfigurations with Datadog integration. The examples highlight how to identify and fix these misconfigurations with correct setups for logging and service monitoring.

Each misconfiguration example in this repository includes its own `readme.md` file, detailing the specific misconfiguration and providing solutions to rectify it.

## Prerequisites

- Docker and Docker Compose installed on your system.
- A Datadog account with an available API key.

## Environment Variables

Before running the containers, you'll need to configure your environment variables. This repository includes an `.env.example` file as a template. Follow these steps to set up your `.env` file:

1. Copy the example file to create a new `.env` file:

   ```bash
   cp .env.example .env
   ```

2. Open the `.env` file and update the `DD_API_KEY` with your Datadog API key.

## Usage

### Running the Containers

Build and start the containers in detached mode using

```bash
docker-compose up -d --build
```

### Accessing the Applications

The correctly configured application is accessible at http://localhost:8080.
Incorrect configurations are accessible at incrementing ports, starting at 8081.

In practice, you'll mostly be accessing them by shelling into the container to diagnose the issue.

### Viewing Logs

To see the logs of all running containers, use

```bash
docker-compose logs -f
```

### Stopping the Containers

To stop all running services, use

```bash
docker-compose down
```

## Troubleshooting

To check the status of the Datadog agent, run the following command:

```bash
docker exec -it <container_id> datadog-agent status
```

To check the logs of the Datadog agent, run the following command:

```bash
docker exec -it <container_id> cat /var/log/datadog/agent.log
```

To access the shell inside of a container, run the following command:

```bash
docker exec -it <container_id> bash
```

## License

This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
