# Notion API reference

Use this reference when performing Notion API calls.

## Setup

Read the API key:

```bash
NOTION_KEY=$(cat ~/.config/notion/api_key)
NOTION_VERSION='2025-09-03'
```

Common headers:

```bash
-H "Authorization: Bearer $NOTION_KEY" \
-H "Notion-Version: $NOTION_VERSION" \
-H "Content-Type: application/json"
```

## Search

Search pages and data sources when IDs are unknown.

```bash
curl -X POST "https://api.notion.com/v1/search" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: $NOTION_VERSION" \
  -H "Content-Type: application/json" \
  -d '{"query": "page title"}'
```

## Get page

```bash
curl "https://api.notion.com/v1/pages/{page_id}" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: $NOTION_VERSION"
```

## Get block children

```bash
curl "https://api.notion.com/v1/blocks/{block_or_page_id}/children" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: $NOTION_VERSION"
```

## Query a data source

In API version `2025-09-03`, query databases via the data source endpoint.

```bash
curl -X POST "https://api.notion.com/v1/data_sources/{data_source_id}/query" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: $NOTION_VERSION" \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {"property": "Status", "select": {"equals": "Active"}},
    "sorts": [{"property": "Date", "direction": "descending"}]
  }'
```

## Create a page in a database

Page creation still uses `parent.database_id`.

```bash
curl -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: $NOTION_VERSION" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"database_id": "xxx"},
    "properties": {
      "Name": {"title": [{"text": {"content": "New Item"}}]},
      "Status": {"select": {"name": "Todo"}}
    }
  }'
```

## Create a data source

```bash
curl -X POST "https://api.notion.com/v1/data_sources" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: $NOTION_VERSION" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"page_id": "xxx"},
    "title": [{"text": {"content": "My Database"}}],
    "properties": {
      "Name": {"title": {}},
      "Status": {"select": {"options": [{"name": "Todo"}, {"name": "Done"}]}},
      "Date": {"date": {}}
    }
  }'
```

## Update page properties

```bash
curl -X PATCH "https://api.notion.com/v1/pages/{page_id}" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: $NOTION_VERSION" \
  -H "Content-Type: application/json" \
  -d '{"properties": {"Status": {"select": {"name": "Done"}}}}'
```

## Append block children

```bash
curl -X PATCH "https://api.notion.com/v1/blocks/{page_id}/children" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: $NOTION_VERSION" \
  -H "Content-Type: application/json" \
  -d '{
    "children": [
      {
        "object": "block",
        "type": "paragraph",
        "paragraph": {
          "rich_text": [{"text": {"content": "Hello"}}]
        }
      }
    ]
  }'
```

## Common property shapes

- Title: `{"title": [{"text": {"content": "..."}}]}`
- Rich text: `{"rich_text": [{"text": {"content": "..."}}]}`
- Select: `{"select": {"name": "Option"}}`
- Multi-select: `{"multi_select": [{"name": "A"}, {"name": "B"}]}`
- Date: `{"date": {"start": "2024-01-15", "end": "2024-01-16"}}`
- Checkbox: `{"checkbox": true}`
- Number: `{"number": 42}`
- URL: `{"url": "https://..."}`
- Email: `{"email": "a@b.com"}`
- Relation: `{"relation": [{"id": "page_id"}]}`

## Notes

- IDs are UUIDs, with or without dashes.
- Search results for databases appear as `object: "data_source"` in this API version.
- A database now effectively has both a `database_id` and a `data_source_id`.
- The API cannot control database view filters from the UI.
- Rate limit is roughly 3 requests per second average; serialize bursts.
