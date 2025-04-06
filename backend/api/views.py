import os
import datetime
import pandas as pd # Import pandas
from django.conf import settings
from django.core.files.storage import default_storage
from django.shortcuts import render
from django.http import FileResponse, Http404, JsonResponse
from rest_framework import generics, permissions, status, views
from rest_framework.response import Response
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required # Import login_required
from .serializers import UserSerializer, AdMobConfigSerializer, GeneralConfigSerializer, AnalyticsEventSerializer # Import AnalyticsEventSerializer
from .models import ActiveDataFile, AdMobConfig, GeneralConfig, AnalyticsEvent # Import AnalyticsEvent model

# View for User Registration
class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = UserSerializer

# --- Add other API views below ---

# View for uploading CSV/Excel data file
class UploadDataView(views.APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, *args, **kwargs):
        file_obj = request.FILES.get('file')

        # Define expected columns (adjust as needed based on actual CSV/Excel structure)
        EXPECTED_COLUMNS = [
            'trade_name', 'arabic_name', 'old_price', 'price', 'active',
            'main_category', 'main_category_ar', 'category', 'category_ar',
            'company', 'dosage_form', 'dosage_form_ar', 'unit', 'usage',
            'usage_ar', 'description', 'last_price_update',
            # 'concentration', 'image_url' # Add if these columns are expected
        ]

        if not file_obj:
            return Response({"error": "No file provided."}, status=status.HTTP_400_BAD_REQUEST)

        allowed_extensions = ['.csv', '.xlsx']
        file_name, file_extension = os.path.splitext(file_obj.name)
        if file_extension.lower() not in allowed_extensions:
            return Response({"error": f"Invalid file type. Allowed: {', '.join(allowed_extensions)}"}, status=status.HTTP_400_BAD_REQUEST)

        save_name = f"latest_drugs{file_extension.lower()}"
        file_path = os.path.join(settings.MEDIA_ROOT, save_name)

        # --- Start Validation ---
        try:
            print(f"Validating uploaded file: {file_obj.name}")
            if file_extension.lower() == '.csv':
                # Use a temporary buffer to read the uploaded file without saving it first
                df = pd.read_csv(file_obj)
            elif file_extension.lower() == '.xlsx':
                df = pd.read_excel(file_obj)
            else:
                # This case should technically not be reached due to earlier extension check
                return Response({"error": "Unsupported file type for validation."}, status=status.HTTP_400_BAD_REQUEST)

            # Check for missing columns
            actual_columns = [col.lower().strip() for col in df.columns]
            missing_columns = [col for col in EXPECTED_COLUMNS if col not in actual_columns]

            if missing_columns:
                print(f"Validation failed: Missing columns - {missing_columns}")
                return Response({
                    "error": "Invalid file structure.",
                    "details": f"Missing required columns: {', '.join(missing_columns)}"
                }, status=status.HTTP_400_BAD_REQUEST)

            print("File validation successful.")
            # Reset file pointer after reading for validation
            file_obj.seek(0)

        except pd.errors.EmptyDataError:
             print("Validation failed: Empty file uploaded.")
             return Response({"error": "Empty file uploaded."}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as validation_error:
            print(f"Error during file validation: {validation_error}")
            return Response({"error": f"Failed to read or validate file content: {validation_error}"}, status=status.HTTP_400_BAD_REQUEST)
        # --- End Validation ---


        # --- Proceed with saving if validation passed ---
        os.makedirs(settings.MEDIA_ROOT, exist_ok=True)

        # Delete existing file(s) of either type before saving the new one
        other_extension = '.xlsx' if file_extension.lower() == '.csv' else '.csv'
        other_save_name = f"latest_drugs{other_extension}"
        other_file_path = os.path.join(settings.MEDIA_ROOT, other_save_name)
        if default_storage.exists(other_file_path):
             print(f"Deleting existing file: {other_file_path}")
             default_storage.delete(other_file_path)
        if default_storage.exists(file_path):
             print(f"Deleting existing file: {file_path}")
             default_storage.delete(file_path)

        try: # Try saving the file
            print(f"Saving new file to: {file_path}")
            saved_path = default_storage.save(file_path, file_obj)
            print(f"File saved successfully: {saved_path}")

            # Task 1.2.2.6: Update active file info in the database
            try:
                file_type = file_extension.lower().strip('.')
                active_file_record = ActiveDataFile.update_active_file(save_name, file_type)
                print(f"Updated ActiveDataFile record: ID={active_file_record.id}, Version={active_file_record.version}")
                # Get file size after saving
                file_size = default_storage.size(saved_path)
                return Response({
                    "message": f"File '{file_obj.name}' uploaded successfully as '{save_name}'.",
                    "version": active_file_record.version,
                    "size_bytes": file_size,
                    "size_kb": round(file_size / 1024, 2), # Add size in KB
                }, status=status.HTTP_201_CREATED)
            except Exception as db_error:
                print(f"Error updating ActiveDataFile record: {db_error}")
                # Optionally delete the saved file if DB update fails?
                # default_storage.delete(saved_path)
                return Response({"error": f"File saved but failed to update version info: {db_error}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Exception as e:
            print(f"Error saving file: {e}")
            return Response({"error": f"Failed to save file: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# View to get the version/timestamp of the latest data file
class DataVersionView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, *args, **kwargs):
        try:
            active_file_info = ActiveDataFile.get_active_file_info()

            if not active_file_info:
                return Response({"error": "No active data file information found."}, status=status.HTTP_404_NOT_FOUND)

            # Construct the response using data from the model
            return Response({
                "version": str(active_file_info.version), # Use the stored version (timestamp)
                "file_type": active_file_info.file_type,
                "last_updated_utc": active_file_info.uploaded_at.isoformat() # Use the stored upload time
            }, status=status.HTTP_200_OK)

        except Exception as e:
            print(f"Error getting data version from DB: {e}")
            # Consider more specific error handling if needed
            return Response({"error": f"Failed to get data version: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# View to serve the latest data file (CSV or XLSX)
class LatestDataView(views.APIView):
    permission_classes = [permissions.AllowAny] # Allow any client to download data

    def get(self, request, *args, **kwargs):
        try:
            active_file_info = ActiveDataFile.get_active_file_info()

            if not active_file_info:
                # Return JSON error instead of raising Http404 directly for consistency
                return JsonResponse({"error": "No active data file information found."}, status=status.HTTP_404_NOT_FOUND)

            file_path = os.path.join(settings.MEDIA_ROOT, active_file_info.file_name)
            download_name = active_file_info.file_name

            if not default_storage.exists(file_path):
                 print(f"Error: ActiveDataFile record points to non-existent file: {file_path}")
                 return JsonResponse({"error": "Active data file not found on disk."}, status=status.HTTP_404_NOT_FOUND)

            if active_file_info.file_type == 'csv':
                content_type = 'text/csv'
            elif active_file_info.file_type == 'xlsx':
                content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            else:
                # Fallback or error if file type is unknown
                print(f"Error: Unknown file type '{active_file_info.file_type}' in ActiveDataFile record.")
                content_type = 'application/octet-stream' # Generic binary type

            # Use FileResponse to stream the file
            response = FileResponse(default_storage.open(file_path, 'rb'), content_type=content_type)
            response['Content-Disposition'] = f'attachment; filename="{download_name}"'
            # Add caching headers if desired
            # response['Cache-Control'] = 'public, max-age=3600' # Example: cache for 1 hour
            return response

        except Exception as e:
            print(f"Error serving data file based on DB record: {e}")
            return JsonResponse({"error": f"Failed to serve data file: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# View to get AdMob Configuration
class AdMobConfigView(views.APIView):
   permission_classes = [permissions.AllowAny] # Allow any client to get ad config

   def get(self, request, *args, **kwargs):
       try:
           config = AdMobConfig.get_config() # Get the singleton instance
           serializer = AdMobConfigSerializer(config)
           return Response(serializer.data, status=status.HTTP_200_OK)
       except Exception as e:
           print(f"Error getting AdMob config: {e}")
           return Response({"error": f"Failed to get AdMob configuration: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# View to get General Configuration
class GeneralConfigView(views.APIView):
   permission_classes = [permissions.AllowAny] # Allow any client to get general config

   def get(self, request, *args, **kwargs):
       try:
           config = GeneralConfig.get_config() # Get the singleton instance
           serializer = GeneralConfigSerializer(config)
           return Response(serializer.data, status=status.HTTP_200_OK)
       except Exception as e:
           print(f"Error getting General config: {e}")
           return Response({"error": f"Failed to get General configuration: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# --- Admin Web Views ---

def admin_login_view(request):
    """Renders the admin login page."""
    return render(request, 'admin_login.html')

@login_required(login_url='/api/v1/admin/login/') # Redirect to login if not authenticated
def admin_upload_view(request):
    """Renders the admin data upload page."""
    # Basic view, just renders the template.
    # Authentication is handled by the decorator and JWT check in the JS.
    return render(request, 'admin_upload.html')


# View to log analytics events
class LogAnalyticsView(views.APIView):
    permission_classes = [permissions.AllowAny] # Allow any client to log events

    def post(self, request, *args, **kwargs):
        serializer = AnalyticsEventSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            # Optionally add user association here if request.user is authenticated
            # serializer.save(user=request.user if request.user.is_authenticated else None)
            return Response({"message": "Event logged successfully."}, status=status.HTTP_201_CREATED)
        else:
            print(f"Analytics logging failed: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
