-- =============================================================================
-- A1 kursuna dinleme dersleri (Unit 1-8, her ünitede 1 adet)
--
-- İçerik sözleşmesi (_ListeningRunner): content.sentences = [{"en", "tr"}].
-- Cümleler A1 seviyesinde ve ünite temasına uygun; kesme işaretli kalıplardan
-- (can't, o'clock) bilinçli kaçınıldı — runner'ın normalize karşılaştırması
-- kesme işaretini koruduğu için öğrenci yazımıyla çakışabiliyor.
--
-- Idempotent: ünitede listening dersi varsa atlanır; order_index ünitenin
-- mevcut maksimumunun sonuna eklenir (araya sokup sıra bozmamak için).
-- Not: isUnitUnlocked prerequisite ünitenin TÜM derslerini istediğinden,
-- tamamlanmış ünitelere ders eklemek sonraki üniteyi yeniden kilitler —
-- yeni içerik yapılana kadar; bilinçli davranış.
-- =============================================================================
DO $$
DECLARE
  c_id uuid;
  u_id uuid;
  next_order int;
  rec record;
BEGIN
  SELECT id INTO c_id FROM public.courses WHERE language = 'en' AND level = 'A1';
  IF c_id IS NULL THEN RETURN; END IF;

  FOR rec IN
    SELECT * FROM (VALUES
      (1, 'Dinleme: Selamlaşma', 'Listening: Greetings',
       '{"sentences":[
          {"en":"Hello, my name is Anna.","tr":"Merhaba, benim adım Anna."},
          {"en":"Good morning! How are you?","tr":"Günaydın! Nasılsın?"},
          {"en":"Thank you very much.","tr":"Çok teşekkür ederim."},
          {"en":"Nice to meet you.","tr":"Tanıştığımıza memnun oldum."}]}'::jsonb),
      (2, 'Dinleme: Günlük Rutinler', 'Listening: Daily Routines',
       '{"sentences":[
          {"en":"I wake up at seven every day.","tr":"Her gün yedide uyanırım."},
          {"en":"She works at a bank.","tr":"O bir bankada çalışır."},
          {"en":"We watch TV in the evening.","tr":"Akşam televizyon izleriz."},
          {"en":"He reads a book every night.","tr":"O her gece kitap okur."}]}'::jsonb),
      (3, 'Dinleme: Yiyecekler', 'Listening: Food & Drinks',
       '{"sentences":[
          {"en":"I would like a cup of tea.","tr":"Bir fincan çay istiyorum."},
          {"en":"Can I have some bread, please?","tr":"Biraz ekmek alabilir miyim, lütfen?"},
          {"en":"She drinks coffee every morning.","tr":"O her sabah kahve içer."},
          {"en":"The apple is on the table.","tr":"Elma masanın üstünde."}]}'::jsonb),
      (4, 'Dinleme: Aile', 'Listening: Family',
       '{"sentences":[
          {"en":"This is my mother.","tr":"Bu benim annem."},
          {"en":"My brother is ten years old.","tr":"Erkek kardeşim on yaşında."},
          {"en":"Her sister is my friend.","tr":"Onun kız kardeşi benim arkadaşım."},
          {"en":"We are a big family.","tr":"Biz büyük bir aileyiz."}]}'::jsonb),
      (5, 'Dinleme: Meslekler ve Şehir', 'Listening: Jobs & City',
       '{"sentences":[
          {"en":"My father is a doctor.","tr":"Babam doktor."},
          {"en":"There is a school near my house.","tr":"Evimin yakınında bir okul var."},
          {"en":"She is a teacher at this school.","tr":"O bu okulda öğretmen."},
          {"en":"Is there a hospital in this city?","tr":"Bu şehirde hastane var mı?"}]}'::jsonb),
      (6, 'Dinleme: Alışveriş', 'Listening: Shopping',
       '{"sentences":[
          {"en":"How much is this shirt?","tr":"Bu gömlek ne kadar?"},
          {"en":"I want to buy new shoes.","tr":"Yeni ayakkabılar almak istiyorum."},
          {"en":"Do you have this in blue?","tr":"Bunun mavisi var mı?"},
          {"en":"These pants are too big.","tr":"Bu pantolon çok büyük."}]}'::jsonb),
      (7, 'Dinleme: Hobiler', 'Listening: Hobbies',
       '{"sentences":[
          {"en":"I can swim very well.","tr":"Çok iyi yüzebilirim."},
          {"en":"We play games on the weekend.","tr":"Hafta sonu oyun oynarız."},
          {"en":"She likes to read books.","tr":"O kitap okumayı sever."},
          {"en":"He cannot play the guitar.","tr":"O gitar çalamaz."}]}'::jsonb),
      (8, 'Dinleme: Zaman', 'Listening: Time & Dates',
       '{"sentences":[
          {"en":"Today is Monday.","tr":"Bugün Pazartesi."},
          {"en":"The meeting is at three.","tr":"Toplantı saat üçte."},
          {"en":"My birthday is in May.","tr":"Doğum günüm Mayısta."},
          {"en":"See you next week.","tr":"Gelecek hafta görüşürüz."}]}'::jsonb)
    ) AS t(unit_order, title_tr, title_en, content)
  LOOP
    SELECT id INTO u_id FROM public.units
     WHERE course_id = c_id AND order_index = rec.unit_order;
    IF u_id IS NULL THEN CONTINUE; END IF;

    IF EXISTS (SELECT 1 FROM public.lessons
                WHERE unit_id = u_id AND type = 'listening') THEN
      CONTINUE;
    END IF;

    SELECT COALESCE(MAX(order_index), 0) + 1 INTO next_order
      FROM public.lessons WHERE unit_id = u_id;

    INSERT INTO public.lessons
      (unit_id, order_index, type, title_tr, title_en, content, xp_reward)
    VALUES
      (u_id, next_order, 'listening', rec.title_tr, rec.title_en, rec.content, 25);
  END LOOP;
END $$;
