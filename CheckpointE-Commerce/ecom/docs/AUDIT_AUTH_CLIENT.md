# 🔐 Audit Auth Client — Inscription & Mot de passe oublié

**Périmètre :** authentification côté **client** (`/fr/client/...`) — inscription, login, vérification OTP, mot de passe oublié.
**Référence :** comparaison avec le flux **vendor** (`/fr/vendors/...`) qui fonctionne correctement.
**Date d'audit :** 2026-04-29
**Dernière mise à jour :** 2026-04-29

> ⚠️ **Contrainte produit (mise à jour 2026-04-29) :** côté client, **l'email est optionnel** (le user peut s'inscrire avec uniquement un téléphone). Donc **tout le flux de vérification et de reset doit fonctionner via SMS seul**. L'email reste un canal de secours **opportuniste** (envoyé en plus du SMS uniquement si le user en a renseigné un), jamais obligatoire ni primaire.

---

## 🎯 Avancement global

**Progression : `0%`**

```
[░░░░░░░░░░░░░░░░░░░░] 0 / 10 problèmes corrigés
```

| Catégorie | Bugs détectés | Corrigés | Progression |
|---|---|---|---|
| 🔴 Bloquants | 3 | 0 | 0% |
| 🟠 Majeurs | 4 | 0 | 0% |
| 🟡 Mineurs | 3 | 0 | 0% |
| **Total** | **10** | **0** | **0%** |

---

## 🔴 Bugs bloquants (impact direct utilisateur)

### B1 — `[ ]` Mot de passe oublié client : SMS uniquement, aucun fallback email — **0%**

**Fichiers :** [app/controllers/client/passwords_controller.rb:21-26](app/controllers/client/passwords_controller.rb#L21-L26)
**Symptôme :** En **dev**, si `SEND_SMS_ENABLED` n'est pas mis à `"true"` ou si le provider SMS (LAM/Orange) n'est pas configuré, **aucun lien n'est envoyé**, mais l'utilisateur voit quand même le message « Instructions envoyées ». En **prod**, si le provider SMS échoue (crédit épuisé, numéro invalide), l'utilisateur ne reçoit rien.

**Comparaison vendor :** `Vendors::PasswordsController#create` envoie un **email** via `Vendors::PasswordsMailer.reset(...).deliver_later`, qui fonctionne avec `letter_opener` en dev (la fenêtre s'ouvre dans le navigateur). ⚠️ **Ne pas répliquer tel quel côté client** : l'email est optionnel pour les clients, le canal **doit rester le SMS**.

**Reproduction :**
1. Aller sur `/fr/client/passwords/new`
2. Saisir un numéro existant
3. → message de succès affiché, mais aucun SMS reçu

**Correctif proposé (SMS d'abord) :**
- **Fiabiliser le SMS** : faire échouer explicitement le contrôleur si l'envoi SMS échoue (cf. B2), au lieu d'afficher un faux succès.
- **En dev**, si `SEND_SMS_ENABLED != "true"`, logger le `reset_url` (et/ou un OTP court) en gros dans la console + ajouter une bannière debug visible quand `Rails.env.development?` pour que le dev voie le lien sans avoir besoin du SMS réel.
- **Email opportuniste uniquement** : si et seulement si `user.email.present?`, envoyer aussi un email en parallèle (passer `send_email: user.email.present?` dans `Notifications::NotificationService.send_password_reset`). Ne **jamais** considérer l'email comme suffisant si le SMS a échoué pour un user sans email.
- Créer un `Client::PasswordsMailer.reset(user, token)` **uniquement** pour ce cas opportuniste (pas comme canal primaire).

---

### B2 — `[ ]` Le contrôleur `Client::PasswordsController#create` ne vérifie pas le résultat de l'envoi SMS — **0%**

**Fichiers :** [app/controllers/client/passwords_controller.rb:20-29](app/controllers/client/passwords_controller.rb#L20-L29)
**Symptôme :** `Notifications::NotificationService.send_password_reset` retourne un hash `{ sms: { success: false, reason: "sms_disabled" }, ... }`, mais le contrôleur ignore ce retour et redirige toujours vers `/fr/client/session/new` avec `notice: "...envoyées par SMS"`.

**Comparaison vendor :** même pattern (le vendor n'analyse pas non plus le retour de `deliver_later`), MAIS comme le canal est email et que `letter_opener` fonctionne en dev, le défaut est masqué.

**Correctif proposé (SMS = critère de succès) :**
```ruby
result = Notifications::NotificationService.send_password_reset(...)
sms_ok   = result[:sms]&.dig(:success)
email_ok = result[:email]&.dig(:success) # opportuniste, seulement si user.email.present?

# Le SMS est le canal primaire côté client : son échec = échec global,
# même si l'email a été envoyé (un user sans email ne le recevra pas du tout).
if sms_ok
  redirect_to new_client_session_path, notice: t(".sms_sent")
else
  redirect_to new_client_session_path, alert: t(".sms_failed_retry")
end
```

---

### B3 — `[ ]` Inscription client : OTP envoyé silencieusement perdu si SMS désactivé/HS — **0%**

**Fichiers :** [app/services/clients/registration_service.rb:84-94](app/services/clients/registration_service.rb#L84-L94), [app/services/otp/sender_service.rb:61-69](app/services/otp/sender_service.rb#L61-L69)
**Symptôme :** `Otp::SenderService.send_sms` rescue `SmsDisabledError` et **renvoie `true`** (mode simulation). Le `Clients::RegistrationService` considère donc l'envoi comme réussi et crée le `PendingRegistration`. L'utilisateur est redirigé vers la page OTP **sans avoir reçu de code** (sauf à lire la console serveur).

**Comparaison vendor :** même bug pour `Vendors::RegistrationService`, mais en dev les devs lisent le `puts` du contrôleur et le code OTP est imprimé en gros dans le terminal. Côté client, un `puts` similaire existe ([registration_service.rb:208-213](app/services/clients/registration_service.rb#L208-L213)).

**Correctif proposé (SMS obligatoire, email opportuniste) :**
- **En dev**, ajouter une bannière d'admin/debug avec le code OTP (et/ou logger en gros) pour ne pas dépendre d'un vrai envoi SMS.
- **En prod**, refuser de continuer si le SMS échoue (raise → rollback du `PendingRegistration`). Ne JAMAIS marquer un envoi simulé comme succès : `Otp::SenderService.send_sms` ne doit pas retourner `true` quand `SmsDisabledError` est levé en prod.
- **Email = bonus uniquement** : si `user.email.present?`, envoyer aussi l'OTP par email en parallèle. Mais pas comme « secours » qui débloquerait l'inscription d'un user n'ayant pas d'email — le SMS reste le critère de succès.

---

## 🟠 Bugs majeurs (impact UX / sécurité)

### M1 — `[ ]` Lien de reset envoyé par SMS = trop long → tarif multi-segments — **0%**

**Fichiers :** [app/services/notifications/password_reset_notification.rb:14-16](app/services/notifications/password_reset_notification.rb#L14-L16)
**Symptôme :** `sms_message` = `"Reset mdp: #{@reset_url} (15 min). Ignorez si non demandé."` avec `@reset_url` du type `https://aa.com/fr/client/passwords/<token-de-100+-chars>/edit` → SMS de **2 ou 3 segments** = ×2/×3 le coût + risque de troncature côté opérateur.

**Correctif proposé (le SMS reste le canal primaire) — flux à 3 étapes :**

| Étape | Route | Ce que voit le user | Ce que fait le serveur |
|---|---|---|---|
| **1. Identification** | `GET /fr/client/passwords/new` → `POST /fr/client/passwords` | Saisit son téléphone | Génère un OTP (6 chiffres), envoie SMS `"Code aa: 482913 (15 min). Ignorez si non demandé."` (1 segment), redirige vers étape 2 |
| **2. Vérification OTP** | `GET /fr/client/passwords/verify` → `POST /fr/client/passwords/verify` | Saisit les 6 chiffres reçus | Vérifie l'OTP. Si OK, génère un **`reset_token` signé court-vivant** (15 min, single-use, HMAC via `Rails.application.message_verifier(:client_password_reset)`) et redirige vers étape 3 avec le token en query string |
| **3. Nouveau mot de passe** | `GET /fr/client/passwords/edit?token=...` → `PATCH /fr/client/passwords` | Saisit + confirme son nouveau mot de passe | Vérifie le `reset_token` (signature + expiration + non-rejoué), `bcrypt`-hash le mdp, update le user, invalide le token, log out toutes les autres sessions, redirige vers `/fr/client/session/new` |

**Pourquoi 3 pages plutôt que 2 :**
- Sépare proprement la **preuve de possession du téléphone** (étape 2) de la **mise à jour du secret** (étape 3) → si l'OTP est mauvais, le user ne perd pas son nouveau mdp déjà tapé.
- Permet d'afficher des messages d'erreur ciblés (« Code invalide » vs « Mot de passe trop faible »).
- Le `reset_token` signé entre étapes 2 et 3 évite de garder un état serveur lourd : pas de table « pending_password_reset », juste un HMAC vérifiable.

**Pourquoi un OTP court plutôt qu'un long lien :**
- 1 segment SMS = ×1 le coût (vs ×2/×3 actuellement).
- Pas de troncature opérateur, pas de lien-suspect bloqué par certains SMS gateways africains.
- Expérience native déjà connue des clients (WhatsApp, Wave, Orange Money, MTN MoMo, Mixx by Yas).

**NB :** ne PAS basculer sur l'email comme canal primaire — l'email est optionnel côté client. Si `user.email.present?`, on peut envoyer l'OTP **en parallèle** par email (canal opportuniste), mais le SMS reste le critère de succès (cf. B1/B2).

---

### M2 — `[ ]` Inscription client : pas de `redirect_if_authenticated` — **0%**

**Fichiers :** [app/controllers/client/registrations_controller.rb:1-13](app/controllers/client/registrations_controller.rb#L1-L13)
**Symptôme :** Un client déjà connecté peut accéder à `/fr/client/registration/new` et soumettre une nouvelle inscription. Le vendor a `before_action :redirect_if_authenticated` ([vendors/registrations_controller.rb:4](app/controllers/vendors/registrations_controller.rb#L4)) qui empêche ce cas.

**Correctif proposé :**
```ruby
before_action :redirect_if_authenticated, only: [:new, :create]

def redirect_if_authenticated
  redirect_to client_dashboard_path if current_user
end
```

---

### M3 — `[ ]` Login client : session ouverte AVANT vérification du `verified?` — **0%**

**Fichiers :** [app/controllers/client/sessions_controller.rb:23-36](app/controllers/client/sessions_controller.rb#L23-L36)
**Symptôme :** `start_new_session_for(user)` est appelé **avant** le check `unless user.verified?`. Si le user ferme l'onglet, son cookie de session reste valide → il revient « connecté mais non vérifié », ce qui peut perturber l'app (panier accessible, etc.). Vendor a le même comportement, mais la redirection `new_vendors_verification_path` est plus stricte (génère un nouvel OTP à chaque login).

**Correctif proposé :**
- Soit ne pas appeler `start_new_session_for` si non vérifié (et créer un cookie temporaire `pending_verification_user_id`).
- Soit générer **systématiquement** un nouvel OTP au login si `!verified?` (comme vendor).

---

### M4 — `[ ]` Verification client après login : ne renvoie PAS de nouveau code — **0%**

**Fichiers :** [app/controllers/client/sessions_controller.rb:27-35](app/controllers/client/sessions_controller.rb#L27-L35)
**Symptôme :** Quand un user non vérifié se connecte, le contrôleur ne fait que rediriger vers `new_client_verification_path`. C'est le `VerificationsController#new` qui appelle `send_verification_code_if_needed` — qui ne renvoie un code QUE si aucun code actif n'existe.

**Comparaison vendor :** [vendors/sessions_controller.rb:37-78](app/controllers/vendors/sessions_controller.rb#L37-L78) génère et envoie systématiquement un nouveau code OTP au login (plus fiable).

**Correctif proposé :** harmoniser sur le pattern vendor — toujours générer un OTP frais au login si non vérifié.

---

## 🟡 Bugs mineurs (cohérence / UX fine)

### m1 — `[ ]` Password reset client : redirection finale sur `client_cart_path` — **0%**

**Fichiers :** [app/controllers/client/passwords_controller.rb:96-98](app/controllers/client/passwords_controller.rb#L96-L98)
**Symptôme :** Après reset, l'utilisateur est redirigé vers le panier. Le vendor va vers le dashboard, ce qui est plus naturel après une opération d'auth.

**Correctif proposé :** rediriger vers `client_dashboard_path` (ou utiliser `session[:return_to]` si présent).

---

### m2 — `[ ]` Vue `passwords/new.html.erb` client : plein de clés `t('client.passwords.new.email_label')` non utilisées — **0%**

**Fichiers :** [config/locales/fr/passwords.yml:46-50](config/locales/fr/passwords.yml#L46-L50)
**Symptôme :** La vue affiche `phone_label` / `phone_placeholder` (champ téléphone), mais le YAML contient aussi `email_label` / `email_placeholder` (résidu d'une version email). À nettoyer pour éviter la confusion.

**Correctif proposé :** retirer les clés email obsolètes du namespace `client.passwords.new` ou bien implémenter le double choix (téléphone OU email) au lieu d'un seul.

---

### m3 — `[ ]` Doublon de namespace `fr.clients.*` et `fr.client.*` — **0%**

**Fichiers :** [config/locales/fr/clients.yml:1-50](config/locales/fr/clients.yml#L1-L50)
**Symptôme :** Le YAML déclare à la fois `fr.clients.registration` (singulier, namespace `clients`) et `fr.client.registrations.new` (pluriel, namespace `client`). Seul le second est utilisé par les vues. Risque : un dev modifie la mauvaise clé et croit avoir fixé une traduction.

**Correctif proposé :** supprimer le namespace `fr.clients.*` mort (lignes 1-48 environ) après vérification globale (`grep -rn "I18n\.t.*clients\." app/`).

---

## 📋 Cheatsheet — différences client vs vendor

> ⚠️ Le tableau liste des **différences** d'implémentation, pas un objectif de convergence : le client doit rester **SMS-first** (email optionnel), le vendor reste **email-first**.

| Aspect | Client (à fiabiliser) | Vendor (OK) |
|---|---|---|
| Identifiant login | `phone_number + country_code` (email optionnel) | `email` |
| Canal mot de passe oublié | **SMS = primaire et obligatoire** (OTP court recommandé) | **Email** (`letter_opener` en dev ✅) |
| Mailer reset | ❌ pas de mailer — à créer **uniquement** pour l'envoi opportuniste si `user.email.present?` | ✅ `Vendors::PasswordsMailer.reset` |
| `redirect_if_authenticated` à l'inscription | ❌ absent (à ajouter) | ✅ présent |
| OTP régénéré au login si non vérifié | ❌ délégué à VerificationsController (à harmoniser) | ✅ inline dans SessionsController |
| Email en complément du SMS | ❌ aucun — à ajouter en **opportuniste** (`if user.email.present?`), jamais comme fallback critique | N/A (déjà email primaire) |

---

## 🛠️ Plan d'action recommandé (par priorité)

> 🎯 **Boussole :** le SMS doit être **fiable seul**. L'email s'ajoute uniquement si `user.email.present?`, jamais comme remplaçant.

1. **B2 + B3** ➜ **Fiabiliser l'envoi SMS** : `Otp::SenderService` et `Notifications::NotificationService` doivent renvoyer un statut clair, et les contrôleurs doivent échouer (alert + pas de redirection « succès ») si `result[:sms][:success] != true`. En dev, afficher l'OTP/le lien dans une bannière debug pour ne pas bloquer le développement.
2. **M1** ➜ **Passer à un OTP court** (6 chiffres) à la place du long lien dans le SMS, avec un **flux à 3 pages** (téléphone → OTP → nouveau mdp). 1 segment SMS, pas de troncature, expérience native pour les clients africains, et séparation propre entre vérification du téléphone et mise à jour du secret.
3. **B1** ➜ Une fois le SMS fiable, ajouter l'**envoi email opportuniste** (uniquement si `user.email.present?`) via un `Client::PasswordsMailer.reset` minimaliste. Petit PR, sans changer le critère de succès (qui reste le SMS).
4. **M3 + M4** ➜ Harmoniser le flux de login non-vérifié sur le pattern vendor (régénération OTP inline au login).
5. **M2** ➜ Ajouter `redirect_if_authenticated` sur `Client::RegistrationsController`.
6. **m1 / m2 / m3** ➜ Nettoyage final (redirection post-reset, clés i18n résiduelles, doublon de namespace).

---

## 📈 Suivi des mises à jour

| Date | Bug | Statut | PR | Notes |
|---|---|---|---|---|
| 2026-04-29 | — | Audit initial | — | 10 problèmes identifiés |
| 2026-04-29 | B1, B2, B3, M1 + cheatsheet + plan | Correctifs réalignés | — | Recadrage des correctifs : SMS = canal primaire et obligatoire côté client, email = bonus opportuniste (`if user.email.present?`). Plan d'action repriorisé : fiabiliser SMS d'abord, OTP court avant tout envoi email. |
| 2026-04-29 | M1 | Flux à 3 pages spécifié | — | Détail du flux mot de passe oublié : (1) saisie téléphone → SMS OTP, (2) vérification OTP → `reset_token` HMAC, (3) saisie nouveau mdp. Choix d'un OTP court 6 chiffres en remplacement du lien long actuel. |

> 💡 **Convention de mise à jour :** quand un bug est corrigé, cocher la case `[ ]` → `[x]`, passer le pourcentage à `100%`, recalculer la progression globale en haut, et ajouter une ligne au tableau de suivi avec la PR/commit.
