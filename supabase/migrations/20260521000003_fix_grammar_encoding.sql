-- Gramer (Grammar Topics) Tablosu Düzenlemesi (Karakter Hataları Giderme)
UPDATE public.grammar_topics SET title_tr = 'Verb To Be (am/is/are)', description_tr = '"To be" fiili kimliği, durumu ve yeri ifade eder. "Ben öğretmenim", "O mutlu", "Onlar evde" gibi cümlelerin temelidir.', examples = '[{"en":"I am a student.","tr":"Ben bir öğrenciyim."},{"en":"She is happy.","tr":"O mutlu."},{"en":"They are at home.","tr":"Onlar evdeler."},{"en":"We are friends.","tr":"Biz arkadaşız."},{"en":"It is cold today.","tr":"Bugün hava soğuk."}]'::jsonb, quiz_questions = '[{"type":"fill","prompt_en":"She ___ a doctor.","prompt_tr":"O bir doktor.","answer":"is"},{"type":"fill","prompt_en":"We ___ from Turkey.","prompt_tr":"Biz Türkiye''denyiz.","answer":"are"},{"type":"mc","prompt_en":"___ you tired?","options":["Am","Is","Are","Be"],"answer":"Are"}]'::jsonb WHERE code = 'a1_verb_to_be';

UPDATE public.grammar_topics SET title_tr = 'Geniş Zaman (Simple Present)' WHERE code = 'a1_simple_present';
UPDATE public.grammar_topics SET title_tr = 'Tanımlıklar (a/an/the)' WHERE code = 'a1_articles';
UPDATE public.grammar_topics SET title_tr = 'İyelik Sıfatları (my/your/his/her)' WHERE code = 'a1_possessive_adjectives';
UPDATE public.grammar_topics SET title_tr = 'There is / There are' WHERE code = 'a1_there_is_are';
UPDATE public.grammar_topics SET title_tr = 'Emir Kipi (Imperative)' WHERE code = 'a1_imperative';
UPDATE public.grammar_topics SET title_tr = 'Şimdiki Zaman (Present Continuous)' WHERE code = 'a1_present_continuous';
UPDATE public.grammar_topics SET title_tr = 'Yetenek/İzin (Can / Could)' WHERE code = 'a1_can_cant';