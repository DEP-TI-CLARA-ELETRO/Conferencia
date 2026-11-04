# Integração WebPosto (Quality Automação)

Especificação OpenAPI oficial (exportada): [`webposto-openapi.json`](webposto-openapi.json).

**Não versionar tokens** neste repositório. Credenciais só em `.env` / secrets.

## Visão geral

| Item | Valor |
|------|--------|
| Fornecedor | Quality Automação / WebPosto |
| Uso no Grupo Clara | Postos GR |
| Formato | OpenAPI 3.1 |
| Servidor documentado | `http://web.qualityautomacao.com.br` |
| Prefixo das rotas | `/INTEGRACAO/V1/...` (há algumas em `/INTEGRACAO/` e V2) |
| Volume | ~157 paths (posto completo; MVP usa só um subconjunto) |
| Autenticação | Query **`chave=<token>`** em todas as chamadas (chave de API Integração no WebPosto) |

Paginação típica: `ultimoCodigo` + `limite` (máx. 2000). Resposta comum: `{ "ultimoCodigo": ..., "resultados": [ ... ] }`.

## Rotas prioritárias para conferência de caixa (MVP)

### Cadastro de filiais

- `GET /INTEGRACAO/V1/EMPRESAS` — lista empresas/filiais (`empresaCodigo`). Mapear para `stores` no nosso sistema.

### Lista de caixas / fechamentos

- `GET /INTEGRACAO/V1/CAIXAS` (`operationId`: `consultarCaixa`)

Query útil: `dataInicial`, `dataFinal`, `turno`, `empresaCodigo`, `individual`, `ultimoCodigo`, `limite`, `dataHoraAtualizacao`.

Schema **`CaixaRede`** (resumo):

- Identificação: `empresaCodigo`, `caixaCodigo`, `pdvCodigo`, `funcionarioCodigo`, `codigo`
- Turno: `turnoCodigo`, `turno`
- Tempo: `dataMovimento`, `abertura`, `fechamento`
- Status: `fechado`, `consolidado`, `bloqueado`, `tipoBloqueio`, `tipoInclusao`
- Totais: `apurado`, `diferenca`
- `centroCusto`, `dataHoraAtualizacao`

Uso no produto: alimentar a tela **Caixas do dia**.

### Apresentado × apurado × diferença (núcleo da conferência)

- `GET /INTEGRACAO/V1/CAIXAS_APRESENTADO` (`operationId`: `consultarCaixaApresentado`)

Query útil: `dataInicial`, `dataFinal`, `tipoData` (`EMISSAO` \| `ENTRADA`), `ultimoCodigo`, `limite`, `dataHoraAtualizacao`.

Schema **`CaixaApresentadoRede`**: para várias formas de pagamento existem três campos
`…Apresentado`, `…Apurado`, `…Diferenca`, por exemplo:

- dinheiro, nota a prazo, cheque, cheque pré, cartão
- carta frete, vale cliente, empréstimo, pré-pago, despesa, vale funcionário
- cheque a pagar, transferência bancária, transferência débito, fundo de caixa débito

Extras úteis: `suprimentoCaixa`, `recebimentoCaixa`, `servicoCaixa`, `ordemPagamento`, `pagamentoCaixa`, `fundoCaixaCredito`, `consolidado`, etc.

Uso no produto: colunas **esperado/apresentado** vs **apurado** da conferência (alinhado às imagens em `docs/referencias/`).

### Apoio (segunda onda dentro do MVP dos postos)

| Rota | Para quê |
|------|----------|
| `GET /INTEGRACAO/V1/MOVIMENTACOES_CAIXA` | Suprimento, despesa, recebimento, troco, etc. (filtro `caixaCodigo`, `tipo`) |
| `GET /INTEGRACAO/V1/SANGRIAS_CAIXA` | Sangrias |
| `GET /INTEGRACAO/V1/VENDAS` | Vendas do período |
| `GET /INTEGRACAO/V1/VENDAS_FORMA_PAGAMENTO` | Formas de pagamento das vendas |
| `GET /INTEGRACAO/V1/VENDAS_RESUMO` | Resumo de vendas |
| `GET/POST /INTEGRACAO/V1/ARQUIVOS/...` | Anexos; tipos incluem `FECHAMENTO_CAIXA_APRESENTADO`, `DESPESA_FECHAMENTO_CAIXA`, `IMAGEM_PDV`, etc. |
| `GET /INTEGRACAO/V1/CARTOES` | Cartões / TEF por turno e empresa |
| `GET /INTEGRACAO/V1/DESPESAS_FINANCEIRO_REDE` | Despesas (flag `apuracaoCaixa`) |

## O que ignorar no MVP de conferência

Rotas de bomba/bico, frota, estoque físico, DRE, brindes, alteração de preço de combustível, etc. Continuam no OpenAPI para o posto, mas **não** entram na 1ª entrega de conferência.

## Encaixe com o nosso sistema

```text
EMPRESAS              → stores (postos)
CAIXAS                → lista / cabeçalho do fechamento
CAIXAS_APRESENTADO    → linhas apresentado × apurado × diferença
(nosso app/server)    → etapas Grupo Clara, permissões, auditoria, anexos extras
```

Conector previsto na modelagem: `webposto`.

## Como usar neste projeto

1. No WebPosto: Administração → Integrações → **API Integração** → copiar a chave.
2. Em `server/.env` (e `infra/.env.example` como modelo):

```env
WEBPOSTO_BASE_URL=https://web.qualityautomacao.com.br
WEBPOSTO_CHAVE=cole_a_chave_aqui
```

3. Reinicie a API (`dart run bin/server.dart`).
4. No app: **Caixas do dia** → **Sincronizar WebPosto** (data da barra superior).

Endpoints internos:
- `GET /webposto/status` — se a chave está configurada
- `POST /webposto/sync` — body `{ "date": "yyyy-MM-dd" }`
- `GET /closings?date=yyyy-MM-dd` — lista importada

## Pendências técnicas

- [x] Autenticação: query `chave=`
- [x] Guardar base URL + chave só em `.env`
- [ ] Validar com 1 posto real: sync do dia + conferência na UI
- [ ] Definir se a conferência humana ainda edita “conferido” ou só valida o `apurado` do WebPosto

## Histórico

| Data | Nota |
|------|------|
| 2026-11-03 | `api.json` movido para `docs/integracoes/webposto-openapi.json`; este resumo criado. |
