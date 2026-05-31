const http = require('http');

const prompts = [
  { id: 'req1', prompt: '日本の人口統計を教えて' },
  { id: 'req2', prompt: '都道府県別の人口を見せて' },
  { id: 'req3', prompt: '東京の最新CPIを教えて' }
];

async function sendRequest(item) {
  const data = JSON.stringify({
    requestId: item.id,
    prompt: item.prompt
  });

  const options = {
    hostname: 'localhost',
    port: 4001,
    path: '/api/intercept',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data)
    }
  };

  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => { responseBody += chunk; });
      res.on('end', () => {
        try {
          const json = JSON.parse(responseBody);
          const mcpUsed = json.metadata?.mcpUsed;
          const mcpTool = json.metadata?.mcpToolName;
          let tableName = 'N/A';
          if (json.injectedSystemPrompt) {
             try {
                const match = json.injectedSystemPrompt.match(/\{[\s\S]*\}/);
                if (match) {
                  const systemPromptJson = JSON.parse(match[0]);
                  tableName = (systemPromptJson.selectedTable && (systemPromptJson.selectedTable.name || systemPromptJson.selectedTable.id)) || 'N/A';
                }
             } catch(e) {}
          }
          process.stdout.write('Prompt: ' + item.prompt + '\n');
          process.stdout.write('mcpUsed: ' + mcpUsed + '\n');
          process.stdout.write('mcpToolName: ' + mcpTool + '\n');
          process.stdout.write('tableName: ' + tableName + '\n');
          process.stdout.write('---\n');
          resolve();
        } catch (e) {
          process.stdout.write('Error parsing response for ' + item.prompt + ': ' + e.message + '\n');
          process.stdout.write('Response body: ' + responseBody + '\n');
          resolve();
        }
      });
    });

    req.on('error', (error) => {
      process.stderr.write('Error sending request: ' + error.message + '\n');
      resolve();
    });

    req.write(data);
    req.end();
  });
}

async function run() {
  for (const item of prompts) {
    await sendRequest(item);
  }
}

run();
