# NimbusShop — infrastructure Azure avec OpenTofu

Infrastructure Azure définie avec OpenTofu : un réseau à deux sous-réseaux,
deux VM web Linux sans IP publique, un Load Balancer Standard et une sonde HTTP.
Le niveau 2 ajoute un jumpbox avec SSH restreint à l'IP publique autorisée.
Le niveau 3 ajoute une alerte CPU Azure Monitor et un Key Vault contenant un
secret aléatoire.

## Pré-requis

- OpenTofu installé.
- Azure CLI installé et connecté avec `az login`.
- Une clé SSH existante; seul son chemin vers le fichier public `.pub` est utilisé.
- Le Resource Group `rg-nimbus-10` déjà créé.
- Le SKU de VM retenu pendant le TP, disponible dans la région `polandcentral`.

Le Resource Group existant est lu comme une donnée et n'est ni créé, ni modifié,
ni supprimé par OpenTofu. Les tags du groupe ne sont donc pas gérés par cette
configuration; les tags `projet`, `owner` et `env` sont appliqués aux ressources
Azure gérées par OpenTofu.

## Paramètres

Les valeurs propres à la machine et à l'abonnement sont fournies localement dans
`terraform.tfvars`, fichier ignoré par Git. Exemple :

```hcl
subscription_id     = "ID-GUID-DE-L-ABONNEMENT"
owner               = "nom-du-binome"
vm_size             = "SKU-RETENU-PENDANT-LE-TP"
ssh_public_key_path = "/chemin/vers/id_ed25519.pub"
allowed_ssh_ip      = "203.0.113.10/32"
alert_email         = "adresse@example.com"
```

Le numéro de groupe, le nom du Resource Group et la région sont initialisés aux
valeurs communiquées pour ce TP; ils restent surchargeables via le même fichier.
Si `subscription_id` est omis, le fournisseur Azure utilise l'abonnement actif
de `az login`.

Le fichier `.terraform.lock.hcl` est généré par `tofu init` et doit être conservé
dans le dépôt pour verrouiller la version du fournisseur.

## Déploiement

```sh
tofu init
tofu fmt -check
tofu validate
tofu plan
tofu apply
tofu output website_url
```

Le site affiche `NimbusShop` et le nom d'hôte de la VM qui a répondu. La sonde
du Load Balancer vérifie `GET /health`, qui renvoie `healthy`. La règle de
sortie explicite du Load Balancer fournit l'accès sortant aux VM web.

## Niveau 2 — administration

`allowed_ssh_ip` doit être l'IP publique actuelle du poste d'administration,
au format CIDR `/32`. Le jumpbox est la seule VM joignable en SSH depuis
Internet; les VM web n'acceptent SSH que depuis `snet-admin`.
Si l'IP publique change, mettre à jour cette variable et appliquer à nouveau
avant de tenter la connexion.

Après `tofu apply`, récupérer les adresses avec `tofu output jumpbox_public_ip`
et `tofu output web_vm_private_ips`, puis utiliser le transfert SSH :

```sh
ssh -i /chemin/vers/id_ed25519 -J azureuser@ADRESSE_PUBLIQUE_JUMPBOX azureuser@IP_PRIVEE_VM_WEB
```

Le nom d'utilisateur est `azureuser` par défaut. Adapter les chemins et adresses
à son environnement; ne jamais fournir ni versionner la clé privée.

## Niveau 3 — supervision et secrets

Une alerte Azure Monitor surveille séparément les deux VM web et envoie un
e-mail via un groupe d'actions si leur CPU moyen dépasse 80 % sur une fenêtre
de 5 minutes. L'évaluation a lieu chaque minute.

OpenTofu génère un mot de passe aléatoire et le stocke comme secret
`nimbus-generated-password` dans un Key Vault. La valeur n'est ni codée dans
les fichiers `.tf`, ni publiée en output. L'état OpenTofu contient cependant
la valeur du secret : conserver le fichier d'état privé et ne jamais le
versionner. Le Key Vault accorde à l'identité utilisée par `az login` les
permissions `Get`, `List` et `Set` sur les secrets.

Pour supprimer les ressources créées par OpenTofu :

```sh
tofu destroy
```

Le Resource Group préexistant est conservé. Ne jamais versionner l'état local,
les plans OpenTofu, `terraform.tfvars`, ni d'autres fichiers contenant des
valeurs personnelles.

## Dépôt Git

Initialiser le dépôt local et vérifier les fichiers avant chaque commit :

```sh
git init
git status --short
git add .gitignore .terraform.lock.hcl README.md cloud-init.yaml *.tf
git diff --cached --check
git status --short
```

Le dépôt doit contenir le code et `.terraform.lock.hcl`, mais pas `.terraform/`,
les fichiers `*.tfstate`, `*.tfvars`, les plans `*.tfplan`, ni des secrets.
Pour publier le projet en ligne, ajouter le dépôt distant fourni par le binôme
ou l'enseignant; aucune URL distante n'est configurée ici.

