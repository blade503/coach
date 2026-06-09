# 🏋️ Mon coach perte de poids

Application web personnelle de suivi (poids, programme diététique, programme sportif, meal prep, tracker de séances gamifié, motivation). 100 % statique côté front, base de données et authentification gérées par **Supabase**, hébergement gratuit sur **GitHub Pages**, installable comme une **PWA** sur mobile.

> ⚠️ Cette app est un outil de suivi personnel, **pas un dispositif médical ni un substitut à un avis professionnel**. Pour une démarche de perte de poids, l'accompagnement d'un médecin ou d'un diététicien-nutritionniste est recommandé.

---

## ✨ Fonctionnalités

- **Suivi du poids** : saisie quotidienne, courbe d'évolution (Chart.js), IMC, progression vers l'objectif.
- **Programme diététique** : repère de cibles, idées de repas, liste d'aliments, boissons.
- **Programme sportif** : séances maison puis salle, semaine type, conseils de réveil.
- **Meal prep** : plats en batch avec quantités par portion.
- **Idées repas** : plats en rotation, assaisonnements, encas, compléments.
- **Tracker de séances gamifié** : XP, niveaux, série hebdomadaire, objectif, trophées, heatmap.
- **Motivation** : messages, habitudes quotidiennes.
- **Multi-appareils** : tout est synchronisé via le compte (ordinateur ↔ mobile).
- **PWA** : icône sur l'écran d'accueil, lancement plein écran, fonctionne hors-ligne.

## 🧱 Stack technique

| Couche | Techno |
| --- | --- |
| Front | HTML/CSS/JS « vanilla », un seul fichier `index.html` |
| Graphiques | [Chart.js](https://www.chartjs.org/) (CDN) |
| Base de données + Auth | [Supabase](https://supabase.com) (PostgreSQL + Auth, offre gratuite) |
| Hébergement | [GitHub Pages](https://pages.github.com/) |
| App mobile | PWA (`manifest.webmanifest` + service worker `sw.js`) |

Aucune étape de build, aucun framework : on édite des fichiers, on les pousse sur GitHub.

## 🗂️ Structure des fichiers

```
index.html              # toute l'app (UI + logique + intégration Supabase)
manifest.webmanifest    # métadonnées PWA (nom, icônes, couleurs)
sw.js                   # service worker (cache + hors-ligne)
icon-192.png            # icône PWA
icon-512.png            # icône PWA
apple-touch-icon.png    # icône iOS
schema.sql              # schéma de la base (à exécuter dans Supabase)
README.md               # ce fichier
```

## ⚙️ Architecture en bref

Le navigateur charge `index.html`, qui initialise le client `supabase-js` avec une **Project URL** et une **clé publishable** (publique, sûre côté navigateur tant que la RLS est active). L'utilisateur se connecte (email + mot de passe), puis l'app lit/écrit dans les tables `weights`, `habits`, `settings`, `workouts`. La **Row Level Security (RLS)** garantit que chaque utilisateur ne voit que ses propres lignes. Le service worker met en cache la coquille de l'app pour le hors-ligne ; les appels Supabase passent toujours par le réseau.

---

## 🚀 Reproduire le projet de zéro

### 1. Créer un projet Supabase
1. [supabase.com](https://supabase.com) → **New project**.
2. Choisir une région proche, noter le mot de passe de la base.
3. Attendre ~2 min la création.

### 2. Créer les tables
Dans Supabase → **SQL Editor** → **New query** → coller le contenu de `schema.sql` (ci-dessous) → **Run**. Vérifier dans **Table Editor** la présence de `weights`, `habits`, `settings`, `workouts`.

```sql
-- 1) Pesées
create table if not exists public.weights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date date not null,
  kg numeric(5,1) not null,
  created_at timestamptz default now(),
  unique (user_id, date)
);

-- 2) Habitudes quotidiennes
create table if not exists public.habits (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date date not null,
  data jsonb not null default '{}'::jsonb,
  primary key (user_id, date)
);

-- 3) Réglages
create table if not exists public.settings (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  target_weight numeric(5,1) default 95,
  start_weight numeric(5,1),
  workout_goal integer default 3
);
alter table public.settings add column if not exists workout_goal integer default 3;

-- 4) Séances de sport
create table if not exists public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date date not null,
  type text not null,
  morning boolean default false,
  created_at timestamptz default now()
);

-- Sécurité (RLS) : chacun ne voit que ses données
alter table public.weights  enable row level security;
alter table public.habits   enable row level security;
alter table public.settings enable row level security;
alter table public.workouts enable row level security;

drop policy if exists "own_weights"  on public.weights;
drop policy if exists "own_habits"    on public.habits;
drop policy if exists "own_settings"  on public.settings;
drop policy if exists "own_workouts"  on public.workouts;

create policy "own_weights"  on public.weights  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own_habits"   on public.habits   for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own_settings" on public.settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own_workouts" on public.workouts for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

### 3. Récupérer les clés
Supabase → ⚙️ **Project Settings** → **API** :
- **Project URL** (`https://<project-ref>.supabase.co`)
- **Publishable key** (`sb_publishable_...`) — sûre côté navigateur grâce à la RLS.

> Ne jamais exposer la clé `sb_secret_...` (accès privilégié, serveur uniquement).

### 4. Configurer `index.html`
En haut du `<script>` :
```js
const SUPABASE_URL      = "https://<project-ref>.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_xxxxxxxx"; // la clé publishable
```

### 5. Régler l'authentification
Supabase → **Authentication** → **Sign In / Providers** → **Email** :
- Désactiver **Confirm email** (connexion immédiate, usage perso).
- Après avoir créé ton compte (étape 7), désactiver **Allow new users to sign up** pour rester le seul utilisateur.

### 6. Publier sur GitHub Pages
1. Créer un dépôt (public conseillé ; les données ne sont pas dans le code).
2. Uploader : `index.html`, `manifest.webmanifest`, `sw.js`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`.
3. **Settings → Pages** → Source `Deploy from a branch`, branche `main`, dossier `/ (root)` → **Save**.
4. L'URL apparaît : `https://<pseudo>.github.io/<repo>/`.

### 7. Créer son compte
Ouvrir l'URL → **Créer mon compte** (email + mot de passe ≥ 8 caractères) → puis verrouiller les inscriptions (étape 5).

### 8. Installer sur mobile (PWA)
Ouvrir l'URL sur le téléphone → se connecter → **Installer l'application** (Android/Chrome) ou **Sur l'écran d'accueil** (iPhone/Safari).

---

## 🔄 Mises à jour

- **Pousser sur `main`** → GitHub Pages redéploie automatiquement (~1 min).
- **PWA** : le service worker fonctionne en « réseau d'abord », donc la version fraîche est récupérée à la prochaine ouverture en ligne — rien à réinstaller.
- Pour **forcer** un rafraîchissement sur tous les appareils (ex. après modification de `sw.js`), incrémenter `const CACHE = "coach-v1";` → `"coach-v2";`.

## 🔐 Sécurité

- La **clé publishable** est publique par conception ; sans connexion, **aucune donnée n'est lisible** (la RLS bloque tout côté serveur).
- Le HTML est public (si le dépôt l'est) ; **les données personnelles ne le sont jamais**.
- Une fois les inscriptions désactivées, un seul compte existe.
- La clé `sb_secret_...` ne doit **jamais** être mise dans le front.

## 🛠️ Personnalisation

- **Objectif de poids / séances** : modifiables dans l'app (stockés dans `settings`).
- **Contenu** (diète, sport, idées) : directement dans le HTML, sections par onglet.
- **Gamification** (XP, niveaux, trophées) : tableaux `XP_BY`, `LEVELS`, `BADGES` dans le `<script>`.

## 📜 Licence

Projet personnel. Réutilisation et adaptation libres pour un usage perso.
