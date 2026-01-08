import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

class AlarmScreen extends StatefulWidget {
  final String title;
  final String body;
  final int debtId;

  const AlarmScreen({
    super.key,
    required this.title,
    required this.body,
    required this.debtId,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _playAlarmSound();
  }

  Future<void> _playAlarmSound() async {
    try {
      // Jouer le son d'alarme système en boucle
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0); // Volume maximum

      // Utiliser le son de notification par défaut
      // Note: Pour un vrai son d'alarme, il faudrait ajouter un fichier audio
      await _audioPlayer.play(AssetSource('audio/alarm.mp3'));
    } catch (e) {
      print('Erreur lecture son alarme: $e');
      // Si le son échoue, au moins afficher l'écran
    }
  }

  void _stopAlarm() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _animationController.dispose();
    Navigator.of(context).pop();
  }

  void _snoozeAlarm() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _animationController.dispose();
    // TODO: Reprogrammer l'alarme dans 5 minutes
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alarme reportée de 5 minutes'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Empêche de fermer avec le bouton retour
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.error.withValues(alpha: 0.3),
                AppColors.backgroundDark,
                AppColors.backgroundDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(),

                  // Icône d'alarme animée
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_animationController.value * 0.2),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            AppIcons.notification,
                            size: 60,
                            color: AppColors.error,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Titre de l'alarme
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Détails
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      widget.body,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondaryDark,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Heure actuelle
                  Text(
                    _getCurrentTime(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),

                  const Spacer(),

                  // Bouton Reporter
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _snoozeAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.calendar, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Reporter (5 min)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouton Arrêter
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _stopAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(AppIcons.close, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Arrêter l\'alarme',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
