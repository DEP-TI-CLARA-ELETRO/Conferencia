import '../../core/widgets/status_chip.dart';

/// Dados FICTÍCIOS usados só para validar o visual.
/// Depois serão substituídos por dados reais da API.

/// Status de exemplo de um caixa (com rótulo + cor do chip).
enum SampleStatus {
  concluido('Concluído', StatusTone.success),
  emConferencia('Em conferência', StatusTone.warning),
  divergencia('Divergência', StatusTone.danger),
  pendente('Pendente', StatusTone.neutral);

  const SampleStatus(this.label, this.tone);
  final String label;
  final StatusTone tone;
}

/// Um caixa do dia (versão de exemplo).
class ClosingSample {
  const ClosingSample({
    required this.register,
    required this.operator,
    required this.opened,
    required this.closed,
    required this.expected,
    required this.counted,
    required this.status,
  });

  final int register; // número do PDV/caixa
  final String operator; // operador
  final String opened; // horário abertura (texto)
  final String closed; // horário fechamento
  final double expected; // valor esperado (PDV)
  final double? counted; // valor conferido (null = ainda não conferiu)
  final SampleStatus status;

  /// Diferença = conferido - esperado (null se ainda não conferiu).
  double? get difference => counted == null ? null : counted! - expected;
}

/// Lista fixa de caixas de demonstração.
const closingSamples = <ClosingSample>[
  ClosingSample(register: 101, operator: 'Maria Silva', opened: '08:02', closed: '14:32', expected: 4265.80, counted: 4265.80, status: SampleStatus.concluido),
  ClosingSample(register: 102, operator: 'João Santos', opened: '08:10', closed: '15:10', expected: 3821.40, counted: 3821.40, status: SampleStatus.concluido),
  ClosingSample(register: 103, operator: 'Ana Costa', opened: '08:05', closed: '16:05', expected: 2985.60, counted: 3001.20, status: SampleStatus.concluido),
  ClosingSample(register: 104, operator: 'Lucas Ferreira', opened: '08:15', closed: '17:20', expected: 1754.30, counted: 1734.30, status: SampleStatus.divergencia),
  ClosingSample(register: 105, operator: 'Carla Mendes', opened: '08:00', closed: '18:05', expected: 3110.90, counted: null, status: SampleStatus.pendente),
  ClosingSample(register: 106, operator: 'Pedro Alves', opened: '08:12', closed: '18:30', expected: 2420.00, counted: 2420.00, status: SampleStatus.concluido),
  ClosingSample(register: 107, operator: 'Juliana Lima', opened: '08:08', closed: '14:50', expected: 1980.20, counted: 1980.20, status: SampleStatus.concluido),
  ClosingSample(register: 108, operator: 'Rafael Souza', opened: '08:20', closed: '15:40', expected: 2234.10, counted: null, status: SampleStatus.emConferencia),
];
