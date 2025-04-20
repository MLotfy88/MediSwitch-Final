from django.contrib import admin
# Import Drug model
from .models import ActiveDataFile, AdMobConfig, GeneralConfig, Drug

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

# Register Drug model
@admin.register(Drug)
class DrugAdmin(admin.ModelAdmin):
    list_display = ('trade_name', 'arabic_name', 'price', 'old_price', 'company', 'main_category', 'updated_at')
    search_fields = ('trade_name', 'arabic_name', 'active_ingredients', 'company')
    list_filter = ('main_category', 'company', 'dosage_form', 'last_price_update')
    readonly_fields = ('created_at', 'updated_at')
    # Consider adding list_editable for 'price' later if needed, but start without it.
    # list_editable = ('price',)
    fieldsets = (
        (None, {
            'fields': ('trade_name', 'arabic_name', 'price', 'old_price', 'last_price_update')
        }),
        ('Categorization', {
            'fields': ('main_category', 'main_category_ar', 'category', 'category_ar')
        }),
        ('Details', {
            'fields': ('active_ingredients', 'company', 'dosage_form', 'dosage_form_ar', 'unit', 'usage', 'usage_ar', 'description')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',) # Keep timestamps collapsed by default
        }),
    )