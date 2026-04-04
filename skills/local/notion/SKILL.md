---
name: notion
description: Read and write Notion pages, blocks, and databases via the Notion API. Use when working with Notion content, searching pages, querying databases/data sources, creating pages, updating properties, appending blocks, or wiring this machine to a Notion integration token.
---

# Notion

Use the Notion API directly from this machine.

## Setup

1. Ensure the API key is stored at `~/.config/notion/api_key`.
2. Ensure the target pages or databases are shared with the integration.
3. Read `references/api.md` before making requests unless the task is trivial and already obvious.

## Workflow

1. Read the API key from `~/.config/notion/api_key`.
2. Search first when the page or database ID is unknown.
3. Inspect existing page or database structure before writing.
4. Prefer fewer larger writes over many tiny writes.
5. For writes, summarize the exact target and intended change before executing if the user’s instruction is ambiguous.

## Guardrails

- Treat the Notion API key as secret material; never paste it back to chat.
- Respect rate limits; avoid tight one-item loops when a batched write will do.
- When updating a database entry, confirm the property names from the live object first.
- Use `Notion-Version: 2025-09-03`.
- In this API version, querying uses `/v1/data_sources/{id}/query`, while page creation under a database still uses `parent.database_id`.

## Common tasks

- Find a page or database: read `references/api.md#search`
- Read a page: read `references/api.md#get-page`
- Read page blocks: read `references/api.md#get-block-children`
- Query a database/data source: read `references/api.md#query-a-data-source`
- Create a page in a database: read `references/api.md#create-a-page-in-a-database`
- Update page properties: read `references/api.md#update-page-properties`
- Append blocks: read `references/api.md#append-block-children`

## Local setup helper

If the user asks to configure Notion access on this machine, create the key file like this:

```bash
mkdir -p ~/.config/notion
chmod 700 ~/.config/notion
printf '%s\n' 'ntn_your_key_here' > ~/.config/notion/api_key
chmod 600 ~/.config/notion/api_key
```

Then test with a search call from `references/api.md`.
