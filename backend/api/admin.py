from django.contrib import admin
from .models import ActiveDataFile, AdMobConfig, GeneralConfig # Import GeneralConfig

# Register your models here.

@admin.register(ActiveDataFile)
class ActiveDataFileAdmin(admin.ModelAdmin):
    list_display = ('file_name', 'file_type', 'version', 'uploaded_at')
    readonly_fields = ('uploaded_at', 'version') # Version is timestamp

@admin.register(AdMobConfig)
class AdMobConfigAdmin(admin.ModelAdmin):
    list_display = ('id', 'ads_enabled', 'last_updated')
    # Prevent adding more than one config instance through the admin
    def has_add_permission(self, request):
        # Check if an instance already exists
        return not AdMobConfig.objects.exists()

    # Optionally, prevent deletion as well
    # def has_delete_permission(self, request, obj=None):
    #     return False

    # Customize field display if needed
    # fields = ('ads_enabled', 'banner_ad_unit_id_android', ...)

@admin.register(GeneralConfig)
class GeneralConfigAdmin(admin.ModelAdmin):
    list_display = ('id', 'about_url', 'privacy_policy_url', 'terms_of_service_url', 'last_updated')
    # Prevent adding more than one config instance
    def has_add_permission(self, request):
        return not GeneralConfig.objects.exists()

    # Optionally, prevent deletion
    # def has_delete_permission(self, request, obj=None):
    #     return False