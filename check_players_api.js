async function check() {
  const res = await fetch('https://academypro-api.tata-elash34.workers.dev/api/athletes');
  const data = await res.json();
  console.log('Athletes count:', data.data ? data.data.length : 0);
  console.log('Athletes:', JSON.stringify(data.data, null, 2));

  const squadsRes = await fetch('https://academypro-api.tata-elash34.workers.dev/api/squads');
  const squadsData = await squadsRes.json();
  console.log('Squads:', JSON.stringify(squadsData.data, null, 2));
}

check().catch(console.error);
