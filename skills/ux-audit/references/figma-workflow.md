# Figma MCP Integration Workflow

How to push the audit report HTML into Figma using `mcp__figma__generate_figma_design`.

## Overview

The Figma MCP tool captures a web page and converts it into a Figma design. The workflow requires:
1. The report HTML served via a local HTTP server
2. A JavaScript capture snippet injected into the browser
3. Polling for capture completion

## Step-by-Step

### 1. Get the Capture Snippet

Call `mcp__figma__generate_figma_design` WITHOUT a `captureId`:

```
mcp__figma__generate_figma_design({})
```

This returns:
- A JavaScript snippet to run in the browser
- A list of recent Figma files (for `existingFile` mode)
- A list of available plans (for `newFile` mode)

### 2. Choose Output Mode

Ask the user (or use config from `.ux-audit.json`):

- **`newFile`**: Creates a new Figma file. Requires `planKey` (team/org) and `fileName`.
- **`existingFile`**: Adds to an existing file. Requires `fileKey` and optionally `nodeId`.
- **`clipboard`**: Copies to clipboard for manual paste.

Call again with the chosen mode:

```
mcp__figma__generate_figma_design({
  outputMode: "newFile",
  planKey: "team-key-from-list",
  fileName: "ProjectName UX Audit"
})
```

or

```
mcp__figma__generate_figma_design({
  outputMode: "existingFile",
  fileKey: "gnJ9S1Bf1o8cWIxKpCy1Ec"
})
```

This returns a `captureId` and the JS snippet.

### 3. Serve the Report Locally

Start a simple HTTP server:

```bash
cd {outputDir}
python3 -m http.server 8765
```

The report will be accessible at `http://localhost:8765/ux-audit-report.html`.

### 4. User Opens the Capture URL

Tell the user to open:

```
http://localhost:8765/ux-audit-report.html#figmacapture&figmadelay=2000
```

The `#figmacapture` hash triggers the Figma capture snippet. The `figmadelay=2000` gives the page 2 seconds to fully render before capture.

Alternatively, add the capture script tag to the HTML:
```html
<script src="https://mcp.figma.com/mcp/html-to-design/capture.js" async></script>
```

The user should see a Figma capture toast/overlay appear in their browser.

### 5. Poll for Completion

Once the user confirms the capture toast appeared, call:

```
mcp__figma__generate_figma_design({
  captureId: "the-capture-id-from-step-2"
})
```

This polls until the capture completes and returns the Figma file URL.

### 6. Stop the Server

```bash
kill $(lsof -ti:8765)
```

## Error Handling

- **Plugin not connected**: The user needs the html.to.design Figma plugin active. Guide them to install it from the Figma Community.
- **Capture timeout**: If polling times out, the page may be too large. Try reducing content or increasing `figmadelay`.
- **Permission error**: The user must have edit access to the target Figma file.

## Token JSON Import (Separate Step)

DTCG token JSON files (`light.tokens.json`, `dark.tokens.json`) cannot be pushed via the MCP tool. They must be imported manually:

1. Open the target Figma file
2. Go to **Local Variables** panel
3. Click the **Import** button
4. Select the token JSON files
5. Choose "Create new collection" or merge into existing

See [dtcg-format.md](dtcg-format.md) for the token file format.
