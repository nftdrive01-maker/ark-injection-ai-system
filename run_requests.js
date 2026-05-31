const prompts = [
  { requestId: 'estat-rank-pop', userPrompt: '日本の人口統計を教えて' },
  { requestId: 'estat-rank-pref', userPrompt: '都道府県別の人口を見せて' },
  { requestId: 'estat-rank-cpi', userPrompt: '東京の最新CPIを教えて' }
];

async function run() {
  for (const p of prompts) {
    try {
      const resp = await fetch('http://localhost:4001/api/intercept', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(p)
      });
      const data = await resp.json();
      
      let tableInfo = 'N/A';
      if (data.injectedSystemPrompt) {
        const match = data.injectedSystemPrompt.match(/```json\n([\s\S]*?)\n```/);
        if (match) {
          try {
            const json = JSON.parse(match[1]);
            if (json.selectedTable) {
              tableInfo = 'Name: ' + json.selectedTable.name + ', ID: ' + json.selectedTable.id;
            }
          } catch(e) {}
        }
      }

      console.log('RequestId: ' + p.requestId);
      console.log('MCP Used: ' + (data.metadata ? data.metadata.mcpUsed : 'undefined'));
      console.log('Tool Name: ' + (data.metadata ? data.metadata.mcpToolName : 'undefined'));
      console.log('e-Stat Table: ' + tableInfo);
      console.log('---');
    } catch (err) {
      console.error('Error for ' + p.requestId + ': ' + err.message);
    }
  }
}
run();
