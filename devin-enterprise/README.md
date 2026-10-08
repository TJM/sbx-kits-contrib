# devin-enterprise (managed-credential variant — repro)

[Devin CLI](https://devin.ai) pinned to a Devin Enterprise deployment (`<org>.devinenterprise.com`), using the **same managed-credential design as the [`devin`](../devin) kit** — `credentials[]` with an `oauth` capture block plus `apiKey` injection, and the stock `devin` entrypoint wrapper.

## ⚠️ This kit is a repro, not a working config

It demonstrates [docker/sbx-releases#683](https://github.com/docker/sbx-releases/issues/683): on enterprise deployments the sign-in succeeds (`Login successful! Credentials stored.`) but the durable-key credential handoff never fires, so when the wrapper rewrites `credentials.toml` to the `devin-proxy-managed` sentinel and re-checks `auth status`, the fetch fails with `invalid api key` and the agent exits with `Failed to secure Devin credentials.`

```bash
sbx run "git+https://github.com/TJM/sbx-kits-contrib.git#ref=devin-enterprise-managed&dir=devin-enterprise" \
  --kit-arg org=<your-org>
```

(Or `sbx run ./devin-enterprise --kit-arg org=<your-org>` from a local clone of this branch.)

Observed on sbx v0.47.0, macOS arm64:

- `proxy: intercepted OAuth token response ... api.devinenterprise.com/auth/cli/token expires_in_seconds:0` — the intermediate is captured
- no `Devin credential handoff` log line ever appears
- `proxy: overriding client-supplied credential with host credential` injects the captured intermediate on every gated request → `invalid api key`

The working variant — same kit shape but with credential passthrough instead of the managed contract — lives on the `devin-enterprise-kit` branch of this fork and is the basis of https://github.com/docker/sbx-kits-contrib/pull/351.
