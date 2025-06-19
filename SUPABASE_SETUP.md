# Configuration de la Base de Données Supabase

## ⚠️ Problème Détecté

Votre application essaie d'accéder à une table `collecte` qui n'existe pas encore dans votre base Supabase.

## 🔧 Solution : Créer les Tables Nécessaires

### 1. Connectez-vous à votre Dashboard Supabase
- Allez sur [supabase.com](https://supabase.com)
- Ouvrez votre projet

### 1.1. Si la table `collecte` existe déjà sans la colonne `hidden`
Exécutez cette requête pour ajouter la colonne manquante :

```sql
-- Ajouter la colonne hidden si elle n'existe pas
ALTER TABLE public.collecte 
ADD COLUMN IF NOT EXISTS hidden BOOLEAN DEFAULT false;

-- Créer un index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_collecte_hidden ON public.collecte(hidden);
```

### 2. Créer la Table `collecte` (si elle n'existe pas encore)
Dans l'onglet "SQL Editor", exécutez cette requête :

```sql
-- Créer la table collecte
CREATE TABLE public.collecte (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    date_collecte TIMESTAMP WITH TIME ZONE NOT NULL,
    type_dechet TEXT NOT NULL,
    adresse TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status TEXT DEFAULT 'En attente' CHECK (status IN ('En attente', 'En cours', 'Terminé', 'Annulé')),
    confirmation_utilisateur BOOLEAN DEFAULT false,
    hidden BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer un index pour les requêtes fréquentes
CREATE INDEX idx_collecte_user_id ON public.collecte(user_id);
CREATE INDEX idx_collecte_status ON public.collecte(status);
CREATE INDEX idx_collecte_date ON public.collecte(date_collecte);

-- Activer Row Level Security (RLS)
ALTER TABLE public.collecte ENABLE ROW LEVEL SECURITY;

-- Politique de sécurité : les utilisateurs ne peuvent voir que leurs propres collectes
CREATE POLICY "Users can view own collecte" ON public.collecte
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own collecte" ON public.collecte
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own collecte" ON public.collecte
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own collecte" ON public.collecte
    FOR DELETE USING (auth.uid() = user_id);
```

### 3. Vérifier la Table `utilisateurs`
Assurez-vous que cette table existe aussi :

```sql
-- Créer la table utilisateurs si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.utilisateurs (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nom TEXT NOT NULL,
    telephone TEXT,
    email TEXT NOT NULL,
    adresse TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activer RLS
ALTER TABLE public.utilisateurs ENABLE ROW LEVEL SECURITY;

-- Politiques de sécurité
CREATE POLICY "Users can view own profile" ON public.utilisateurs
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.utilisateurs
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.utilisateurs
    FOR INSERT WITH CHECK (auth.uid() = id);
```

### 4. Données de Test (Optionnel)
Pour tester l'application, vous pouvez ajouter quelques données d'exemple :

```sql
-- Remplacez 'YOUR_USER_ID' par l'ID d'un utilisateur existant
INSERT INTO public.collecte (user_id, date_collecte, type_dechet, adresse, status, confirmation_utilisateur) VALUES
('YOUR_USER_ID', NOW() + INTERVAL '1 day', 'Plastique', '123 Rue de Kinshasa', 'Terminé', false),
('YOUR_USER_ID', NOW() + INTERVAL '3 days', 'Papier', '456 Avenue Lumumba', 'En attente', false),
('YOUR_USER_ID', NOW() - INTERVAL '2 days', 'Verre', '789 Boulevard Mobutu', 'Terminé', true);
```

## 🚀 Après Configuration

Une fois les tables créées :

1. **Redémarrez l'application** Flutter
2. **Testez la connexion** - les erreurs de base de données devraient disparaître
3. **Vérifiez les fonctionnalités** :
   - Affichage des statistiques
   - Section "Prochaine collecte"
   - Navigation vers les autres pages

## 📝 Mode Démo Actuel

En attendant la configuration de la base, l'application fonctionne en **mode démo** avec :
- ✅ Statistiques fictives (5 total, 2 en attente, 3 terminées)
- ✅ Collecte de démonstration (Plastique, demain)
- ✅ Messages d'information au lieu d'erreurs

## 🔍 Vérification

Pour vérifier que tout fonctionne :

```sql
-- Vérifier les tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Vérifier les données
SELECT * FROM public.collecte LIMIT 5;
```

## 🆘 Besoin d'Aide ?

Si vous rencontrez des problèmes :
1. Vérifiez que vous êtes connecté au bon projet Supabase
2. Assurez-vous que les variables d'environnement sont correctes
3. Consultez les logs Supabase dans le dashboard
4. Contactez le support Supabase si nécessaire

---

💡 **Tip** : Une fois la base configurée, vous pourrez profiter pleinement de toutes les fonctionnalités de votre application USAFICO !
