## Slack Configuration

To enable Slack notifications in `implement-prepare` and `implement-finalize`, add the following to your project's `CLAUDE.md`:

```
slack-channel-id: C0XXXXXXXXX
```

The `slack-channel-id` value is the Slack channel ID (not the name). To find it:
- Open the channel in Slack → click the channel name → scroll to the bottom of the popup → copy the Channel ID

### How it works

- If `slack-channel-id` is present → skill calls `mcp__claude_ai_Slack__slack_send_message` and stores the message `ts` as `thread_ts` for reply threading
- If absent → Slack step is silently skipped, `thread_ts = null`

### Requirements

- Slack: the claude.ai Slack connector must be connected with write access enabled (`/mcp` lists `slack_send_message`)
- GitHub: `gh` CLI installed and logged in (`gh auth status`) — PRs are created with `gh pr create --draft`
