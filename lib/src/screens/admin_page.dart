import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/catalog_item.dart';
import '../services/catalog_service.dart';
import '../supabase_client.dart';
import '../widgets/mirrify_logo.dart';
import 'login_page.dart';

/// A página de Administrador só é acessível para o e-mail admin cadastrado.
/// Usuários comuns nunca chegam até aqui (a AppBar do SimulatorPage
/// já esconde o botão para quem não é admin).
class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final CatalogService _catalogService = CatalogService();

  static const String _adminEmail = 'manucatarinavs2@gmail.com';

  bool get _isAdmin {
    final email = SupabaseService.currentUser?.email ?? '';
    return email.trim().toLowerCase() == _adminEmail.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _catalogService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _catalogService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() => setState(() {});

  void _showItemDialog([CatalogItem? existingItem]) {
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final imageCtrl = TextEditingController(text: existingItem?.imageUrl ?? '');
    final descCtrl = TextEditingController(text: existingItem?.description ?? '');
    String selectedCat = existingItem?.category ?? 'Maquiagem';

    final categories = ['Maquiagem', 'Cores de Cabelo', 'Cortes', 'Penteados'];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(
                  existingItem == null ? Icons.add_circle_outline_rounded : Icons.edit_note_rounded,
                  color: AppPalette.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    existingItem == null ? 'Cadastrar Visual' : 'Editar Visual',
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
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedCat,
                        decoration: const InputDecoration(labelText: 'Categoria'),
                        items: categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCat = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'URL da Imagem',
                          hintText: 'https://...',
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Informe a URL' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descrição (opcional)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  if (existingItem == null) {
                    _catalogService.addItem(
                      name: nameCtrl.text.trim(),
                      category: selectedCat,
                      imageUrl: imageCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                  } else {
                    _catalogService.updateItem(
                      id: existingItem.id,
                      name: nameCtrl.text.trim(),
                      category: selectedCat,
                      imageUrl: imageCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                  }
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppPalette.secondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: Text(
                        existingItem == null
                            ? 'Visual cadastrado com sucesso!'
                            : 'Visual atualizado com sucesso!',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(existingItem == null ? 'Cadastrar' : 'Salvar'),
              ),
            ],
          );
        });
      },
    );
  }

  void _confirmDelete(CatalogItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Visual'),
        content: Text('Deseja excluir "${item.name}" do catálogo? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              _catalogService.deleteItem(item.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Visual excluído do catálogo.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
    // Barreira de segurança: se não for admin, mostra tela de acesso negado
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C2448),
                    ),
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
            Text(
              'Administrador',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF2C2448),
              ),
            ),
          ],
        ),
        actions: [
          // Logout diretamente do painel Admin
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
        label: Text(
          'Novo Visual',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildAdminDashboard() {
    final items = _catalogService.items;
    final userEmail = SupabaseService.currentUser?.email ?? '';

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
                        'Olá, Administradora!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Admin',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Métricas
          Row(
            children: [
              _buildMetricCard('Total', '${items.length}', Icons.collections_rounded, AppPalette.periwinkle),
              const SizedBox(width: 12),
              _buildMetricCard('Salvos', '${_catalogService.savedGallery.length}', Icons.favorite_rounded, const Color(0xFFE91E63)),
              const SizedBox(width: 12),
              _buildMetricCard('Categorias', '4', Icons.category_rounded, AppPalette.violet),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Catálogo de Visuais',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C2448),
            ),
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
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: AppPalette.mint,
                        child: const Icon(Icons.image, size: 26),
                      ),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    item.category,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppPalette.violet),
                  ),
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
          const SizedBox(height: 80), // Espaço para o FAB
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
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2C2448),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppPalette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
