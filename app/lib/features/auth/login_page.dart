import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import 'auth_controller.dart';

/// Tela de login.
/// ConsumerStatefulWidget = tem estado próprio (_obscure, controllers) + Riverpod.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Controles dos campos de texto
  final _email = TextEditingController();
  final _password = TextEditingController();
  // Chave para validar o Form inteiro
  final _formKey = GlobalKey<FormState>();
  // true = senha escondida (bolinhas)
  bool _obscure = true;

  @override
  void dispose() {
    // Libera controllers quando a tela some (evita vazamento de memória)
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    // validate() roda os validators; se falhar, para aqui
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Pede login ao controller (não fala com a API direto)
    ref.read(authControllerProvider.notifier).login(
          _email.text.trim(),
          _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    // watch = se AuthState mudar, redesenha (erro, busy, etc.)
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Em tela baixa, permite rolar
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // não estica demais
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Conferência de Caixas',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Entre com sua conta para continuar',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 28),
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // largura total
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'E-mail'),
                          // null = ok; String = mensagem de erro
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          onFieldSubmitted: (_) => _submit(), // Enter envia
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            suffixIcon: IconButton(
                              icon: Icon(
                                // ternário: ícone conforme _obscure
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              // setState = muda estado local e redesenha
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Informe a senha' : null,
                        ),
                        // Só mostra a caixa vermelha se houver erro
                        if (auth.error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              auth.error!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          // busy → botão desabilitado (onPressed null)
                          onPressed: auth.busy ? null : _submit,
                          child: auth.busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
