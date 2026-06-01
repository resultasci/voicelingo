-- Mevcut veritabanındaki bozuk Türkçe karakterleri düzeltme yaması

-- 1. Rozetler (Badges) Tablosu Düzenlemesi
UPDATE public.badges SET name_tr = '3 Gün', description_tr = '3 gün üst üste çalıştın!' WHERE code = 'streak_3';
UPDATE public.badges SET name_tr = 'Bir Hafta', description_tr = '7 gün üst üste çalıştın!' WHERE code = 'streak_7';
UPDATE public.badges SET name_tr = 'Bir Ay', description_tr = '30 gün üst üste çalıştın!' WHERE code = 'streak_30';
UPDATE public.badges SET name_tr = 'Yüz Gün', description_tr = '100 gün üst üste çalıştın!' WHERE code = 'streak_100';

UPDATE public.badges SET name_tr = 'İlk Adım', description_tr = '10 kelime öğrendin' WHERE code = 'words_10';
UPDATE public.badges SET name_tr = 'Sözlük Avcısı', description_tr = '50 kelime ustası oldun' WHERE code = 'words_50';
UPDATE public.badges SET name_tr = 'Yüz Kelime', description_tr = '100 kelime ustası oldun' WHERE code = 'words_100';
UPDATE public.badges SET name_tr = 'Beş Yüz', description_tr = '500 kelime ustası oldun' WHERE code = 'words_500';

UPDATE public.badges SET name_tr = 'İlk Sohbet', description_tr = '10 konuşma turu tamamladın' WHERE code = 'talk_10';
UPDATE public.badges SET name_tr = 'Sohbet Eden', description_tr = '100 konuşma turu tamamladın' WHERE code = 'talk_100';
UPDATE public.badges SET name_tr = 'Konuşmacı', description_tr = '500 konuşma turu tamamladın' WHERE code = 'talk_500';

UPDATE public.badges SET name_tr = 'Mükemmel', description_tr = '5 kez 95+ puan aldın' WHERE code = 'perfect_5';

UPDATE public.badges SET name_tr = 'Sabah Kuşu', description_tr = 'Sabah 06-09 arası çalıştın' WHERE code = 'early_bird';
UPDATE public.badges SET name_tr = 'Gece Kuşu', description_tr = 'Gece 22-02 arası çalıştın' WHERE code = 'night_owl';

UPDATE public.badges SET name_tr = 'Senarist', description_tr = '5 senaryo tamamladın' WHERE code = 'scenarios_5';

-- 2. Üniteler (Units) Tablosu Düzenlemesi
UPDATE public.units SET title_tr = 'Selamlaşma ve Tanışma' WHERE title_en = 'Greetings & Introductions';
UPDATE public.units SET title_tr = 'Günlük Rutinler' WHERE title_en = 'Daily Routines';
UPDATE public.units SET title_tr = 'Yiyecek ve İçecekler' WHERE title_en = 'Food & Drinks';

-- 3. Dersler (Lessons) Tablosu Düzenlemesi
UPDATE public.lessons SET title_tr = 'Selamlaşma Kelimeleri', content = '{"words":[{"en":"hello","tr":"merhaba"},{"en":"goodbye","tr":"hoşçakal"},{"en":"please","tr":"lütfen"},{"en":"thank you","tr":"teşekkür ederim"},{"en":"yes","tr":"evet"},{"en":"no","tr":"hayır"},{"en":"sorry","tr":"özür dilerim"},{"en":"good morning","tr":"günaydın"}]}'::jsonb WHERE title_en = 'Greeting Words';

UPDATE public.lessons SET title_tr = 'Tanışma Pratiği' WHERE title_en = 'Small Talk Practice';

UPDATE public.lessons SET title_tr = 'Günlük Aktivite Fiilleri', content = '{"words":[{"en":"wake up","tr":"uyanmak"},{"en":"eat","tr":"yemek"},{"en":"drink","tr":"içmek"},{"en":"work","tr":"çalışmak"},{"en":"sleep","tr":"uyumak"},{"en":"study","tr":"çalışmak (ders)"},{"en":"read","tr":"okumak"},{"en":"watch","tr":"izlemek"}]}'::jsonb WHERE title_en = 'Daily Activity Verbs';

UPDATE public.lessons SET title_tr = 'Geniş Zaman' WHERE title_en = 'Simple Present';
UPDATE public.lessons SET title_tr = 'Şimdiki Zaman' WHERE title_en = 'Present Continuous';
UPDATE public.lessons SET title_tr = 'Kafe Sohbeti' WHERE title_en = 'Coffee Shop Talk';

UPDATE public.lessons SET title_tr = 'Yiyecek Kelimeleri', content = '{"words":[{"en":"bread","tr":"ekmek"},{"en":"cheese","tr":"peynir"},{"en":"apple","tr":"elma"},{"en":"chicken","tr":"tavuk"},{"en":"rice","tr":"pirinç"},{"en":"water","tr":"su"},{"en":"tea","tr":"çay"},{"en":"coffee","tr":"kahve"}]}'::jsonb WHERE title_en = 'Food Words';

UPDATE public.lessons SET title_tr = 'Tanımlıklar' WHERE title_en = 'Articles';
UPDATE public.lessons SET title_tr = 'Restoran Siparişi' WHERE title_en = 'Restaurant Order';

-- 4. Gramer (Grammar Topics) Tablosu Düzenlemesi
UPDATE public.grammar_topics SET title_tr = 'Geniş Zaman (Simple Present)' WHERE code = 'a1_simple_present';
UPDATE public.grammar_topics SET title_tr = 'Tanımlıklar (a/an/the)' WHERE code = 'a1_articles';
UPDATE public.grammar_topics SET title_tr = 'İyelik Sıfatları (my/your/his/her)' WHERE code = 'a1_possessive_adjectives';
UPDATE public.grammar_topics SET title_tr = 'Emir Kipi (Imperative)' WHERE code = 'a1_imperative';
UPDATE public.grammar_topics SET title_tr = 'Şimdiki Zaman (Present Continuous)' WHERE code = 'a1_present_continuous';
UPDATE public.grammar_topics SET title_tr = 'Yetenek/İzin (Can / Could)' WHERE code = 'a1_can_cant';

