export class WebpostoException extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.name = 'WebpostoException';
  }
}

export class WebpostoClient {
  constructor({ baseUrl, chave }) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.chave = chave;
    this.pageSize = 500;
  }

  async fetchAll(path, query = {}) {
    const all = [];
    let ultimoCodigo;

    for (;;) {
      const params = new URLSearchParams({
        chave: this.chave,
        limite: String(this.pageSize),
        ...query,
      });
      if (ultimoCodigo != null) params.set('ultimoCodigo', String(ultimoCodigo));

      const url = `${this.baseUrl}${path}?${params}`;
      const res = await fetch(url, { headers: { accept: 'application/json' } });
      if (!res.ok) {
        const body = await res.text();
        throw new WebpostoException(
          `WebPosto ${path} falhou (${res.status}): ${body}`,
          res.status,
        );
      }
      const body = await res.json();
      const resultados = body?.resultados;
      if (!Array.isArray(resultados) || resultados.length === 0) break;
      for (const item of resultados) {
        if (item && typeof item === 'object') all.push(item);
      }
      const next = body.ultimoCodigo;
      if (next == null || resultados.length < this.pageSize) break;
      ultimoCodigo = typeof next === 'number' ? next : Number.parseInt(String(next), 10);
      if (Number.isNaN(ultimoCodigo)) break;
    }
    return all;
  }

  empresas() {
    return this.fetchAll('/INTEGRACAO/V1/EMPRESAS');
  }

  caixas({ dataInicial, dataFinal, empresaCodigo }) {
    const q = { dataInicial, dataFinal };
    if (empresaCodigo != null) q.empresaCodigo = String(empresaCodigo);
    return this.fetchAll('/INTEGRACAO/V1/CAIXAS', q);
  }

  caixasApresentado({ dataInicial, dataFinal }) {
    return this.fetchAll('/INTEGRACAO/V1/CAIXAS_APRESENTADO', {
      dataInicial,
      dataFinal,
      tipoData: 'EMISSAO',
    });
  }

  vendas({ dataInicial, dataFinal, empresaCodigo }) {
    return this.fetchAll('/INTEGRACAO/V1/VENDAS', {
      dataInicial,
      dataFinal,
      empresaCodigo: String(empresaCodigo),
      situacao: 'T',
    });
  }

  vendasFormaPagamento({ dataInicial, dataFinal, empresaCodigo }) {
    return this.fetchAll('/INTEGRACAO/V1/VENDAS_FORMA_PAGAMENTO', {
      dataInicial,
      dataFinal,
      empresaCodigo: String(empresaCodigo),
      situacao: 'T',
    });
  }

  funcionarios(funcionarioCodigo) {
    const q = {};
    if (funcionarioCodigo != null) q.funcionarioCodigo = String(funcionarioCodigo);
    return this.fetchAll('/INTEGRACAO/V1/FUNCIONARIOS', q);
  }
}
