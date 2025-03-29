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
