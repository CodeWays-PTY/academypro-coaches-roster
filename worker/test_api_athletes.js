const http = require('https');

http.get('https://academypro-api.tata-elash34.workers.dev/api/athletes', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', data);
  });
}).on('error', console.error);
