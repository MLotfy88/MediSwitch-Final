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


# Model to track premium subscription status (placeholder)
# TODO: Link this to a proper User/Device profile when implemented
class SubscriptionStatus(models.Model):
    # Using a fixed primary key for singleton-like behavior per user/device later
    # For now, just a placeholder identifier
    identifier = models.CharField(max_length=255, unique=True, default="default_user") # Replace with actual user/device ID later
    is_premium = models.BooleanField(default=False)
    premium_expiry_date = models.DateTimeField(null=True, blank=True, help_text="Expiry date of the current premium subscription")
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        status = "Premium" if self.is_premium else "Free"
        expiry = f" (Expires: {self.premium_expiry_date})" if self.is_premium and self.premium_expiry_date else ""
        return f"Subscription Status [{self.identifier}]: {status}{expiry}"

    class Meta:
        verbose_name = "Subscription Status"
        verbose_name_plural = "Subscription Statuses"

    @classmethod
    def get_status(cls, identifier="default_user"): # Replace default later
        """Gets the status for a given identifier, creating if it doesn't exist."""
        status, created = cls.objects.get_or_create(identifier=identifier)
        return status

    def update_status(self, is_premium, expiry_date=None):
        """Updates the premium status and expiry date."""
        self.is_premium = is_premium
        self.premium_expiry_date = expiry_date if is_premium else None
        self.save()


# Model to store Drug information
class Drug(models.Model):
    trade_name = models.CharField(max_length=255, db_index=True, help_text="Commercial name of the drug")
    arabic_name = models.CharField(max_length=255, db_index=True, blank=True, help_text="Arabic commercial name")
    old_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text="Previous price before the last update")
    price = models.DecimalField(max_digits=10, decimal_places=2, help_text="Current price")
    # Storing active ingredients as text for now. Consider a separate model + ManyToManyField for structured data later.
    active_ingredients = models.TextField(db_index=True, blank=True, help_text="Active ingredients, potentially comma-separated")
    main_category = models.CharField(max_length=100, db_index=True, blank=True, help_text="Main therapeutic category (e.g., Respiratory)")
    main_category_ar = models.CharField(max_length=100, blank=True, help_text="Arabic main category")
    category = models.CharField(max_length=100, db_index=True, blank=True, help_text="Sub-category (e.g., cold drugs)")
    category_ar = models.CharField(max_length=100, blank=True, help_text="Arabic sub-category")
    company = models.CharField(max_length=100, db_index=True, blank=True, help_text="Manufacturing company")
    dosage_form = models.CharField(max_length=100, blank=True, help_text="Dosage form (e.g., Syrup, Tablet)")
    dosage_form_ar = models.CharField(max_length=100, blank=True, help_text="Arabic dosage form")
    # 'unit' field from CSV seems unclear (values '1', '2'). Storing as CharField for now.
    unit = models.CharField(max_length=50, blank=True, help_text="Unit information (needs clarification)")
    usage = models.CharField(max_length=100, blank=True, help_text="General usage description (e.g., Oral.Liquid)")
    usage_ar = models.CharField(max_length=100, blank=True, help_text="Arabic usage description")
    description = models.TextField(blank=True, help_text="Detailed description or indications")
    last_price_update = models.DateField(null=True, blank=True, help_text="Date the price was last updated")
    
    # Additional fields from scraped data
    concentration = models.CharField(max_length=100, blank=True, help_text="Drug concentration (e.g., 120mg/5ml)")
    visits = models.IntegerField(default=0, help_text="Number of visits/views on source website")

    # Timestamps for tracking and synchronization
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True, db_index=True, help_text="Timestamp of the last modification, used for sync")

    def __str__(self):
        return self.trade_name

    class Meta:
        ordering = ['trade_name']
        indexes = [
            models.Index(fields=['trade_name', 'arabic_name']),
            # Add more indexes as needed based on query patterns
        ]
