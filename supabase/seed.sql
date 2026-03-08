-- Seed data for initial app load

INSERT INTO public.pocus_items (id, category, title_pt, title_es, body_pt, body_es, is_premium, status) 
VALUES 
  (gen_random_uuid(), 'Emergência', 'Choque Obstrutivo', 'Choque Obstructivo', 'Avaliação de TEP e Tamponamento Cardíaco via POCUS.', 'Evaluación de TEP y Taponamiento Cardíaco vía POCUS.', false, 'published'),
  (gen_random_uuid(), 'Cardiologia', 'Derrame Pericárdico', 'Derrame Pericárdico', 'Janela subxifoide mostrando sinal do balanço.', 'Ventana subxifoidea mostrando el signo de bamboleo.', false, 'published')
ON CONFLICT DO NOTHING;
