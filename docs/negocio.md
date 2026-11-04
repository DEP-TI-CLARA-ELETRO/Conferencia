# Contexto de negócio — Conferência de Caixas (Grupo Clara)

Documento vivo. Atualizar quando o processo, o ERP ou o escopo do MVP mudarem.

## 1. Empresa

**Grupo Clara** — rede com vários negócios e ERPs diferentes. O objetivo deste sistema é **padronizar** processos internos (especialmente **fechamento / conferência de caixa**) e facilitar o trabalho de setores como **financeiro**, **controle**, fiscal, tesouraria, gerência, etc.

Referência visual pedida pela direção: as imagens em [`docs/referencias/`](referencias/) (modelo tipo “SISCAIXA”). Não é para copiar pixel a pixel; o produto deve ser mais minimalista, com boa informação.

## 2. Negócios, lojas e ERPs

| Negócio | Exemplos | ERP | Como os dados de caixa devem entrar |
|---------|----------|-----|-------------------------------------|
| Materiais / elétricos | Clara Eletros | **Nerus** | Leitura de banco (somente leitura, quando houver acesso) |
| Presentes | GR Presentes | **Nerus** | Idem |
| Distribuição | Distribuidoras GR | **Nerus** (confirmar se 100% igual) | Idem |
| Postos de combustível | Postos GR | **WebPosto** | API com **token** → JSON (contrato já existente) |
| Supermercados | Supermercados GR | **CISS** | Leitura de banco (somente leitura) |

### Formas de alimentar o sistema (podem coexistir)

1. **Automático via API** — WebPosto (token + JSON).
2. **Automático via SQL** — Nerus e CISS (acesso restrito, idealmente views; nunca escrever no ERP).
3. **Assistido / manual** — digitar valores, anexar relatório/PDF, foto de cupom, etc. (complemento ou fallback quando a integração falhar).

## 3. O que o sistema deve padronizar

Ideia central (alinhada às imagens de referência):

- Acompanhar **caixas fechados** do dia / da loja.
- Comparar **valor esperado** (vindo do PDV/ERP ou lançado) × **valor conferido** (apurado pelo setor).
- Mostrar **diferença** (sobra / falta) por forma de pagamento quando fizer sentido (dinheiro, POS, TEF, etc.).
- Passar por **etapas** com responsáveis (ex.: PDV importado → conferência fiscal → tesouraria → gerência → supervisão → controladoria → finalizado).
- Anexos, justificativas e trilha para **financeiro / controle**.

Perfis e permissões da base técnica atual espelham esse fluxo (`admin`, `fiscal`, `tesouraria`, `gerencia`, `supervisao`, `controladoria`, `rh`, `financeiro`).

## 4. Decisões de escopo (MVP)

Registrado em conversa com o time de desenvolvimento:

| # | Pergunta | Decisão |
|---|----------|---------|
| 1 | Por onde começar o MVP? | **B — Postos GR + WebPosto (JSON)** |
| 2 | WebPosto já tem rotas de fechamento / caixa? | **Sim.** Spec OpenAPI arquivada e resumida em [`docs/integracoes/`](integracoes/). |

### Documentação da API WebPosto

| Arquivo | Conteúdo |
|---------|----------|
| [`integracoes/webposto.md`](integracoes/webposto.md) | Resumo: rotas MVP, schemas, encaixe no produto |
| [`integracoes/webposto-openapi.json`](integracoes/webposto-openapi.json) | OpenAPI completo (~157 paths) |

Rotas centrais para o MVP: `EMPRESAS`, `CAIXAS`, `CAIXAS_APRESENTADO` (apresentado × apurado × diferença por forma de pagamento).

### Fora do MVP imediato (próximas ondas)

- Integração **Nerus** (Eletros, Presentes, distribuidoras) via leitura de banco.
- Integração **CISS** (supermercados) via leitura de banco.
- Fluxo 100% manual com OCR de cupom (pode entrar como fallback pontual, mas não é o foco da 1ª entrega WebPosto).

A **UI e o fluxo humano** (lista do dia, conferência, etapas) devem nascer **genéricos** (por loja + conector), para reutilizar quando Nerus/CISS entrarem.

## 5. Implicações técnicas (orientação)

- Cada **loja** no sistema precisará de metadados: bandeira/negócio, ERP, **conector** (`webposto` \| `nerus` \| `ciss` \| `manual`).
- Cada **fechamento de caixa** deve registrar a **origem** dos valores esperados (API WebPosto, SQL, manual, anexo).
- Credenciais (token WebPosto, connection strings Nerus/CISS) ficam só em **segredos / `.env`**, nunca no Git.
- Integrações de banco de terceiros: preferir usuário **read-only** e objetos acordados com o fornecedor.
- Detalhes da integração WebPosto: ver [`integracoes/webposto.md`](integracoes/webposto.md).

## 6. Pendências para o próximo passo

- [x] Arquivar OpenAPI WebPosto e resumir rotas de caixa (`docs/integracoes/`).
- [x] Integração server/app: sync WebPosto (`chave` no `.env`) + listagem de caixas.
- [ ] Smoke test com chave real (1 posto / 1 dia).
- [ ] Confirmar se **Distribuidoras GR** usam Nerus no mesmo modelo das Eletros.
- [ ] Definir, com a operação, os **papéis** que vão usar o MVP nos postos (quem confere, quem aprova).
- [ ] Critério de “bateu”: tolerância de centavos? obrigatório justificar divergência?
- [ ] Definir se a conferência humana **reedita** valores ou só **valida** o apurado já vindo do WebPosto.

## 7. Histórico curto

| Data | Nota |
|------|------|
| 2026-11-03 | Contexto Grupo Clara + multi-ERP; MVP = Postos + WebPosto. |
| 2026-11-03 | `api.json` organizado em `docs/integracoes/webposto-openapi.json` + resumo `webposto.md`. |
