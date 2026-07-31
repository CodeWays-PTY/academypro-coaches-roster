const http = require('https');

function get(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

async function run() {
  try {
    console.log('Testing /api/rosters/All ...');
    const all = await get('https://academypro-api.tata-elash34.workers.dev/api/rosters/All');
    console.log('All Players count:', all.data?.players?.length);
    console.log('All Players names:', all.data?.players?.map(p => `${p.firstName} ${p.lastName} (${p.team || p.ageGroup})`));

    console.log('\nTesting /api/rosters/First%20Team ...');
    const ft = await get('https://academypro-api.tata-elash34.workers.dev/api/rosters/First%20Team');
    console.log('First Team Players count:', ft.data?.players?.length);
    console.log('First Team Players names:', ft.data?.players?.map(p => `${p.firstName} ${p.lastName} (${p.team || p.ageGroup})`));

    console.log('\nTesting /api/rosters/U15%20Squad ...');
    const u15 = await get('https://academypro-api.tata-elash34.workers.dev/api/rosters/U15%20Squad');
    console.log('U15 Squad Players count:', u15.data?.players?.length);
    console.log('U15 Squad Players names:', u15.data?.players?.map(p => `${p.firstName} ${p.lastName} (${p.team || p.ageGroup})`));
  } catch (e) {
    console.error(e);
  }
}

run();
