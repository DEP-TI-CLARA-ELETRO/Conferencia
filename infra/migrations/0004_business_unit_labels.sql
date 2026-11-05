-- Garante business_unit nas lojas existentes e classifica o seed.
UPDATE stores
SET business_unit = 'materiais'
WHERE code = '01' AND (business_unit IS NULL OR business_unit = '');

UPDATE stores
SET business_unit = 'posto'
WHERE connector = 'webposto'
  AND (business_unit IS NULL OR business_unit = '');

UPDATE stores
SET business_unit = 'outros'
WHERE business_unit IS NULL OR business_unit = '';
