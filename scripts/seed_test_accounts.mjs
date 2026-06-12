// VoiceLingo — Test hesabı seed script'i.
//
// 3 test hesabı oluşturur ve N gün boyunca "eksiksiz kullanım" simüle eder:
//   test20@voicelingo.dev → 20 gün   test60 → 60 gün   test80 → 80 gün
//
// Tüm yazımlar hesabın KENDİ oturumuyla yapılır (anon key + password grant),
// yani RLS politikalarının izin verdiğinden fazlası yazılamaz. Service-role
// gerekmez. Tekrar çalıştırmak güvenlidir: önce kullanıcının seed edilebilir
// satırları silinir (user_badges hariç — orada ignore-duplicates upsert).
//
// Kullanım:  node scripts/seed_test_accounts.mjs

import { readFileSync } from 'fs';

const env = Object.fromEntries(
  readFileSync(new URL('../.env', import.meta.url), 'utf8')
    .split('\n').filter(l => l.includes('='))
    .map(l => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()]),
);
const SUPABASE_URL = env.SUPABASE_URL;
const ANON_KEY = env.SUPABASE_ANON_KEY;
const PASSWORD = 'Test1234!';

const ACCOUNTS = [
  { email: 'test20@voicelingo.dev', username: 'test20', days: 20, cefr: 'A2', goal: 10, motivation: 'travel', character: 'lily', freezes: 1 },
  { email: 'test60@voicelingo.dev', username: 'test60', days: 60, cefr: 'B1', goal: 20, motivation: 'work', character: 'sarah', freezes: 2 },
  { email: 'test80@voicelingo.dev', username: 'test80', days: 80, cefr: 'B1', goal: 30, motivation: 'exam', character: 'kai', freezes: 2 },
];

// Migration 20260518000001'deki rozet XP ödülleri (xp toplamı için).
const BADGE_XP = {
  streak_3: 50, streak_7: 100, streak_30: 500, streak_100: 2000,
  words_10: 30, words_50: 150, words_100: 300, words_500: 1500,
  talk_10: 30, talk_100: 200, talk_500: 1000,
  perfect_5: 100, early_bird: 50, night_owl: 50, scenarios_5: 150,
};

// ---------------------------------------------------------------------------
// Kelime havuzu (en|tr) — A1-B1 sık kullanılan kelimeler.
const WORD_POOL = `
apple|elma, house|ev, water|su, book|kitap, friend|arkadaş, school|okul, teacher|öğretmen,
family|aile, mother|anne, father|baba, brother|erkek kardeş, sister|kız kardeş, child|çocuk,
morning|sabah, evening|akşam, night|gece, today|bugün, tomorrow|yarın, yesterday|dün,
breakfast|kahvaltı, lunch|öğle yemeği, dinner|akşam yemeği, bread|ekmek, milk|süt, cheese|peynir,
coffee|kahve, tea|çay, sugar|şeker, salt|tuz, egg|yumurta, meat|et, chicken|tavuk, fish|balık,
fruit|meyve, vegetable|sebze, orange|portakal, banana|muz, grape|üzüm, strawberry|çilek,
city|şehir, village|köy, street|sokak, road|yol, bridge|köprü, building|bina, garden|bahçe,
kitchen|mutfak, bedroom|yatak odası, bathroom|banyo, window|pencere, door|kapı, table|masa,
chair|sandalye, bed|yatak, lamp|lamba, mirror|ayna, clock|saat, phone|telefon, computer|bilgisayar,
weather|hava durumu, rain|yağmur, snow|kar, wind|rüzgar, sun|güneş, cloud|bulut, storm|fırtına,
hot|sıcak, cold|soğuk, warm|ılık, cool|serin, dry|kuru, wet|ıslak, sunny|güneşli, cloudy|bulutlu,
happy|mutlu, sad|üzgün, angry|kızgın, tired|yorgun, hungry|aç, thirsty|susamış, scared|korkmuş,
excited|heyecanlı, bored|sıkılmış, surprised|şaşırmış, worried|endişeli, calm|sakin, proud|gururlu,
big|büyük, small|küçük, tall|uzun, short|kısa, long|uzun (mesafe), wide|geniş, narrow|dar,
fast|hızlı, slow|yavaş, early|erken, late|geç, new|yeni, old|eski, young|genç, beautiful|güzel,
ugly|çirkin, clean|temiz, dirty|kirli, easy|kolay, difficult|zor, cheap|ucuz, expensive|pahalı,
rich|zengin, poor|fakir, strong|güçlü, weak|zayıf, heavy|ağır, light|hafif, full|dolu, empty|boş,
run|koşmak, walk|yürümek, jump|zıplamak, swim|yüzmek, fly|uçmak, drive|araba sürmek, ride|binmek,
eat|yemek, drink|içmek, cook|pişirmek, bake|fırında pişirmek, cut|kesmek, wash|yıkamak,
read|okumak, write|yazmak, speak|konuşmak, listen|dinlemek, watch|izlemek, look|bakmak,
see|görmek, hear|duymak, smell|koklamak, taste|tatmak, touch|dokunmak, feel|hissetmek,
think|düşünmek, know|bilmek, learn|öğrenmek, teach|öğretmek, study|ders çalışmak, remember|hatırlamak,
forget|unutmak, understand|anlamak, believe|inanmak, hope|ummak, wish|dilemek, dream|hayal etmek,
work|çalışmak, play|oynamak, rest|dinlenmek, sleep|uyumak, wake|uyanmak, start|başlamak,
finish|bitirmek, stop|durmak, continue|devam etmek, open|açmak, close|kapatmak, push|itmek,
pull|çekmek, carry|taşımak, bring|getirmek, take|almak, give|vermek, send|göndermek,
receive|almak (teslim), buy|satın almak, sell|satmak, pay|ödemek, cost|mal olmak, spend|harcamak,
save|biriktirmek, borrow|ödünç almak, lend|ödünç vermek, choose|seçmek, decide|karar vermek,
travel|seyahat etmek, visit|ziyaret etmek, arrive|varmak, leave|ayrılmak, return|geri dönmek,
stay|kalmak, move|taşınmak, change|değiştirmek, grow|büyümek, build|inşa etmek, break|kırmak,
fix|tamir etmek, repair|onarmak, create|yaratmak, draw|çizmek, paint|boyamak, sing|şarkı söylemek,
dance|dans etmek, laugh|gülmek, cry|ağlamak, smile|gülümsemek, shout|bağırmak, whisper|fısıldamak,
ask|sormak, answer|cevaplamak, explain|açıklamak, describe|tanımlamak, suggest|önermek,
agree|katılmak, disagree|katılmamak, argue|tartışmak, discuss|müzakere etmek, promise|söz vermek,
invite|davet etmek, meet|buluşmak, introduce|tanıştırmak, greet|selamlamak, welcome|karşılamak,
airport|havalimanı, station|istasyon, ticket|bilet, luggage|bagaj, passport|pasaport,
journey|yolculuk, holiday|tatil, hotel|otel, reservation|rezervasyon, reception|resepsiyon,
restaurant|restoran, menu|menü, waiter|garson, bill|hesap, order|sipariş, tip|bahşiş,
hospital|hastane, doctor|doktor, nurse|hemşire, medicine|ilaç, pain|ağrı, fever|ateş,
headache|baş ağrısı, cough|öksürük, healthy|sağlıklı, sick|hasta, appointment|randevu,
market|pazar, shop|dükkan, price|fiyat, discount|indirim, customer|müşteri, cash|nakit,
wallet|cüzdan, pocket|cep, size|beden, color|renk, dress|elbise, shirt|gömlek, trousers|pantolon,
shoes|ayakkabı, jacket|ceket, coat|palto, hat|şapka, glove|eldiven, scarf|atkı, umbrella|şemsiye,
job|iş, office|ofis, meeting|toplantı, salary|maaş, boss|patron, colleague|iş arkadaşı,
interview|mülakat, experience|deneyim, skill|beceri, career|kariyer, company|şirket, project|proje,
news|haber, newspaper|gazete, magazine|dergi, story|hikaye, history|tarih, language|dil,
word|kelime, sentence|cümle, question|soru, problem|sorun, solution|çözüm, idea|fikir,
reason|sebep, result|sonuç, example|örnek, mistake|hata, success|başarı, failure|başarısızlık,
future|gelecek, past|geçmiş, present|şimdiki zaman, moment|an, century|yüzyıl, weekend|hafta sonu,
nature|doğa, forest|orman, mountain|dağ, river|nehir, lake|göl, sea|deniz, beach|plaj,
island|ada, desert|çöl, animal|hayvan, bird|kuş, horse|at, sheep|koyun, butterfly|kelebek,
music|müzik, song|şarkı, movie|film, theatre|tiyatro, painting|tablo, photograph|fotoğraf,
hobby|hobi, sport|spor, football|futbol, basketball|basketbol, tennis|tenis, race|yarış,
team|takım, player|oyuncu, winner|kazanan, prize|ödül, game|oyun, score|skor, goal|hedef,
freedom|özgürlük, peace|barış, war|savaş, law|kanun, government|hükümet, citizen|vatandaş,
environment|çevre, pollution|kirlilik, energy|enerji, electricity|elektrik, technology|teknoloji,
science|bilim, research|araştırma, knowledge|bilgi, education|eğitim, university|üniversite,
student|öğrenci, lesson|ders, exam|sınav, homework|ödev, library|kütüphane, dictionary|sözlük
`.split(/[,\n]/).map(s => s.trim()).filter(Boolean).map(s => {
  const [word, translation] = s.split('|');
  return { word: word.trim(), translation: (translation ?? '').trim() };
});

// ---------------------------------------------------------------------------
// Konuşma şablonları — gerçekçi geçmiş sohbetler.
const ERROR_TYPES = ['article usage', 'past tense', 'preposition', 'subject-verb agreement', 'word order', 'plural form', 'verb tense', 'vocabulary choice'];

const DIALOGUES = [
  { title: 'Ordering coffee', msgs: [
    ['a', "Hi there! Welcome to Bean Street. What can I get you today?"],
    ['u', 'Hi! I would like a large cappuccino, please.', 92],
    ['a', 'Great choice! Would you like anything to eat with that?'],
    ['u', 'Yes, I take a croissant too.', 76, "Yes, I'll take a croissant too.", 'Use the future form for spontaneous decisions.', ['verb tense']],
    ['a', "Perfect, one large cappuccino and a croissant. For here or to go?"],
    ['u', 'To go, please. How much is it?', 95],
    ['a', "That'll be 8.50. Cash or card?"],
    ['u', 'Card, please. Thank you very much!', 98],
  ]},
  { title: 'At the airport', msgs: [
    ['a', 'Good morning! May I see your passport and boarding pass, please?'],
    ['u', 'Of course, here you are. I am flying to London today.', 94],
    ['a', 'Thank you. Are you checking any bags today?'],
    ['u', 'Yes, I have one suitcase and one hand luggage.', 88, 'Yes, I have one suitcase and one piece of hand luggage.', "'Luggage' is uncountable; use 'a piece of'.", ['plural form']],
    ['a', 'Your suitcase is within the limit. Here is your baggage tag.'],
    ['u', 'Great. Which gate do I need to go?', 80, 'Which gate do I need to go to?', "The verb 'go' needs the preposition 'to' here.", ['preposition']],
    ['a', 'Gate B12. Boarding starts at 10:30. Have a nice flight!'],
    ['u', 'Thank you for your help. Have a nice day!', 97],
  ]},
  { title: 'Job interview practice', msgs: [
    ['a', "Thanks for coming in today. Can you tell me a little about yourself?"],
    ['u', 'Sure! I have worked in marketing for three years and I love creative projects.', 95],
    ['a', 'Impressive. What would you say is your biggest strength?'],
    ['u', 'I am very organized and I always finish my works on time.', 79, 'I always finish my work on time.', "'Work' is uncountable in this meaning.", ['plural form']],
    ['a', 'Good to hear. Why do you want to join our company?'],
    ['u', 'Because your company has a great culture and I want to grow my career here.', 93],
    ['a', 'Where do you see yourself in five years?'],
    ['u', 'I hope I will lead a small team and manage important projects.', 91],
  ]},
  { title: 'Dinner reservation', msgs: [
    ['a', 'Good evening, La Tavola restaurant. How can I help you?'],
    ['u', 'Hello! I would like to book a table for two people for Saturday evening.', 96],
    ['a', 'Certainly. What time would you prefer?'],
    ['u', 'Around eight clock, if it is possible.', 74, "Around eight o'clock, if possible.", "Say 'eight o'clock'; 'if possible' is more natural.", ['vocabulary choice', 'word order']],
    ['a', 'Eight o\'clock on Saturday for two. May I have your name, please?'],
    ['u', 'Yes, my name is Deniz. D-E-N-I-Z.', 99],
    ['a', 'Perfect, Deniz. Your table is booked. See you on Saturday!'],
    ['u', 'Thank you so much. See you then!', 98],
  ]},
  { title: 'Talking about the weekend', msgs: [
    ['a', "Hey! How was your weekend? Did you do anything fun?"],
    ['u', 'It was great! I went to the beach with my friends on Saturday.', 95],
    ['a', 'That sounds lovely! How was the weather?'],
    ['u', 'The weather was perfect, very sunny and warm. We swimmed for hours.', 77, 'We swam for hours.', "'Swim' has the irregular past form 'swam'.", ['past tense']],
    ['a', "Nice! Did you eat anything special there?"],
    ['u', 'Yes, we had grilled fish at a small restaurant near the sea.', 94],
    ['a', 'Now I am hungry! Would you go again next weekend?'],
    ['u', 'Definitely! Maybe you can join us next time.', 96],
  ]},
  { title: "At the doctor's office", msgs: [
    ['a', 'Good morning. What seems to be the problem today?'],
    ['u', 'Good morning, doctor. I have a headache and a sore throat since two days.', 75, 'I have had a headache and a sore throat for two days.', "Use present perfect with 'for' for duration.", ['verb tense', 'preposition']],
    ['a', 'I see. Do you have a fever as well?'],
    ['u', 'Yes, I had a small fever last night, around 38 degrees.', 89],
    ['a', 'Let me check your throat. It looks a bit red. It is probably a mild infection.'],
    ['u', 'Is it serious? Do I need any medicine?', 93],
    ['a', "Nothing serious. I'll prescribe a painkiller and you should rest for a few days."],
    ['u', 'Thank you, doctor. I will follow your advice.', 97],
  ]},
  { title: 'Buying clothes', msgs: [
    ['a', 'Hello! Welcome to our store. Are you looking for anything special?'],
    ['u', 'Hi! I am looking for a jacket for the winter.', 94],
    ['a', 'We have some great options. What size do you wear?'],
    ['u', 'I usually wear medium, but it depends of the brand.', 78, 'It depends on the brand.', "'Depend' takes the preposition 'on'.", ['preposition']],
    ['a', 'Here is a medium in dark blue. The fitting room is over there.'],
    ['u', 'This fits perfectly. How much does it cost?', 95],
    ['a', "It's 89.90, and today we have a 20 percent discount."],
    ['u', "Great, I'll take it! Can I pay by card?", 98],
  ]},
  { title: 'Hotel check-in', msgs: [
    ['a', 'Good afternoon! Welcome to the Grand Plaza. Do you have a reservation?'],
    ['u', 'Good afternoon. Yes, I booked a double room for three nights.', 96],
    ['a', 'May I have your name and ID, please?'],
    ['u', 'Here you are. Is the breakfast include in the price?', 73, 'Is breakfast included in the price?', "Use the passive 'included'; no article before 'breakfast'.", ['verb tense', 'article usage']],
    ['a', 'Yes, breakfast is included, served from 7 to 10 in the restaurant.'],
    ['u', 'Perfect. What time is the check-out?', 92],
    ['a', 'Check-out is at noon. Here is your key card, room 504.'],
    ['u', 'Thank you very much. Have a good day!', 98],
  ]},
];

// ---------------------------------------------------------------------------
// Yardımcılar

// Deterministik RNG — aynı hesap için tekrar çalıştırma aynı veriyi üretir.
function mulberry32(seed) {
  return function () {
    seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const todayLocal = new Date();
todayLocal.setHours(0, 0, 0, 0);

function dayAt(daysAgo, hour, minute = 0, second = 0) {
  const d = new Date(todayLocal);
  d.setDate(d.getDate() - daysAgo);
  d.setHours(hour, minute, second, 0);
  return d;
}

function dateStr(d) {
  const y = d.getFullYear(), m = String(d.getMonth() + 1).padStart(2, '0'), g = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${g}`;
}

async function rest(token, path, { method = 'GET', body, prefer } = {}) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method,
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(prefer ? { Prefer: prefer } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status}: ${await res.text()}`);
  const text = await res.text();
  return text ? JSON.parse(text) : null;
}

async function authPost(path, body) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/${path}`, {
    method: 'POST',
    headers: { apikey: ANON_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { ok: res.ok, status: res.status, json: await res.json() };
}

async function signUpOrIn(email, password) {
  const signup = await authPost('signup', { email, password });
  if (signup.ok && signup.json.access_token) {
    return { token: signup.json.access_token, uid: signup.json.user.id, created: true };
  }
  // Zaten kayıtlıysa (veya signup session dönmediyse) password grant dene.
  const signin = await authPost('token?grant_type=password', { email, password });
  if (signin.ok && signin.json.access_token) {
    return { token: signin.json.access_token, uid: signin.json.user.id, created: false };
  }
  throw new Error(`Auth failed for ${email}: signup=${JSON.stringify(signup.json)} signin=${JSON.stringify(signin.json)}`);
}

// ---------------------------------------------------------------------------
// Hesap başına seed

async function seedAccount(acc) {
  const rnd = mulberry32(acc.days * 7919 + 13);
  const pick = (arr) => arr[Math.floor(rnd() * arr.length)];
  const ri = (lo, hi) => lo + Math.floor(rnd() * (hi - lo + 1));

  console.log(`\n=== ${acc.email} (${acc.days} gün) ===`);
  const { token, uid, created } = await signUpOrIn(acc.email, PASSWORD);
  console.log(`  auth ok (uid=${uid}, ${created ? 'yeni kayıt' : 'mevcut hesap'})`);

  // --- Önceki seed'i temizle (idempotent re-run) ---
  for (const t of ['practice_sessions', 'words', 'conversations', 'daily_quests',
    'user_lesson_progress', 'user_grammar_progress', 'user_scenario_progress']) {
    await rest(token, `${t}?user_id=eq.${uid}`, { method: 'DELETE' });
  }

  const N = acc.days; // bugün dahil N gün: daysAgo = N-1 .. 0

  // --- practice_sessions ---
  const sessions = [];
  let sessionsXp = 0;
  for (let ago = N - 1; ago >= 0; ago--) {
    // Sabah bloğu (bazı günler) — early_bird gerçekçiliği
    if (rnd() < 0.4) {
      const turns = ri(2, 4);
      for (let t = 0; t < turns; t++) {
        sessions.push({ mode: 'conversation', words: 0, score: 5.0, xp: 5, at: dayAt(ago, 7, 30 + t * 2, ri(0, 50)) });
      }
    }
    // Akşam konuşma turları
    const evening = ri(5, 10);
    const eh = ri(18, 21);
    for (let t = 0; t < evening; t++) {
      sessions.push({ mode: 'conversation', words: 0, score: 5.0, xp: 5, at: dayAt(ago, eh, 10 + t * 3, ri(0, 50)) });
    }
    // Kelime tekrar oturumları
    const reviews = ri(1, 2);
    for (let t = 0; t < reviews; t++) {
      const w = ri(8, 18);
      sessions.push({
        mode: 'word_review_batch', words: w,
        score: Math.round((3.2 + rnd() * 1.8) * 10) / 10,
        xp: ri(12, 28), at: dayAt(ago, t === 0 ? 12 : 20, ri(5, 50), ri(0, 50)),
      });
    }
  }
  sessionsXp = sessions.reduce((a, s) => a + s.xp, 0);
  await rest(token, 'practice_sessions', {
    method: 'POST', prefer: 'return=minimal',
    body: sessions.map(s => ({
      user_id: uid, mode: s.mode, words_practiced: s.words, avg_score: s.score,
      xp_earned: s.xp, created_at: s.at.toISOString(), ended_at: s.at.toISOString(),
    })),
  });
  console.log(`  practice_sessions: ${sessions.length} satır (${sessionsXp} XP)`);

  // --- words ---
  const wordCount = Math.min(Math.round(40 + N * 2.5), WORD_POOL.length);
  const masteredCount = Math.round(wordCount * 0.6);
  const words = [];
  for (let i = 0; i < wordCount; i++) {
    const ago = Math.max(0, N - 1 - Math.floor((i * N) / wordCount));
    const mastered = i < masteredCount;
    const interval = mastered ? ri(6, 30) : ri(1, 3);
    const nextReview = new Date(todayLocal);
    nextReview.setDate(nextReview.getDate() + (mastered ? ri(0, interval) : ri(-2, 1)));
    words.push({
      user_id: uid,
      word: WORD_POOL[i].word,
      translation: WORD_POOL[i].translation,
      ease_factor: Math.round((2.2 + rnd() * 0.6) * 100) / 100,
      interval_days: interval,
      repetitions: mastered ? ri(3, 7) : ri(0, 2),
      next_review: dateStr(nextReview),
      created_at: dayAt(ago, ri(9, 22), ri(0, 59)).toISOString(),
    });
  }
  await rest(token, 'words', { method: 'POST', prefer: 'return=minimal', body: words });
  console.log(`  words: ${wordCount} kelime (${masteredCount} mastered)`);

  // --- içerik tabloları (salt-okunur) ---
  const [badges, scenarios, topics, units, lessons] = await Promise.all([
    rest(token, 'badges?select=id,code'),
    rest(token, 'scenarios?select=id,objectives&is_public=eq.true&order=created_at.asc&limit=12'),
    rest(token, 'grammar_topics?select=id,xp_reward,level,order_index&order=level.asc,order_index.asc'),
    rest(token, 'units?select=id,order_index&order=order_index.asc').catch(() => null),
    rest(token, 'lessons?select=id,unit_id,order_index,xp_reward'),
  ]);

  // --- conversations + messages ---
  const convCount = Math.min(4 + Math.floor(N / 4), 20);
  const characters = ['lily', 'james', 'sarah', 'kai', 'maya', 'omar'];
  const convRows = [];
  const convMeta = [];
  for (let j = 0; j < convCount; j++) {
    const ago = Math.max(0, N - 1 - Math.floor((j * N) / convCount));
    const dlg = DIALOGUES[j % DIALOGUES.length];
    const startAt = dayAt(ago, ri(18, 21), ri(0, 40));
    const endAt = new Date(startAt.getTime() + dlg.msgs.length * 45000);
    convRows.push({
      user_id: uid,
      title: dlg.title,
      scenario: j % 3 === 0 && scenarios.length > 0 ? pick(scenarios).id : null,
      character_id: j === convCount - 1 ? acc.character : pick(characters),
      created_at: startAt.toISOString(),
      updated_at: endAt.toISOString(),
    });
    convMeta.push({ dlg, startAt });
  }
  const inserted = await rest(token, 'conversations', {
    method: 'POST', prefer: 'return=representation', body: convRows,
  });
  const msgRows = [];
  inserted.forEach((conv, j) => {
    const { dlg, startAt } = convMeta[j];
    dlg.msgs.forEach((m, k) => {
      const [role, content, score, suggestion, explanation, errors] = m;
      msgRows.push({
        conversation_id: conv.id,
        user_id: uid,
        role: role === 'u' ? 'user' : 'assistant',
        content,
        eval_score: role === 'u' ? (score ?? ri(80, 98)) : null,
        eval_suggestion: suggestion ?? null,
        eval_explanation: explanation ?? null,
        grammar_errors: role === 'u'
            ? (errors ?? (rnd() < 0.2 ? [pick(ERROR_TYPES)] : []))
            : null,
        created_at: new Date(startAt.getTime() + k * 45000).toISOString(),
      });
    });
  });
  await rest(token, 'messages', { method: 'POST', prefer: 'return=minimal', body: msgRows });
  console.log(`  conversations: ${convCount}, messages: ${msgRows.length}`);

  // --- user_lesson_progress ---
  let lessonXp = 0;
  if (lessons?.length) {
    const unitOrder = new Map((units ?? []).map(u => [u.id, u.order_index]));
    const sorted = [...lessons].sort((a, b) =>
      (unitOrder.get(a.unit_id) ?? 0) - (unitOrder.get(b.unit_id) ?? 0) || a.order_index - b.order_index);
    const K = Math.min(Math.round(N * 0.7), sorted.length);
    const rows = [];
    for (let i = 0; i < K; i++) {
      const ago = Math.max(0, N - 1 - Math.floor((i * N) / K));
      const masteredL = i < Math.floor(K * 0.7);
      const at = dayAt(ago, ri(17, 21), ri(0, 59));
      const reviewAt = new Date(at.getTime() + 7 * 86400000);
      rows.push({
        user_id: uid, lesson_id: sorted[i].id,
        status: masteredL ? 'mastered' : 'completed',
        stars: masteredL ? 3 : ri(2, 3),
        best_score: masteredL ? ri(92, 100) : ri(75, 91),
        attempts: ri(1, 3),
        last_attempt_at: at.toISOString(),
        next_review_at: masteredL ? null : reviewAt.toISOString(),
        updated_at: at.toISOString(),
      });
      lessonXp += sorted[i].xp_reward ?? 20;
    }
    await rest(token, 'user_lesson_progress', { method: 'POST', prefer: 'return=minimal', body: rows });
    console.log(`  lessons: ${K}/${sorted.length} tamamlandı`);
  }

  // --- user_grammar_progress ---
  let grammarXp = 0;
  if (topics?.length) {
    const K = Math.min(Math.round(N / 4) + 2, topics.length);
    const rows = [];
    for (let i = 0; i < K; i++) {
      const ago = Math.max(0, N - 1 - Math.floor((i * N) / K));
      const masteredG = rnd() < 0.5;
      const score = masteredG ? ri(95, 100) : ri(72, 94);
      const at = dayAt(ago, ri(16, 22), ri(0, 59));
      rows.push({
        user_id: uid, topic_id: topics[i].id,
        status: masteredG ? 'mastered' : 'completed',
        quiz_score: score, attempts: ri(1, 3),
        completed_at: at.toISOString(), updated_at: at.toISOString(),
      });
      grammarXp += topics[i].xp_reward ?? 30;
    }
    await rest(token, 'user_grammar_progress', { method: 'POST', prefer: 'return=minimal', body: rows });
    console.log(`  grammar: ${K}/${topics.length} konu tamamlandı`);
  }

  // --- user_scenario_progress ---
  if (scenarios?.length) {
    const S = Math.min(5 + Math.floor(N / 10), scenarios.length);
    const rows = [];
    for (let i = 0; i < S; i++) {
      const ago = Math.max(0, N - 2 - Math.floor((i * N) / S));
      const total = (scenarios[i].objectives ?? []).length;
      const at = dayAt(ago, ri(18, 22), ri(0, 59));
      rows.push({
        user_id: uid, scenario_id: scenarios[i].id,
        objectives_met: total, total_objectives: total,
        completed_at: at.toISOString(), attempts: ri(1, 2),
        best_score: ri(78, 100), updated_at: at.toISOString(),
      });
    }
    await rest(token, 'user_scenario_progress', { method: 'POST', prefer: 'return=minimal', body: rows });
    console.log(`  scenarios: ${S} tamamlandı`);
  }

  // --- user_badges ---
  const badgeByCode = new Map(badges.map(b => [b.code, b.id]));
  const startAgo = N - 1;
  const award = [
    ['talk_10', startAgo - 1], ['early_bird', startAgo - 1], ['words_10', startAgo - 2],
    ['night_owl', startAgo - 2], ['streak_3', startAgo - 2], ['perfect_5', startAgo - 5],
    ['scenarios_5', startAgo - 6], ['streak_7', startAgo - 6], ['talk_100', startAgo - 10],
    ['words_50', startAgo - 12],
  ];
  if (N >= 30) award.push(['words_100', startAgo - 25], ['streak_30', startAgo - 29]);
  if (N >= 50) award.push(['talk_500', startAgo - 49]);
  const badgeRows = award
    .filter(([code]) => badgeByCode.has(code))
    .map(([code, ago]) => ({
      user_id: uid, badge_id: badgeByCode.get(code),
      earned_at: dayAt(Math.max(0, ago), ri(18, 22), ri(0, 59)).toISOString(),
    }));
  await rest(token, 'user_badges?on_conflict=user_id,badge_id', {
    method: 'POST', prefer: 'return=minimal,resolution=ignore-duplicates', body: badgeRows,
  });
  const badgeXp = award.reduce((a, [code]) => a + (BADGE_XP[code] ?? 0), 0);
  console.log(`  badges: ${badgeRows.length} rozet (${badgeXp} XP)`);

  // --- daily_quests ---
  const questRows = [];
  let questXp = 0;
  for (let ago = 7; ago >= 1; ago--) {
    const qd = dateStr(dayAt(ago, 0));
    for (const [type, target, xp] of [['learn_words', 5, 20], ['conversation_turns', 10, 25], ['practice_minutes', acc.goal, 30]]) {
      questRows.push({
        user_id: uid, quest_date: qd, quest_type: type, target, progress: target,
        completed_at: dayAt(ago, 21, ri(0, 50)).toISOString(), xp_reward: xp,
        created_at: dayAt(ago, 7, 0).toISOString(),
      });
      questXp += xp;
    }
  }
  // Bugün: 2 tamam, 1 devam ediyor (gerçekçi gün-içi görünüm)
  const todayStr = dateStr(todayLocal);
  questRows.push(
    { user_id: uid, quest_date: todayStr, quest_type: 'learn_words', target: 5, progress: 5, completed_at: dayAt(0, 10, 12).toISOString(), xp_reward: 20, created_at: dayAt(0, 7, 0).toISOString() },
    { user_id: uid, quest_date: todayStr, quest_type: 'conversation_turns', target: 10, progress: 10, completed_at: dayAt(0, 12, 40).toISOString(), xp_reward: 25, created_at: dayAt(0, 7, 0).toISOString() },
    { user_id: uid, quest_date: todayStr, quest_type: 'practice_minutes', target: acc.goal, progress: Math.max(1, Math.round(acc.goal * 0.7)), completed_at: null, xp_reward: 30, created_at: dayAt(0, 7, 0).toISOString() },
  );
  questXp += 45;
  await rest(token, 'daily_quests', { method: 'POST', prefer: 'return=minimal', body: questRows });
  console.log(`  quests: ${questRows.length} görev`);

  // --- profile (xp en sonda; trg_level level'ı otomatik hesaplar) ---
  const startDate = dayAt(N - 1, 9, 0);
  const totalXp = sessionsXp + badgeXp + questXp + lessonXp + grammarXp;
  await rest(token, `profiles?id=eq.${uid}`, {
    method: 'PATCH', prefer: 'return=minimal',
    body: {
      username: acc.username,
      xp: totalXp,
      streak_days: N,
      streak_last_date: todayStr,
      streak_freezes: acc.freezes,
      last_active_at: new Date().toISOString(),
      onboarding_completed_at: startDate.toISOString(),
      daily_minute_goal: acc.goal,
      learning_motivation: acc.motivation,
      cefr_level: acc.cefr,
      seeded_at: startDate.toISOString(),
      selected_character_id: acc.character,
      target_language: 'en',
      created_at: startDate.toISOString(),
    },
  });
  console.log(`  profile: xp=${totalXp} (level ${Math.floor(totalXp / 500) + 1}), streak=${N}`);
}

// ---------------------------------------------------------------------------
for (const acc of ACCOUNTS) {
  await seedAccount(acc);
}
console.log('\nTamamlandı. Giriş bilgileri:');
for (const acc of ACCOUNTS) {
  console.log(`  ${acc.email}  /  ${PASSWORD}`);
}
