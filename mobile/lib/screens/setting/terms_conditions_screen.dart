import 'package:freshk/extensions/localized_context.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.loc.termsAndConditionsTitle,
            style: TextStyles.sectionHeader),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding),
        child: SingleChildScrollView(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Termes et Conditions d'Utilisation",
                  style: TextStyles.sectionHeader),
              SizedBox(height: 20),

              // 1. Objet de la Plateforme
              Text("1. Objet de la Plateforme",
                  style: TextStyles.sectionHeader),
              SizedBox(height: 8),
              Text(
                "Freshk connecte les agriculteurs et coopératives avec les épiceries, restaurants et hôtels pour faciliter la commande et la livraison de produits frais en Tunisie.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 20),

              // 2. Comptes Utilisateurs
              Text("2. Comptes Utilisateurs", style: TextStyles.sectionHeader),
              SizedBox(height: 8),
              Text(
                "• Un seul compte est autorisé par entreprise.\n"
                "• La revente ou le partage du compte est strictement interdit.\n"
                "• En cas de fraude ou usage non conforme, le compte peut être suspendu immédiatement.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 20),

              // 3. Commandes & Paiement
              Text("3. Commandes & Paiement", style: TextStyles.sectionHeader),
              SizedBox(height: 8),
              Text(
                "• Les prix sont dynamiques (pilotés par IA) mais ne dépasseront jamais +15% du prix moyen du marché (source : Observatoire des Prix Agricoles).\n"
                "• Moyens de paiement : virement bancaire, e-Dinar, ou paiement à la livraison (clients vérifiés uniquement).\n"
                "• Agriculteurs : le paiement est effectué sous 48h maximum après livraison au hub.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 20),

              // 4. Livraison & Qualité
              Text("4. Livraison & Qualité", style: TextStyles.sectionHeader),
              SizedBox(height: 8),
              Text(
                "• Livraison assurée entre 6h00 et 11h00, du lundi au samedi.\n"
                "• En cas de défaut de qualité, vous avez 12h maximum pour signaler avec photo (WhatsApp ou app).\n"
                "• Nous proposons un remplacement gratuit ou un remboursement si le problème est confirmé.\n"
                "• Les pertes causées par une mauvaise manipulation après livraison ne sont pas couvertes.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 20),

              // 5. Données & Confidentialité
              Text("5. Données & Confidentialité",
                  style: TextStyles.sectionHeader),
              SizedBox(height: 8),
              Text(
                "• Conforme à la loi tunisienne 2004-63 sur la protection des données personnelles.\n"
                "• Les données sont hébergées localement en Tunisie.\n"
                "• Agriculteurs : partage de données anonymes autorisé uniquement avec votre consentement explicite (ex : Ministère de l'Agriculture).",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 20),

              // 6. Responsabilités
              Text("6. Responsabilités", style: TextStyles.sectionHeader),
              SizedBox(height: 8),
              Text(
                "• Les événements externes (intempéries, grèves, etc.) ne sont pas couverts.\n"
                "• En cas de litige, le tribunal de Sousse est compétent.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 20),

              // 7. Résiliation
              Text("7. Résiliation", style: TextStyles.sectionHeader),
              SizedBox(height: 8),
              Text(
                "• Freshk se réserve le droit de suspendre un compte en cas de retard de paiement supérieur à 14 jours ou en cas de fraude.\n"
                "• Agriculteurs : vous pouvez quitter la plateforme sans frais si paiement retardé > 48h.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 28),

              // Centre d'Assistance
              Text("Centre d'Assistance", style: TextStyles.sectionHeader),
              SizedBox(height: 12),

              // Comment passer une commande ?
              Text("Comment passer une commande ?",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Text(
                "• Sélectionnez vos produits et quantités dans l'app ou sur WhatsApp.\n"
                "• Choisissez votre heure de livraison.\n"
                "• Vous recevrez un récapitulatif par SMS.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 16),

              // Moyens de paiement
              Text("Moyens de paiement",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Text(
                "• Virement bancaire\n"
                "• e-Dinar\n"
                "• Paiement à la livraison (clients vérifiés)",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 16),

              // Horaires de livraison
              Text("Horaires de livraison",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Text(
                "• Du lundi au samedi\n"
                "• Entre 6h et 9h du matin\n"
                "• Suivi GPS de votre commande intégré à l'app",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 16),

              // Produit abîmé
              Text("Produit abîmé ?",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Text(
                "• Prenez une photo dans un délai de 12h.\n"
                "• Envoyez-la sur WhatsApp : +216 26 399 011\n"
                "• On vous propose un remplacement ou un remboursement.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 16),

              // Infos pour agriculteurs
              Text("Infos pour agriculteurs",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Text(
                "• Paiement dans les 48h après livraison au hub\n"
                "• Bonus de +5% si la qualité est notée > 90/100\n"
                "• Baisse de prix ? Consultez les prévisions dans l'app (ex. excès régional > 15%)",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 16),

              // Contact urgent
              Text("Contact urgent",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Text(
                "• WhatsApp : +216 26 399 011 (réponse < 1h)\n"
                "• Email : support@freshk.tn\n"
                "• Médiateur agricole (UTAP) : 71 123 456",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 16),

              // Données sécurité
              Text("Mes données sont-elles en sécurité ?",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Text(
                "Oui ! Conforme à la loi tunisienne 2004-63.\nAucune donnée n'est vendue à des tiers.",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 16),

              // Panne logistique
              Text("En cas de panne logistique",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Text(
                "• Vous recevez un SMS d'alerte immédiat\n"
                "• Votre commande est re-routée vers un autre hub (Tunis Nord ou Sud)\n"
                "• Vous bénéficiez de -20% sur votre prochaine commande",
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
