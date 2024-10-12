# Misconfiguration 1

This example intentionally misconfigures multiline log processing to create a scenario where logs are not ingested correctly. Initially multi-line logs are not being processed correctly, but even after uncommenting the `log_processing_rules` section, the logs are still not being ingested correctly.

## Incorrect configuration

The following configuration is incorrect:

`misconfig1.d/conf.yaml`

```yaml
logs:
  - type: file
    path: /var/log/flask/flask.log
    service: misconfig1
    source: flask
    tags:
      - environment:development
    log_processing_rules:
      - type: multi_line
        name: pattern_multiline
        pattern: "\d{4}-\d{2}-\d{2}" # Incorrect pattern (missing backslashes and brackets)
        improper_key: true # Misconfigured parameter (should be 'include_at_match')
```

## Solution

```diff
 logs:
   - type: file
     path: /var/log/flask/flask.log
     service: misconfig1
     source: flask
     tags:
       - environment:development
     log_processing_rules:
       - type: multi_line
         name: faulty_multiline
-        pattern: "\d{4}-\d{2}-\d{2}"
-        improper_key: true
+        pattern: "\\d{4}-\\d{2}-\\d{2}"
+        include_at_match: true
```

### Correct Configuration

`misconfig1.d/conf.yaml`

```yaml
logs:
  - type: file
    path: /var/log/flask/flask.log
    service: misconfig1
    source: flask
    tags:
      - environment:development
    log_processing_rules:
      - type: multi_line
        name: pattern_multiline
        pattern: "\\d{4}-\\d{2}-\\d{2}"
        include_at_match: true
```
