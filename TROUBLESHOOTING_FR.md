# 🔧 Guide de Dépannage - Waiting Room App

## ✅ L'application se lance maintenant !

Mais il reste deux problèmes à résoudre :

---

## 🗺️ Problème 1 : La localisation ne fonctionne pas

### **Causes possibles :**

1. **Les permissions ne sont pas accordées**
2. **Le GPS est désactivé sur l'émulateur**
3. **L'émulateur n'a pas de position GPS simulée**

### **Solutions :**

#### **Solution A : Vérifier les permissions dans l'app**
1. Lancez l'application
2. Quand vous ajoutez un client, l'app devrait demander la permission de localisation
3. Cliquez sur "Autoriser" ou "Allow"

#### **Solution B : Activer le GPS sur l'émulateur**
1. Dans l'émulateur Android, ouvrez **Settings** (Paramètres)
2. Allez dans **Location** (Localisation)
3. Activez **Use location** (Utiliser la localisation)

#### **Solution C : Définir une position GPS dans l'émulateur**
1. Ouvrez l'**Extended Controls** de l'émulateur (les 3 points `...`)
2. Allez dans **Location**
3. Entrez une latitude et longitude (par exemple : `48.8566, 2.3522` pour Paris)
4. Cliquez sur **Send**

#### **Solution D : Vérifier les logs**
Regardez dans la console Flutter pour ces messages :
```
📍 Checking location permission...
📍 Requesting location permission...
📍 Fetching current position...
✅ Location obtained: XX.XXXX, YY.YYYY
```

Si vous voyez :
```
⚠️ Location permission denied
⚠️ Location services are disabled
⚠️ Location fetch timed out
```

Cela indique le problème spécifique.

---

## 🗄️ Problème 2 : Les clients ne sont pas ajoutés/supprimés dans Supabase

### **Cause principale : Politiques RLS (Row Level Security) manquantes**

Supabase utilise RLS pour sécuriser les données. Sans les bonnes politiques, les opérations INSERT/DELETE échouent silencieusement.

### **Solution : Configurer Supabase**

#### **Étape 1 : Accéder à Supabase**
1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet
3. Cliquez sur **SQL Editor** dans le menu de gauche

#### **Étape 2 : Exécuter le script SQL**
1. Ouvrez le fichier `supabase_setup.sql` dans ce projet
2. Copiez tout le contenu
3. Collez-le dans l'éditeur SQL de Supabase
4. Cliquez sur **Run** (Exécuter)

#### **Étape 3 : Vérifier la configuration**
Après avoir exécuté le script, vérifiez :

1. **Table créée :**
   - Allez dans **Table Editor**
   - Vous devriez voir la table `clients`

2. **RLS activé :**
   - Cliquez sur la table `clients`
   - Allez dans l'onglet **Policies**
   - Vous devriez voir 4 politiques :
     - Allow anonymous read access
     - Allow anonymous insert access
     - Allow anonymous delete access
     - Allow anonymous update access

3. **Realtime activé :**
   - Allez dans **Database** > **Replication**
   - La table `clients` devrait être listée

#### **Étape 4 : Tester**
1. Relancez l'application Flutter
2. Ajoutez un client
3. Vérifiez dans la console Flutter :
   ```
   ➕ Inserting client to Supabase: [nom]
   ✅ Client inserted to Supabase successfully
   ```
4. Vérifiez dans Supabase Table Editor que le client apparaît

---

## 🔍 Vérification des logs

### **Logs attendus lors de l'ajout d'un client :**
```
📍 Getting location for new client...
📍 Checking location permission...
✅ Location obtained: 48.8566, 2.3522
➕ Inserting client to Supabase: John Doe
✅ Client inserted to Supabase successfully
✅ Client added to local list
```

### **Logs attendus lors de la suppression d'un client :**
```
🗑️ Removing client from Supabase: [id]
✅ Client removed from Supabase
✅ Client removed from local DB
✅ Client removed from UI
```

### **Logs d'erreur courants :**

#### **Erreur : "new row violates row-level security policy"**
➡️ **Solution :** Les politiques RLS ne sont pas configurées. Exécutez `supabase_setup.sql`

#### **Erreur : "relation 'public.clients' does not exist"**
➡️ **Solution :** La table n'existe pas. Exécutez `supabase_setup.sql`

#### **Erreur : "Location permission denied"**
➡️ **Solution :** Accordez les permissions de localisation dans l'app

#### **Erreur : "Location services are disabled"**
➡️ **Solution :** Activez le GPS dans les paramètres de l'émulateur

---

## 📱 Commandes utiles

### **Voir tous les logs en temps réel :**
```powershell
flutter run -d emulator-5554
```

### **Voir uniquement les logs de l'app :**
```powershell
adb logcat | Select-String -Pattern "flutter"
```

### **Nettoyer et reconstruire :**
```powershell
flutter clean
flutter pub get
flutter run -d emulator-5554
```

---

## ✅ Checklist de vérification

- [ ] L'application se lance sans crash
- [ ] Supabase est configuré avec les politiques RLS
- [ ] La table `clients` existe dans Supabase
- [ ] Les permissions de localisation sont accordées
- [ ] Le GPS est activé sur l'émulateur
- [ ] Une position GPS est définie dans l'émulateur
- [ ] Les logs montrent "✅ Client inserted to Supabase successfully"
- [ ] Les clients apparaissent dans Supabase Table Editor
- [ ] La suppression fonctionne et les logs montrent "✅ Client removed from Supabase"

---

## 🆘 Besoin d'aide ?

Si les problèmes persistent, partagez :
1. Les logs de la console Flutter
2. Une capture d'écran de Supabase Table Editor
3. Une capture d'écran des politiques RLS dans Supabase

