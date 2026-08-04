const rawData = `Immanuel Engelbrecht	Manieengelbrecht35@gmail.com	082 438 1998
Sello Jantie	Nthabyjankie@gmail.com	083 495 2406
Wikus De Koker	Wikusdekoker12@gmail.com	067 787 5916
Phatu Motlhabane	Phatumotlhabane@gmail.com	-
Shayaan Rafiq	@icloud.com	084 208 9276
Alexander Coetzer	-	069 656 9306
Achuma Bibi	achumabibi5@gmail.com	635279367
Taylon Cartwright	taylonbradleycartwright@gmail.com	075 028 7075
Bokang Maphosa	-	079 901 5552
Kyle Smith	-	083 387 9023
Simphiwe Philemon	-	082 644 7842
Khumo Kutumela	Khumokutumela77@gmail.com	066 543 1954
Luvani Nkwinika	Nkwinikaluvani21@gmail.com	061 083 5809
Liam Maré	Liammare2011@gmail.com	079 402 5703
Kody Langeveldt	elkody@icloud.com	-
Theodore Mosia	theo67mosia@gmail.com	068 569 5251
Shelton Julies	-	066 491 3739
Luyanda Nzotho	luyandanzotho51@gmail.com	069 889 4923
Siphosihle Masemola	Siphosihlemasemola69@gmail.com	704029838`;

const apiBase = 'https://academypro-api.tata-elash34.workers.dev';
const squadId = 'sq-1785841532380';
const squadName = 'U15';

async function run() {
  const lines = rawData.trim().split('\n');
  console.log(`Posting ${lines.length} athletes via HTTP API to ${apiBase}...`);

  for (let i = 0; i < lines.length; i++) {
    const parts = lines[i].split('\t').map(s => s.trim());
    const fullName = parts[0];
    let email = parts[1];
    let phone = parts[2];

    const nameParts = fullName.split(' ');
    const firstName = nameParts[0];
    const lastName = nameParts.slice(1).join(' ') || '';

    if (!email || email === '-' || email === '@icloud.com' || !email.includes('@') || email.startsWith('@')) {
      const slug = fullName.toLowerCase().replace(/[^a-z0-9]/g, '.');
      email = `${slug}@dummy.academypro.co.za`;
    }

    if (phone === '-' || !phone) {
      phone = null;
    } else if (!phone.startsWith('0') && !phone.startsWith('+')) {
      phone = '0' + phone;
    }

    const payload = {
      firstName,
      lastName,
      name: fullName,
      email,
      phone,
      team: squadName,
      ageGroup: squadName,
      position: 'Athlete',
      schoolId: '1'
    };

    try {
      // 1. Post Athlete via HTTP API
      const res = await fetch(`${apiBase}/api/athletes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      const athleteId = data?.data?.id || data?.id || `plr_u15_${String(i+1).padStart(3, '0')}`;
      console.log(`[${i+1}/${lines.length}] Athlete Posted: ${fullName} (ID: ${athleteId}) -> ${res.status}`);

      // 2. Post Squad Membership via HTTP API
      const memRes = await fetch(`${apiBase}/api/squads/members`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ squadId, squadName, athleteId, playerId: athleteId })
      });
      const memData = await memRes.json();
      console.log(`   Squad Member Added: ${memRes.status} -> ${JSON.stringify(memData)}`);

    } catch (e) {
      console.error(`Error posting ${fullName}:`, e.message);
    }
  }

  console.log('\nFinished posting all 19 athletes via HTTP API!');
}

run();
