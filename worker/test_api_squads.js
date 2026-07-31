const http = require('https');

http.get('https://academypro-api.tata-elash34.workers.dev/api/squads', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', JSON.stringify(JSON.parse(data), null, 2));
  });
}).on('error', console.error);
