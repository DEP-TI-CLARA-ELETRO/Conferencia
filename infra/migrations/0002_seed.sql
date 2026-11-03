-- Perfis, permissoes e loja inicial.
-- O usuario admin de desenvolvimento e criado pelo servidor (precisa de hash de senha).

INSERT INTO stores (code, name) VALUES ('01', 'Loja 01 - Centro');

INSERT INTO roles (code, name) VALUES
    ('admin',        'Administrador'),
    ('fiscal',       'Fiscal de Caixa'),
    ('tesouraria',   'Tesouraria'),
    ('gerencia',     'Gerencia'),
    ('supervisao',   'Supervisao'),
    ('controladoria','Controladoria'),
    ('rh',           'Recursos Humanos'),
    ('financeiro',   'Financeiro');

INSERT INTO permissions (code, description) VALUES
    ('home.view',         'Ver pagina inicial'),
    ('closings.view',     'Ver caixas do dia'),
    ('closings.fiscal',   'Conferencia fiscal do caixa'),
    ('closings.treasury', 'Recebimento e conferencia da tesouraria'),
    ('closings.manager',  'Aprovacao da gerencia'),
    ('closings.supervisor','Aprovacao da supervisao'),
    ('closings.audit',    'Controladoria'),
    ('vouchers.view',     'Ver vales e diferencas'),
    ('hr.view',           'Ver ocorrencias e RH'),
    ('finance.view',      'Ver financeiro'),
    ('users.manage',      'Gerenciar usuarios e permissoes');

-- Admin: tudo
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p WHERE r.code = 'admin';

-- Demais perfis
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM (VALUES
    ('fiscal',        'home.view'),
    ('fiscal',        'closings.view'),
    ('fiscal',        'closings.fiscal'),
    ('tesouraria',    'home.view'),
    ('tesouraria',    'closings.view'),
    ('tesouraria',    'closings.treasury'),
    ('gerencia',      'home.view'),
    ('gerencia',      'closings.view'),
    ('gerencia',      'closings.manager'),
    ('gerencia',      'vouchers.view'),
    ('supervisao',    'home.view'),
    ('supervisao',    'closings.view'),
    ('supervisao',    'closings.supervisor'),
    ('controladoria', 'home.view'),
    ('controladoria', 'closings.view'),
    ('controladoria', 'closings.audit'),
    ('rh',            'home.view'),
    ('rh',            'hr.view'),
    ('rh',            'vouchers.view'),
    ('financeiro',    'home.view'),
    ('financeiro',    'closings.view'),
    ('financeiro',    'finance.view')
) AS m(role_code, perm_code)
JOIN roles r ON r.code = m.role_code
JOIN permissions p ON p.code = m.perm_code;
