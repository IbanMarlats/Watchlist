import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../widgets/clapperboard_header.dart';

class SettingsPage extends StatefulWidget {
  final List<Movie> movies;
  final Color currentAccentColor;
  final Function(Color)? onAccentColorChanged;
  final VoidCallback onResetData;
  final VoidCallback? onBack;
  final String tmdbApiKey;
  final Function(String) onApiKeyChanged;

  const SettingsPage({
    super.key,
    required this.movies,
    this.currentAccentColor = Colors.white,
    this.onAccentColorChanged,
    required this.onResetData,
    this.onBack,
    this.tmdbApiKey = '',
    required this.onApiKeyChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _obscureApiKey = true;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.tmdbApiKey);
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbApiKey != widget.tmdbApiKey && _apiKeyController.text != widget.tmdbApiKey) {
      _apiKeyController.text = widget.tmdbApiKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWatchlist = widget.movies.where((m) => m.status != 'none').length;
    final totalCompleted = widget.movies.where((m) => m.status == 'completed').length;
    final totalWatchLater = widget.movies.where((m) => m.status == 'watch_later').length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ClapperboardHeader(
              title: 'Paramètres ⚙️',
              subtitle: 'Configuration et gestion des données',
              showSettings: false,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: widget.onBack,
                    )
                  : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Utilisateur',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$totalWatchlist film${totalWatchlist > 1 ? 's' : ''} dans la collection',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('✅ $totalCompleted vus', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('⏳ $totalWatchLater à voir', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionHeader('API TMDB (The Movie Database) 🎬'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Clé API TMDB (v3 API Key) :',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (widget.tmdbApiKey.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Active',
                                        style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _apiKeyController,
                            obscureText: _obscureApiKey,
                            style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 1.2),
                            decoration: InputDecoration(
                              hintText: 'Coller votre clé API TMDB ici...',
                              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12, letterSpacing: 0),
                              filled: true,
                              fillColor: const Color(0xFF12121D),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _obscureApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: Colors.grey[400],
                                      size: 18,
                                    ),
                                    tooltip: _obscureApiKey ? 'Afficher la clé' : 'Masquer la clé',
                                    onPressed: () {
                                      setState(() {
                                        _obscureApiKey = !_obscureApiKey;
                                      });
                                    },
                                  ),
                                  if (_apiKeyController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                                      tooltip: 'Effacer',
                                      onPressed: () {
                                        setState(() {
                                          _apiKeyController.clear();
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              widget.onApiKeyChanged(_apiKeyController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Clé API TMDB enregistrée ! 🎬'),
                                  backgroundColor: Color(0xFF161722),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.black),
                            label: const Text('Enregistrer la clé API', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.help_outline_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Comment obtenir votre clé gratuite ?',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '1. Allez sur themoviedb.org/signup et créez un compte.\n'
                                  '2. Dans Paramètres > API, demandez une clé API gratuite (v3 API Key).\n'
                                  '3. Copiez la clé et collez-la ci-dessus !',
                                  style: TextStyle(color: Colors.grey[300], fontSize: 11, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF90CEA1), Color(0xFF01B4E4)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TMDB',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Gestion des données'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.download_rounded, color: Colors.white),
                            title: const Text('Exporter ma Watchlist', style: TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text('Sauvegarder ma liste au format JSON', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Données exportées (Simulé)')),
                              );
                            },
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          ListTile(
                            leading: const Icon(Icons.refresh_rounded, color: Colors.grey),
                            title: const Text('Réinitialiser les démos', style: TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text('Restaurer la liste initiale de films de démonstration', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            onTap: () {
                              widget.onResetData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Liste réinitialisée avec succès !'), backgroundColor: Color(0xFF161722)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.movie_creation_outlined, size: 36, color: Colors.white),
                          SizedBox(height: 6),
                          Text('Watchlist App • Version 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          SizedBox(height: 2),
                          Text('Développé avec Flutter 💙', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
