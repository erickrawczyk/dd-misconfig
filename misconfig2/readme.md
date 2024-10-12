# Misconfiguration 2

This example intentionally misconfigures the hostname to create a scenario where logs are not ingested correctly and an unrelated error is logged.

## Incorrect configuration

The following configuration is incorrect:

`datadog.yaml`

```diff
  site: us5.datadoghq.com
+ hostname: misconfig2
  logs_enabled: true
```
