from django.apps import AppConfig

class ApkUpdatesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.apk_updates'
    verbose_name = 'APK Updates'
    
    def ready(self):
        # Import signals or other initialization code here if needed
        pass
