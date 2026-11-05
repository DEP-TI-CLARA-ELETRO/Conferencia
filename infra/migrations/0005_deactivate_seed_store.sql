-- Loja seed de demo ("Loja 01 - Centro") não é unidade real do Grupo Clara.
UPDATE stores
SET active = FALSE
WHERE code = '01' AND name ILIKE '%Loja 01%';
