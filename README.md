# datasplice-zendesk

Datasplice package that reads tickets from the Zendesk Support API.

## Settings

| Setting | Type | Required | Description |
|---|---|---|---|
| `subdomain` | string | yes | `foo` for `foo.zendesk.com` |

## Secrets

| Name | Description |
|---|---|
| `ZENDESK_EMAIL` | Email of the API user |
| `ZENDESK_TOKEN` | API token (see below) |

**Getting a token:** Zendesk Admin Center -> Apps and integrations -> APIs ->
Zendesk API -> enable *Token access* -> Add API token. The token is shown once.

## Actions

`tickets` (source): every ticket, 100 per page, cursor pagination. Adds one
derived field, `via_channel` (from `via.channel`).

## Example `main.yaml`

```yaml
name: "zendesk tickets"

steps:
  - uses: "github.com/datasplice-labs/datasplice-zendesk@v0.1.0"
    action: "tickets"
    secrets: ["ZENDESK_EMAIL", "ZENDESK_TOKEN"]
    with:
      subdomain: "mycompany"

  - uses: "datasplice/map"
    with:
      select: ["id", "subject", "status", "priority", "created_at", "via_channel"]

  - uses: "datasplice/csv"
    with:
      path: "tickets.csv"
      atomic: true
```

With a `secrets.yaml` next to it:

```yaml
secrets:
  type: "file"
  filepath: ".env"
```

Then `datasplice get`, `datasplice plan`, `datasplice run`.
