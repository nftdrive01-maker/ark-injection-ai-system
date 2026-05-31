$body = '{"userText": "物件は全部で何件ありますか？", "domainId": "db-mcp", "sessionId": "debug-amica-bff-count", "requestId": "debug-amica-bff-count"}'
$sw = [system.diagnostics.stopwatch]::StartNew()
try {
    $res = curl.exe -s -X POST "http://localhost:3000/api/injection/intercept/" -H "Content-Type: application/json" -d $body
    $sw.Stop()
    $elapsed = $sw.Elapsed.TotalSeconds
    if ($res) {
        $json = $res | ConvertFrom-Json
        $mcpToolName = if ($null -ne $json.metadata.mcpToolName) { "True" } else { "False" }
        $mcpUsed = if ($null -ne $json.metadata.mcpUsed) { "True" } else { "False" }
        $totalCount = if ($null -ne $json.injectedSystemPrompt -and $json.injectedSystemPrompt.Contains("total_count 2000")) { "True" } else { "False" }
        "ELAPSED: $elapsed"
        "MCP_TOOL_NAME: $mcpToolName"
        "MCP_USED: $mcpUsed"
        "TOTAL_COUNT: $totalCount"
    } else {
        "REQUEST_FAILED_OR_EMPTY"
    }
} catch {
    "ERROR: $($_.Exception.Message)"
}
