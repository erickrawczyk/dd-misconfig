# Misconfiguration 3

This example intentionally misconfigures the database connection with an incorrect host and an incorrect ssl value. The host should be `localhost` or the name of the service and the ssl value should be `disable`.

## Incorrect configuration

The following configuration is incorrect:

`misconfig3.d/postgres.yaml`

```diff
init_config:

instances:
- host: "postgres"
+ host: "database"
  port: 5432
  username: "wrong_user"
  password: "wrong_password"
  dbname: "mydatabase"
- ssl: disable
+ ssl: "disable"

```
