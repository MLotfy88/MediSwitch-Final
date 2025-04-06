from django.db import models
import time

class ActiveDataFile(models.Model):
    """
    Represents the currently active data file (CSV or XLSX)
    uploaded by the admin. Ensures only one record exists.
    """
    file_name = models.CharField(max_length=255, unique=True)
    file_type = models.CharField(max_length=10, choices=[('csv', 'CSV'), ('xlsx', 'XLSX')])
    # Use timestamp as version for simplicity, matching current version logic
    version = models.BigIntegerField(unique=True, help_text="Unix timestamp of upload time")
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.file_name} (Version: {self.version})"

    @classmethod
    def update_active_file(cls, file_name, file_type):
        """
        Deletes any existing records and creates a new one for the
        currently active file.
        """
        cls.objects.all().delete() # Ensure only one record exists
        current_timestamp = int(time.time())
        instance = cls.objects.create(
            file_name=file_name,
            file_type=file_type,
            version=current_timestamp
        )
        return instance

    @classmethod
    def get_active_file_info(cls):
        """
        Retrieves the information of the single active data file.
        Returns None if no file has been uploaded yet.
        """
        try:
            return cls.objects.get() # Should only be one record
        except cls.DoesNotExist:
            return None
        except cls.MultipleObjectsReturned:
            # This shouldn't happen with the update_active_file logic,
            # but handle defensively. Maybe delete all but the latest?
            # For now, just return the latest one based on timestamp.
            print("Warning: Multiple ActiveDataFile records found. Returning the latest.")
            return cls.objects.order_by('-version').first()
# Model to store AdMob configuration
class AdMobConfig(models.Model):
    # Use a singleton pattern approach: only one row should exist
    # We can enforce this in the save method or admin interface
    banner_ad_unit_id_android = models.CharField(max_length=255, blank=True, help_text="Android Banner Ad Unit ID")
    banner_ad_unit_id_ios = models.CharField(max_length=255, blank=True, help_text="iOS Banner Ad Unit ID")
    interstitial_ad_unit_id_android = models.CharField(max_length=255, blank=True, help_text="Android Interstitial Ad Unit ID")
    interstitial_ad_unit_id_ios = models.CharField(max_length=255, blank=True, help_text="iOS Interstitial Ad Unit ID")
    ads_enabled = models.BooleanField(default=True, help_text="Globally enable/disable ads")
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return "AdMob Configuration"

    class Meta:
        verbose_name = "AdMob Configuration"
        verbose_name_plural = "AdMob Configuration"

    @classmethod
    def get_config(cls):
        """Gets the singleton AdMob config instance, creating if it doesn't exist."""
        config, created = cls.objects.get_or_create(pk=1) # Assuming pk=1 for singleton
        if created:
            print("Created initial AdMobConfig record.")
        return config


# Model to store basic analytics events
class AnalyticsEvent(models.Model):
    event_type = models.CharField(max_length=100, db_index=True) # e.g., 'search', 'drug_view', 'calculation'
    details = models.JSONField(blank=True, null=True) # Store extra details like search query, drug name, etc.
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    # Optional: Link to user if authentication is implemented for analytics
    # user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return f"{self.event_type} at {self.timestamp}"

    class Meta:
        ordering = ['-timestamp']


# Model to store general app configuration (e.g., links)
class GeneralConfig(models.Model):
    # Singleton approach again
    about_url = models.URLField(blank=True, help_text="URL for the 'About Us' page")
    privacy_policy_url = models.URLField(blank=True, help_text="URL for the Privacy Policy page")
    terms_of_service_url = models.URLField(blank=True, help_text="URL for the Terms of Service page")
    # Add more general settings as needed
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return "General App Configuration"

    class Meta:
        verbose_name = "General Configuration"
        verbose_name_plural = "General Configuration"

    @classmethod
    def get_config(cls):
        """Gets the singleton General config instance, creating if it doesn't exist."""
        config, created = cls.objects.get_or_create(pk=1) # Assuming pk=1 for singleton
        if created:
            print("Created initial GeneralConfig record.")
        return config
