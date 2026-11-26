import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../supabase_client.dart';
import '../widgets/mirrify_logo.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _supabase = Supabase.instance.client;

  bool _isAdmin = false;
  bool _isLoading = true;
  String _adminName = '';
  String _adminEmail = '';

  List<Map<String, dynamic>> _visuais = [];
  int _totalGaleria = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        setState(() { _isAdmin = false; _isLoading = false; });
        return;
      }

      // 1. Verifica se é admin e pega os dados do perfil
      final profile = await _supabase
          .from('profiles')
          .select('nome, email, tipo_usuario')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null || profile['tipo_usuario'] != 'administrador') {
        setState(() { _isAdmin = false; _isLoading = false; });
        return;
      }

      _adminName = profile['nome'] ?? 'Administrador';
      _adminEmail = profile['email'] ?? user.email ?? '';

      // 2. Busca os visuais ativos
      final visuaisResponse = await _supabase
          .from('visuais')
          .select()
          .eq('ativo', true)
          .order('created_at', ascending: false);
      
      // 3. Conta os itens na galeria
      final galeriaResponse = await _supabase
          .from('galeria')
          .select('id')
          .count();

      if (!mounted) return;
      setState(() {
        _isAdmin = true;
        _visuais = List<Map<String, dynamic>>.from(visuaisResponse);
        _totalGaleria = galeriaResponse.count;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() { _isAdmin = false; _isLoading = false; });
      _showSnack('Erro ao carregar dados: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : AppPalette.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg),
      ),
    );
  }

  void _showItemDialog([Map<String, dynamic>? existingItem]) async {
    final isEditing = existingItem != null;
    final nameCtrl = TextEditingController(text: existingItem?['nome'] ?? '');
    final imageCtrl = TextEditingController(text: existingItem?['imagem_url'] ?? '');
    final descCtrl = TextEditingController(text: existingItem?['descricao'] ?? '');
    String selectedCat = existingItem?['categoria'] ?? 'Maquiagem';

    final categories = ['Maquiagem', 'Cores de Cabelo', 'Cortes', 'Penteados'];
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded, color: AppPalette.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEditing ? 'Editar Visual' : 'Cadastrar Visual',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nome do Visual'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedCat,
                        decoration: const InputDecoration(labelText: 'Categoria'),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCat = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: imageCtrl,
                        decoration: const InputDecoration(labelText: 'URL da Imagem', hintText: 'https://...'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Informe a URL' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => isSaving = true);

                  try {
                    final data = {
                      'nome': nameCtrl.text.trim(),
                      'categoria': selectedCat,
                      'imagem_url': imageCtrl.text.trim(),
                      'descricao': descCtrl.text.trim(),
                      'ativo': true,
                    };

                    if (isEditing) {
                      await _supabase.from('visuais').update(data).eq('id', existingItem['id']);
                    } else {
                      await _supabase.from('visuais').insert(data);
                    }

                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    _showSnack(isEditing ? 'Visual atualizado com sucesso!' : 'Visual cadastrado com sucesso!');
                    _loadAdminData(); // Recarrega a lista
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    _showSnack('Erro ao salvar: $e', isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEditing ? 'Salvar' : 'Cadastrar'),
              ),
            ],
          );
        });
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Visual'),
        content: Text('Deseja excluir "${item['nome']}" do catálogo? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                // Aqui fazemos um Soft Delete (apenas inativamos o item) 
                // ou você pode usar .delete() para apagar de vez.
                await _supabase.from('visuais').update({'ativo': false}).eq('id', item['id']);
                _showSnack('Visual excluído do catálogo.');
                _loadAdminData();
              } catch (e) {
                _showSnack('Erro ao excluir: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Barreira de segurança
    if (!_isAdmin) {
      return Scaffold(
        body: MirrifyBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block_rounded, size: 72, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Acesso Negado',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF2C2448)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta área é exclusiva para administradores da Lumière Cosméticos.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppPalette.textMuted),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2448),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: AppPalette.secondary),
            const SizedBox(width: 8),
            Text('Administrador', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await SupabaseService.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sair'),
            style: TextButton.styleFrom(foregroundColor: AppPalette.textMuted),
          ),
        ],
      ),
      body: _buildAdminDashboard(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        backgroundColor: AppPalette.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Novo Visual', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boas vindas Admin
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppPalette.brandGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, color: AppPalette.secondary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $_adminName!',
                        style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        _adminEmail,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                  child: Text('Admin', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Métricas
          Row(
            children: [
              _buildMetricCard('Total', '${_visuais.length}', Icons.collections_rounded, AppPalette.periwinkle),
              const SizedBox(width: 12),
              _buildMetricCard('Salvos', '$_totalGaleria', Icons.favorite_rounded, const Color(0xFFE91E63)),
              const SizedBox(width: 12),
              _buildMetricCard('Categorias', '4', Icons.category_rounded, AppPalette.violet),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Catálogo de Visuais',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF2C2448)),
          ),
          Text(
            'Gerencie os visuais disponíveis no Espelho Inteligente (RF04)',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),

          // Lista do catálogo
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5DEFA)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: _visuais.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Nenhum visual cadastrado ainda.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _visuais.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _visuais[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item['imagem_url'] ?? '',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52, height: 52, color: AppPalette.mint,
                            child: const Icon(Icons.image, size: 26),
                          ),
                        ),
                      ),
                      title: Text(item['nome'] ?? 'Sem nome', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      subtitle: Text(item['categoria'] ?? 'Sem categoria', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppPalette.violet)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppPalette.periwinkle, size: 20),
                            tooltip: 'Editar',
                            onPressed: () => _showItemDialog(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            tooltip: 'Excluir',
                            onPressed: () => _confirmDelete(item),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5DEFA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF2C2448))),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppPalette.textMuted)),
          ],
        ),
      ),
    );
  }
}