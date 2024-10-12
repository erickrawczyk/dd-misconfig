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
