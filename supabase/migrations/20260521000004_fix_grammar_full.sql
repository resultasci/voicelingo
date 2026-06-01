-- Apply full grammar content fixes
CREATE TEMP TABLE temp_grammar_topics (
  level text, order_index int, code text, title_tr text, title_en text,
  description_tr text, description_en text, examples jsonb, quiz_questions jsonb, xp_reward int
);

INSERT INTO temp_grammar_topics (level, order_index, code, title_tr, title_en, description_tr, description_en, examples, quiz_questions, xp_reward) VALUES
('A1', 1, 'a1_verb_to_be', 'Verb To Be (am/is/are)', 'Verb To Be (am/is/are)',
 '"To be" fiili kimliği, durumu ve yeri ifade eder. "Ben öğretmenim", "O mutlu", "Onlar evde" gibi cümlelerin temelidir.',
 'The verb "to be" expresses identity, state, and location. It is the foundation of sentences like "I am a teacher", "She is happy", "They are at home".',
 '[{"en":"I am a student.","tr":"Ben bir öğrenciyim."},{"en":"She is happy.","tr":"O mutlu."},{"en":"They are at home.","tr":"Onlar evdeler."},{"en":"We are friends.","tr":"Biz arkadaşız."},{"en":"It is cold today.","tr":"Bugün hava soğuk."}]'::jsonb,
 '[{"type":"fill","prompt_en":"She ___ a doctor.","prompt_tr":"O bir doktor.","answer":"is"},{"type":"fill","prompt_en":"We ___ from Turkey.","prompt_tr":"Biz Türkiye''denyiz.","answer":"are"},{"type":"mc","prompt_en":"___ you tired?","options":["Am","Is","Are","Be"],"answer":"Are"}]'::jsonb,
 30),

('A1', 2, 'a1_simple_present', 'Geniş Zaman (Simple Present)', 'Simple Present Tense',
 'Geniş zaman alışkanlıklar, genel gerçekler ve düzenli olaylar için kullanılır. Üçüncü tekil şahısta fiile -s/-es eklenir.',
 'Simple Present is used for habits, general truths, and routines. Add -s/-es to the verb in third-person singular.',
 '[{"en":"I drink coffee every morning.","tr":"Her sabah kahve içerim."},{"en":"He works at a bank.","tr":"O bir bankada çalışır."},{"en":"The sun rises in the east.","tr":"Güneş doğudan doğar."},{"en":"She lives in Istanbul.","tr":"O İstanbul''da yaşıyor."}]'::jsonb,
 '[{"type":"fill","prompt_en":"He ___ (play) football on weekends.","answer":"plays"},{"type":"fill","prompt_en":"They ___ (not / like) fish.","answer":"do not like"},{"type":"mc","prompt_en":"___ she speak English?","options":["Do","Does","Is","Are"],"answer":"Does"}]'::jsonb,
 30),

('A1', 3, 'a1_articles', 'Tanımlıklar (a/an/the)', 'Articles (a/an/the)',
 '"A/an" belirsiz tanımlık, ilk kez bahsedilen tekil isimler için. "The" belirli tanımlık, bilinen veya tekrar bahsedilen isimler için.',
 '"A/an" is the indefinite article for singular nouns first mentioned. "The" is the definite article for known or repeated nouns.',
 '[{"en":"I saw a dog. The dog was friendly.","tr":"Bir köpek gördüm. O köpek dostçaydı."},{"en":"She is an engineer.","tr":"O bir mühendis."},{"en":"The sun is bright.","tr":"Güneş parlak."},{"en":"I need an umbrella.","tr":"Bir şemsiyeye ihtiyacım var."}]'::jsonb,
 '[{"type":"fill","prompt_en":"I have ___ apple.","answer":"an"},{"type":"fill","prompt_en":"She is ___ best student in the class.","answer":"the"},{"type":"mc","prompt_en":"He bought ___ car last week.","options":["a","an","the","-"],"answer":"a"}]'::jsonb,
 30),

('A1', 4, 'a1_possessives', 'İyelik Sıfatları (my/your/his/her)', 'Possessive Adjectives',
 'İyelik sıfatları bir şeyin kime ait olduğunu gösterir: my (benim), your (senin), his (onun-erkek), her (onun-kadın), its (onun-nesne), our (bizim), their (onların).',
 'Possessive adjectives show ownership: my, your, his, her, its, our, their.',
 '[{"en":"This is my book.","tr":"Bu benim kitabım."},{"en":"What is your name?","tr":"Senin adın ne?"},{"en":"Her car is red.","tr":"Onun arabası kırmızı."},{"en":"Their house is big.","tr":"Onların evi büyük."}]'::jsonb,
 '[{"type":"fill","prompt_en":"He loves ___ family. (he)","answer":"his"},{"type":"fill","prompt_en":"We live with ___ parents.","answer":"our"},{"type":"mc","prompt_en":"This is Mary. ___ dog is cute.","options":["His","Her","Its","Their"],"answer":"Her"}]'::jsonb,
 30),

('A1', 5, 'a1_there_is_are', 'There is / There are', 'There is / There are',
 'Bir yerde bir şeyin VAR olduğunu söylerken kullanılır. Tekil için "there is", çoğul için "there are".',
 'Used to say something EXISTS in a place. "There is" for singular, "there are" for plural.',
 '[{"en":"There is a cat on the chair.","tr":"Sandalyede bir kedi var."},{"en":"There are two books on the table.","tr":"Masada iki kitap var."},{"en":"Is there a problem?","tr":"Bir sorun var mı?"},{"en":"There aren''t any people here.","tr":"Burada hiç insan yok."}]'::jsonb,
 '[{"type":"fill","prompt_en":"___ a bank near here.","answer":"There is"},{"type":"fill","prompt_en":"___ many students in the class.","answer":"There are"},{"type":"mc","prompt_en":"___ any milk in the fridge?","options":["Is there","Are there","There is","There are"],"answer":"Is there"}]'::jsonb,
 30),

('A1', 6, 'a1_imperative', 'Emir Kipi (Imperative)', 'Imperative Mood',
 'Emir kipi talimat, rica veya öneri verirken kullanılır. Fiilin temel hali kullanılır, özne söylenmez.',
 'The imperative is used to give instructions, requests, or suggestions. Use the base form of the verb without a subject.',
 '[{"en":"Open the door, please.","tr":"Lütfen kapıyı aç."},{"en":"Don''t touch that!","tr":"Ona dokunma!"},{"en":"Be careful.","tr":"Dikkatli ol."},{"en":"Sit down.","tr":"Otur."}]'::jsonb,
 '[{"type":"fill","prompt_en":"___ quiet, please.","answer":"Be"},{"type":"fill","prompt_en":"___ run in the hallway. (negative)","answer":"Don''t"},{"type":"mc","prompt_en":"___ your homework before dinner.","options":["Do","Does","Doing","Done"],"answer":"Do"}]'::jsonb,
 30),

('A1', 7, 'a1_present_continuous', 'Åimdiki Zaman (Present Continuous)', 'Present Continuous',
 'Åu anda devam eden eylemler için kullanılır. "be + verb-ing" yapısı. "I am working", "She is sleeping".',
 'Used for actions happening right now. Structure: "be + verb-ing". "I am working", "She is sleeping".',
 '[{"en":"I am reading a book.","tr":"Kitap okuyorum."},{"en":"They are playing in the garden.","tr":"Bahçede oynuyorlar."},{"en":"What are you doing?","tr":"Ne yapıyorsun?"},{"en":"She isn''t listening.","tr":"O dinlemiyor."}]'::jsonb,
 '[{"type":"fill","prompt_en":"He ___ (work) right now.","answer":"is working"},{"type":"fill","prompt_en":"They ___ (not / sleep).","answer":"are not sleeping"},{"type":"mc","prompt_en":"___ you waiting for me?","options":["Do","Does","Are","Is"],"answer":"Are"}]'::jsonb,
 30),

('A1', 8, 'a1_can_could', 'Yetenek/İzin (Can / Could)', 'Can / Could',
 '"Can" şimdiki yetenek ve izin için ("I can swim"). "Could" geçmiş yetenek ve kibar rica için ("Could you help me?").',
 '"Can" for present ability and permission. "Could" for past ability and polite requests.',
 '[{"en":"I can speak English.","tr":"İngilizce konuşabilirim."},{"en":"Could you pass the salt?","tr":"Tuzu uzatır mısın?"},{"en":"She couldn''t come yesterday.","tr":"O dün gelemedi."},{"en":"Can I help you?","tr":"Yardım edebilir miyim?"}]'::jsonb,
 '[{"type":"fill","prompt_en":"___ you swim?","answer":"Can"},{"type":"fill","prompt_en":"He ___ ride a bike when he was 5.","answer":"could"},{"type":"mc","prompt_en":"___ I borrow your pen?","options":["Can","Am","Is","Will"],"answer":"Can"}]'::jsonb,
 30);

UPDATE public.grammar_topics t
SET 
  title_tr = tmp.title_tr,
  description_tr = tmp.description_tr,
  examples = tmp.examples,
  quiz_questions = tmp.quiz_questions
FROM temp_grammar_topics tmp
WHERE t.code = tmp.code;

DROP TABLE temp_grammar_topics;
