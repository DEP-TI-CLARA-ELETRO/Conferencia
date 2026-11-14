import { spawn } from 'node:child_process';
import fs from 'node:fs/promises';
import { config } from '../config.js';
import { parseCouponText } from './couponOcrParser.js';

async function runVision(imagePath) {
  if (!config.googleVisionApiKey) {
    return { engine: 'vision', error: 'GOOGLE_VISION_API_KEY vazia', parsed: {} };
  }
  try {
    const bytes = await fs.readFile(imagePath);
    const content = bytes.toString('base64');
    const url = `https://vision.googleapis.com/v1/images:annotate?key=${config.googleVisionApiKey}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        requests: [
          {
            image: { content },
            features: [{ type: 'DOCUMENT_TEXT_DETECTION' }],
          },
        ],
      }),
    });
    if (!res.ok) {
      return {
        engine: 'vision',
        error: `Vision HTTP ${res.status}`,
        parsed: {},
      };
    }
    const json = await res.json();
    const text =
      json?.responses?.[0]?.fullTextAnnotation?.text ||
      json?.responses?.[0]?.textAnnotations?.[0]?.description ||
      '';
    return {
      engine: 'vision',
      rawText: text || null,
      parsed: text ? parseCouponText(text) : {},
      confidence: text ? 0.8 : null,
      error: text ? null : 'Sem texto',
    };
  } catch (err) {
    return { engine: 'vision', error: String(err.message || err), parsed: {} };
  }
}

function runTesseract(imagePath) {
  return new Promise((resolve) => {
    const args = [imagePath, 'stdout', '-l', 'por+eng', '--psm', '6'];
    const env = { ...process.env };
    if (config.tessdataPrefix) env.TESSDATA_PREFIX = config.tessdataPrefix;
    const child = spawn(config.tesseractBin, args, { env });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (d) => {
      stdout += d.toString();
    });
    child.stderr.on('data', (d) => {
      stderr += d.toString();
    });
    child.on('error', (err) => {
      resolve({
        engine: 'tesseract',
        error: String(err.message || err),
        parsed: {},
      });
    });
    child.on('close', (code) => {
      if (code !== 0 && !stdout.trim()) {
        resolve({
          engine: 'tesseract',
          error: stderr.trim() || `exit ${code}`,
          parsed: {},
        });
        return;
      }
      const text = stdout.trim();
      resolve({
        engine: 'tesseract',
        rawText: text || null,
        parsed: text ? parseCouponText(text) : {},
        confidence: text ? 0.6 : null,
        error: text ? null : stderr.trim() || 'Sem texto',
      });
    });
  });
}

/**
 * Cruza os motores: Vision tem prioridade; Tesseract preenche chaves que faltaram.
 * Se ambos leram a mesma chave com diferença relevante, mantém Vision e anota.
 */
function fuse(runs) {
  const byEngine = Object.fromEntries(runs.map((r) => [r.engine, r.parsed || {}]));
  const vision = byEngine.vision || {};
  const tesseract = byEngine.tesseract || {};
  const out = { ...tesseract, ...vision };
  const conflicts = [];
  for (const [k, v] of Object.entries(vision)) {
    const t = tesseract[k];
    if (typeof t === 'number' && Math.abs(t - v) >= 0.02) {
      conflicts.push(`${k}: vision=${v} tess=${t}`);
    }
  }
  return { proposed: out, conflicts };
}

export async function runDualOcr(imagePath) {
  const [vision, tesseract] = await Promise.all([
    runVision(imagePath),
    runTesseract(imagePath),
  ]);
  const runs = [vision, tesseract];
  const { proposed, conflicts } = fuse(runs);
  const ok = Object.keys(proposed).length > 0;
  const engineErrors = runs.map((r) => r.error).filter(Boolean);
  const hadText = runs.some((r) => Boolean(r.rawText && r.rawText.trim()));
  let warning = null;
  if (!ok && hadText) {
    warning =
      'OCR leu o cupom, mas não identificou formas de pagamento conhecidas' +
      (engineErrors.length ? ` (${engineErrors.join('; ')})` : '');
  } else if (!ok) {
    warning = engineErrors.join('; ') || 'OCR sem valores';
  } else if (conflicts.length) {
    warning = `Cruzamento com divergência: ${conflicts.join(', ')}`;
  } else if (engineErrors.length) {
    warning = `OCR parcial (${engineErrors.join('; ')})`;
  }
  return { runs, proposed, warning, ok };
}
