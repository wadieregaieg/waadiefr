import 'package:freshk/extensions/localized_context.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({Key? key}) : super(key: key);

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
        title: Text(context.loc.supportCenterTitle,
            style: TextStyles.sectionHeader),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding),
        child: SingleChildScrollView(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Centre d'Assistance", style: TextStyles.sectionHeader),
              SizedBox(height: 16),

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
