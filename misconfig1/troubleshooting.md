## Troubleshooting

To check the status of the Datadog agent, run the following command:

```bash
docker exec -it <misconfig1_container_id> datadog-agent status
```

To check the logs of the Datadog agent, run the following command:

```bash
docker exec -it <misconfig1_container_id> cat /var/log/datadog/agent.log
```
