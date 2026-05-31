const http = require('http');
const tests = [
  { requestId: 'estat-domain-pop', userText: '日本の人口統計を教えて' },
  { requestId: 'estat-domain-pref', userText: '都道府県別の人口を見せて' },
  { requestId: 'estat-domain-cpi', userText: '東京の最新CPIを教えて' }
];
async function runTests() {
  for (const test of tests) {
    const data = JSON.stringify({ domainId: 'e-stat_mcp', requestId: test.requestId, userText: test.userText });
    const options = { hostname: '127.0.0.1', port: 4001, path: '/api/intercept', method: 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } };
    await new Promise((resolve) => {
      const req = http.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => body += chunk);
        res.on('end', () => {
          try {
            const resp = JSON.parse(body);
            const meta = resp.metadata || {};
            let out = 'requestId: ' + test.requestId + ', mcpUsed: ' + meta.mcpUsed + ', mcpToolName: ' + (meta.mcpToolName || 'undefined') + ', mcpErrorCode: ' + (meta.mcpErrorCode || 'undefined');
            if (resp.injectedSystemPrompt) {
              const p = resp.injectedSystemPrompt;
              const match = p.match(/\"selectedTable\":\s*({[^{}]+})/);
              if (match) {
                 try {
                   const table = JSON.parse(match[1]);
                   out += ', selectedTableName: ' + table.name + ', selectedTableId: ' + table.id;
                 } catch(e) {}
              }
            }
            console.log(out);
          } catch (e) { console.error('Error: ' + e.message); }
          resolve();
        });
      });
      req.on('error', (e) => { console.error('Req Error: ' + e.message); resolve(); });
      req.write(data);
      req.end();
    });
  }
}
runTests();
