import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../services/transaction_provider.dart';
import '../screens/categories_screen.dart';
import '../screens/analytics_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  String? _username;
  String? _email;
  String? _photoUrl;
  Uint8List? _photoBytes; // Store photo as bytes

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final u = await _api.getUsername();
    final e = await _api.getEmail();
    final p = await _api.getProfilePhoto();
    print('DEBUG: Username: $u, Email: $e, PhotoURL: $p'); // Debug

    // Try to load photo from URL
    Uint8List? bytes;
    if (p != null && p.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(p));
        if (response.statusCode == 200) {
          bytes = response.bodyBytes;
          print(
            'DEBUG: Photo loaded successfully, size: ${bytes.length} bytes',
          );
        } else {
          print('DEBUG: Failed to load photo, status: ${response.statusCode}');
        }
      } catch (e) {
        print('DEBUG: Error loading photo: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _username = u ?? 'Pengguna';
      _email = e;
      _photoUrl = p;
      _photoBytes = bytes;
    });
  }

  Future<void> _editProfile() async {
    final usernameCtrl = TextEditingController(text: _username);
    Uint8List? pickedBytes;
    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final xfile = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 80,
                        );
                        if (xfile != null) {
                          pickedBytes = await xfile.readAsBytes();
                          setModalState(() {});
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pilih Foto'),
                    ),
                    const SizedBox(width: 12),
                    if (pickedBytes != null)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: MemoryImage(pickedBytes!),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = usernameCtrl.text.trim();
                          Navigator.of(ctx).pop();
                          final res = await _api.updateProfile(
                            newName,
                            pickedBytes,
                          );
                          if (!mounted) return;
                          if (res['status'] == 'success') {
                            await _loadProfile();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile diperbarui'),
                              ),
                            );
                          } else {
                            final msg =
                                res['message'] ?? 'Gagal memperbarui profile';
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    usernameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // User Profile Header (load username and email from secure storage)
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      backgroundImage: _photoBytes != null
                          ? MemoryImage(_photoBytes!)
                          : null,
                      child: _photoBytes == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _editProfile,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _username ?? 'Pengguna',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  _email ?? '${_username ?? 'pengguna'}@uangbro.app',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const SizedBox(height: 40),

          // Settings Section
          _buildSectionHeader(context, "Pengaturan"),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Reset Semua Data",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmReset(context),
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final api = ApiService();
              final provider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              final navigator = Navigator.of(context);
              await api.logout();
              // refresh transactions to show legacy only
              await provider.fetchTransactions();
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Kelola Kategori'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export CSV'),
            onTap: () {
              final provider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              final csv = provider.exportToCsv();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Export CSV'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(child: SelectableText(csv)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import CSV (Paste)'),
            onTap: () async {
              final controller = TextEditingController();
              await showDialog(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text('Import CSV'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: TextField(
                      controller: controller,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText: 'Paste CSV content here',
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dctx).pop(),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final csv = controller.text.trim();
                        if (csv.isNotEmpty) {
                          Navigator.of(dctx).pop();
                          final provider = Provider.of<TransactionProvider>(
                            context,
                            listen: false,
                          );
                          final messenger = ScaffoldMessenger.of(context);
                          final imported = await provider.importFromCsv(csv);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Imported $imported rows')),
                          );
                        }
                      },
                      child: const Text('Import'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('Analitik'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Ubah Password'),
            onTap: () => _showResetPasswordDialog(context),
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, "Tentang Aplikasi"),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Versi Aplikasi"),
            trailing: Text("1.0.0"),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text("Dibuat dengan Flutter"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Data?"),
        content: const Text(
          "Semua data transaksi akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              final messenger = ScaffoldMessenger.of(context);
              await provider.resetData();
              messenger.showSnackBar(
                const SnackBar(content: Text('Semua data berhasil dihapus')),
              );
            },
            child: const Text("Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final usernameCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNewPass = true;
    bool obscureConfirmPass = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ubah Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: obscureNewPass,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewPass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureNewPass = !obscureNewPass;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: obscureConfirmPass,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPass = !obscureConfirmPass;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = usernameCtrl.text.trim();
                final newPass = newPassCtrl.text;
                final confirmPass = confirmPassCtrl.text;

                if (username.isEmpty ||
                    newPass.isEmpty ||
                    confirmPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field wajib diisi')),
                  );
                  return;
                }

                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password minimal 6 karakter'),
                    ),
                  );
                  return;
                }

                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password tidak cocok')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                final messenger = ScaffoldMessenger.of(context);
                final result = await _api.resetPassword(username, newPass);
                if (result['status'] == 'success') {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Password berhasil diubah',
                      ),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Gagal mengubah password',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
