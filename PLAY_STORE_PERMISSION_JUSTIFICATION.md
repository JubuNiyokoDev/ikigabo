# Justification des Permissions - Ikigabo (Google Play Store)

**Application:** Ikigabo - Gestion de Patrimoine Personnel
**ID Package:** com.ikigabo.ikigabo
**Date:** 23 janvier 2026

---

## Permission: USE_FULL_SCREEN_INTENT

### Pourquoi cette permission est nécessaire

Ikigabo est une application de gestion financière personnelle qui aide les utilisateurs à suivre leurs dettes (dettes à payer et dettes à recevoir). La permission `USE_FULL_SCREEN_INTENT` est **essentielle** pour la fonctionnalité principale de rappel des dettes.

### Cas d'utilisation principal

1. **Gestion des Dettes Critiques**
   - Les utilisateurs créent des entrées pour les dettes qu'ils doivent rembourser ou qu'on leur doit
   - Ils peuvent programmer des alarmes de rappel pour ne pas manquer les dates de paiement importantes
   - Un oubli de remboursement peut entraîner des pénalités financières, des frais de retard ou des impacts négatifs sur les relations

2. **Pourquoi les alarmes système plutôt que les notifications simples**
   - **Criticité financière:** Les dettes impliquent des conséquences financières réelles (intérêts, pénalités)
   - **Fiabilité:** Les alarmes système sont plus visibles et ne peuvent pas être facilement ignorées comme une notification
   - **Importance temporelle:** Les dates de paiement de dettes sont fixes et non négociables
   - **Protection de l'utilisateur:** Éviter les oublis qui pourraient causer des dommages financiers

3. **Contrôle de l'utilisateur**
   - Les alarmes sont **uniquement** créées quand l'utilisateur le demande explicitement
   - L'utilisateur choisit la date et l'heure de chaque alarme
   - Aucune alarme automatique ou non sollicitée

### Implémentation technique

L'application utilise `AlarmClock.ACTION_SET_ALARM` pour créer des alarmes dans l'application Horloge système du téléphone. Voir le code source:

- **Fichier:** `android/app/src/main/kotlin/com/ikigabo/ikigabo/MainActivity.kt`
- **Méthode:** `setSystemAlarm()`
- **Permissions associées:**
  - `android.permission.SCHEDULE_EXACT_ALARM`
  - `com.android.alarm.permission.SET_ALARM`

### Documentation publique

Notre politique de confidentialité explique clairement cette utilisation:
**URL:** https://jubuniyokodev.github.io/ikigabo/privacy-policy.html
**Section:** "6. Permissions et Alarmes de Rappel"

Extrait:
> "Ikigabo utilise la permission 'USE_FULL_SCREEN_INTENT' pour fournir des alarmes de rappel critiques pour les dettes. Cette fonctionnalité est essentielle car la gestion des dettes nécessite des rappels opportuns pour éviter les pénalités de retard et maintenir de bonnes relations financières."

### Protection des données

- ✅ Aucune donnée personnelle n'est collectée via cette permission
- ✅ Application 100% offline - toutes les données restent sur l'appareil
- ✅ Aucune transmission de données à des serveurs externes
- ✅ L'utilisateur contrôle entièrement quand et comment les alarmes sont créées

### Conformité avec les politiques Google Play

Cette utilisation est conforme aux [Politiques de Permission Google Play](https://support.google.com/googleplay/android-developer/answer/9047303) car:

1. **Utilisation claire et évidente:** Les utilisateurs comprennent immédiatement pourquoi ils programment une alarme (rappel de dette)
2. **Fonctionnalité principale:** Le suivi et les rappels de dettes font partie intégrante de l'expérience utilisateur de gestion financière
3. **Transparence complète:** Documenté dans la politique de confidentialité et visible pour l'utilisateur
4. **Contrôle utilisateur:** Les utilisateurs initient toutes les alarmes

---

## Autres Permissions Utilisées

### SCHEDULE_EXACT_ALARM
Permet de programmer des alarmes précises à des heures spécifiques (nécessaire pour les rappels de dettes à l'heure exacte).

### com.android.alarm.permission.SET_ALARM
Permet à l'application d'interfacer avec l'application Horloge système pour créer des alarmes.

### POST_NOTIFICATIONS
Utilisée pour les notifications générales de l'application (non critiques).

---

## Contact pour Questions

**Développeur:** Joffre As Jubu Niyondiko (RundiNova)
**Email:** niyondikojoffreasjubu@gmail.com
**Téléphone:** +257 68 49 73 72
**GitHub:** https://github.com/JubuNiyokoDev/ikigabo

---

**Note pour l'équipe Google Play Review:**
Si vous avez des questions concernant cette justification ou souhaitez des démonstrations supplémentaires de cette fonctionnalité, n'hésitez pas à nous contacter directement. Nous sommes disponibles pour fournir des captures d'écran, des vidéos de démonstration, ou des explications supplémentaires.
