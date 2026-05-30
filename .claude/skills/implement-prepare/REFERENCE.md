## Slack Configuration

To enable Slack notifications in `implement-prepare` and `implement-finalize`, add the following to your project's `CLAUDE.md`:

```
slack-channel-id: C0XXXXXXXXX
```

The `slack-channel-id` value is the Slack channel ID (not the name). To find it:
- Open the channel in Slack → click the channel name → scroll to the bottom of the popup → copy the Channel ID

### How it works

- If `slack-channel-id` is present → skill calls `mcp__slack__slack_post_message` and stores `thread_ts` for reply threading
- If absent → Slack step is silently skipped, `thread_ts = null`

### MCP requirement

Slack notifications require the `mcp__slack__*` MCP server to be configured. Add to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-...",
        "SLACK_TEAM_ID": "T0XXXXXXXXX"
      }
    }
  }
}
```

`SLACK_BOT_TOKEN` requires the `chat:write` and `channels:read` OAuth scopes.
