-- A1 Ders Yolunu Genişletme (Unit 4 - 8)
DO $$
DECLARE
  c_id uuid;
  u3_id uuid;
  u4_id uuid;
  u5_id uuid;
  u6_id uuid;
  u7_id uuid;
  u8_id uuid;
BEGIN
  -- Mevcut A1 Kursunu Bul
  SELECT id INTO c_id FROM public.courses WHERE language = 'en' AND level = 'A1';
  IF c_id IS NULL THEN RETURN; END IF;

  -- Unit 3'ü bul, prerequisite olarak kullanacağız
  SELECT id INTO u3_id FROM public.units WHERE course_id = c_id AND order_index = 3;

  -- Unit 4: Family & Friends (Ailem ve Arkadaşlarım)
  INSERT INTO public.units (course_id, order_index, title_tr, title_en, theme, prerequisite_unit_id)
  VALUES (c_id, 4, 'Ailem ve Arkadaşlarım', 'Family & Friends', 'family', u3_id)
  RETURNING id INTO u4_id;

  INSERT INTO public.lessons (unit_id, order_index, type, title_tr, title_en, content, xp_reward) VALUES
    (u4_id, 1, 'vocab', 'Aile Üyeleri', 'Family Members', '{"words":[{"en":"mother","tr":"anne"},{"en":"father","tr":"baba"},{"en":"brother","tr":"erkek kardeş"},{"en":"sister","tr":"kız kardeş"},{"en":"friend","tr":"arkadaş"},{"en":"family","tr":"aile"}]}'::jsonb, 20),
    (u4_id, 2, 'grammar', 'İyelik Sıfatları', 'Possessive Adjectives', '{"topic_code":"a1_possessive_adjectives"}'::jsonb, 30),
    (u4_id, 3, 'conversation', 'Aileni Tanıt', 'Family Intro', '{"scenario_code":"family_intro","min_turns":4}'::jsonb, 30),
    (u4_id, 4, 'quiz', 'Unit 4 Quiz', 'Unit 4 Quiz', '{"questions":[{"type":"mc","prompt_en":"This is ___ brother.","options":["I","me","my","mine"],"answer":"my"}]}'::jsonb, 30);

  -- Unit 5: Jobs & City (Meslekler ve Şehir)
  INSERT INTO public.units (course_id, order_index, title_tr, title_en, theme, prerequisite_unit_id)
  VALUES (c_id, 5, 'Meslekler ve Şehir', 'Jobs & City', 'city', u4_id)
  RETURNING id INTO u5_id;

  INSERT INTO public.lessons (unit_id, order_index, type, title_tr, title_en, content, xp_reward) VALUES
    (u5_id, 1, 'vocab', 'Meslekler', 'Jobs', '{"words":[{"en":"teacher","tr":"öğretmen"},{"en":"doctor","tr":"doktor"},{"en":"student","tr":"öğrenci"},{"en":"hospital","tr":"hastane"},{"en":"school","tr":"okul"}]}'::jsonb, 20),
    (u5_id, 2, 'grammar', 'There is / There are', 'There is / There are', '{"topic_code":"a1_there_is_are"}'::jsonb, 30),
    (u5_id, 3, 'conversation', 'Yol Tarifi ve Meslek', 'Directions & Jobs', '{"scenario_code":"directions","min_turns":4}'::jsonb, 30),
    (u5_id, 4, 'quiz', 'Unit 5 Quiz', 'Unit 5 Quiz', '{"questions":[{"type":"fill","prompt_en":"___ there a bank near here?","answer":"Is"}]}'::jsonb, 30);

  -- Unit 6: Shopping & Clothes (Alışveriş ve Giysiler)
  INSERT INTO public.units (course_id, order_index, title_tr, title_en, theme, prerequisite_unit_id)
  VALUES (c_id, 6, 'Alışveriş ve Giysiler', 'Shopping & Clothes', 'shopping', u5_id)
  RETURNING id INTO u6_id;

  INSERT INTO public.lessons (unit_id, order_index, type, title_tr, title_en, content, xp_reward) VALUES
    (u6_id, 1, 'vocab', 'Giysiler ve Renkler', 'Clothes & Colors', '{"words":[{"en":"shirt","tr":"gömlek"},{"en":"pants","tr":"pantolon"},{"en":"shoes","tr":"ayakkabı"},{"en":"red","tr":"kırmızı"},{"en":"blue","tr":"mavi"}]}'::jsonb, 20),
    (u6_id, 2, 'grammar', 'Some / Any / Much / Many', 'Quantifiers', '{"topic_code":"a1_quantifiers"}'::jsonb, 30),
    (u6_id, 3, 'conversation', 'Mağazada Alışveriş', 'Shopping in a Store', '{"scenario_code":"shopping","min_turns":5}'::jsonb, 30),
    (u6_id, 4, 'quiz', 'Unit 6 Quiz', 'Unit 6 Quiz', '{"questions":[{"type":"mc","prompt_en":"How ___ apples do we have?","options":["much","many","some","any"],"answer":"many"}]}'::jsonb, 30);

  -- Unit 7: Hobbies & Free Time (Hobiler ve Boş Zaman)
  INSERT INTO public.units (course_id, order_index, title_tr, title_en, theme, prerequisite_unit_id)
  VALUES (c_id, 7, 'Hobiler ve Boş Zaman', 'Hobbies & Free Time', 'hobbies', u6_id)
  RETURNING id INTO u7_id;

  INSERT INTO public.lessons (unit_id, order_index, type, title_tr, title_en, content, xp_reward) VALUES
    (u7_id, 1, 'vocab', 'Hobiler', 'Hobbies', '{"words":[{"en":"play","tr":"oynamak"},{"en":"swim","tr":"yüzmek"},{"en":"read","tr":"okumak"},{"en":"music","tr":"müzik"},{"en":"game","tr":"oyun"}]}'::jsonb, 20),
    (u7_id, 2, 'grammar', 'Can / Can Not (Yetenek)', 'Can / Can not', '{"topic_code":"a1_can_cant"}'::jsonb, 30),
    (u7_id, 3, 'conversation', 'Hafta Sonu Planı', 'Weekend Plan', '{"scenario_code":"weekend_plan","min_turns":4}'::jsonb, 30),
    (u7_id, 4, 'quiz', 'Unit 7 Quiz', 'Unit 7 Quiz', '{"questions":[{"type":"fill","prompt_en":"She ___ (can) swim very fast.","answer":"can"}]}'::jsonb, 30);

  -- Unit 8: Time & Dates (Zaman ve Tarihler)
  INSERT INTO public.units (course_id, order_index, title_tr, title_en, theme, prerequisite_unit_id)
  VALUES (c_id, 8, 'Zaman ve Tarihler', 'Time & Dates', 'time', u7_id)
  RETURNING id INTO u8_id;

  INSERT INTO public.lessons (unit_id, order_index, type, title_tr, title_en, content, xp_reward) VALUES
    (u8_id, 1, 'vocab', 'Günler ve Saatler', 'Days & Time', '{"words":[{"en":"Monday","tr":"Pazartesi"},{"en":"week","tr":"hafta"},{"en":"month","tr":"ay"},{"en":"year","tr":"yıl"},{"en":"time","tr":"zaman"}]}'::jsonb, 20),
    (u8_id, 2, 'grammar', 'Saatleri Söyleme', 'Telling Time', '{"topic_code":"a1_telling_time"}'::jsonb, 30),
    (u8_id, 3, 'conversation', 'Randevu Ayarlama', 'Making an Appointment', '{"scenario_code":"appointment","min_turns":4}'::jsonb, 30),
    (u8_id, 4, 'quiz', 'Unit 8 Quiz', 'Unit 8 Quiz', '{"questions":[{"type":"mc","prompt_en":"What time is it? (14:00)","options":["two o clock","four o clock","two past","four pm"],"answer":"two o clock"}]}'::jsonb, 30);

END $$;
