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
from django.contrib.auth.decorators import login_required
from django.db.models import Count # Import Count for aggregation
from django.db.models.functions import Lower # Import Lower for case-insensitive grouping
from collections import Counter # For counting queries
from decimal import Decimal, InvalidOperation
from django.utils.dateparse import parse_date, parse_datetime
from .serializers import UserSerializer, AdMobConfigSerializer, GeneralConfigSerializer, AnalyticsEventSerializer
from .models import ActiveDataFile, AdMobConfig, GeneralConfig, AnalyticsEvent, SubscriptionStatus, Drug # Import SubscriptionStatus and Drug

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


# View to validate In-App Purchases
class ValidatePurchaseView(views.APIView):
    permission_classes = [permissions.AllowAny] # Or IsAuthenticated if linked to user accounts

    def post(self, request, *args, **kwargs):
        platform = request.data.get('platform') # 'android' or 'ios'
        purchase_token = request.data.get('purchase_token') # From PurchaseDetails.verificationData.serverVerificationData
        product_id = request.data.get('product_id') # e.g., 'mediswitch_premium_monthly'
        # TODO: Get user/device identifier if validation is user-specific
        user_identifier = "default_user" # Placeholder

        if not all([platform, purchase_token, product_id]):
            return Response({"error": "Missing required validation data (platform, purchase_token, product_id)."}, status=status.HTTP_400_BAD_REQUEST)

        print(f"Received validation request: Platform={platform}, Product={product_id}, Token={purchase_token[:10]}...") # Log truncated token

        is_valid = False
        expiry_date = None

        # --- Placeholder for Store Validation Logic ---
        # TODO: Implement actual validation using platform-specific APIs/libraries
        if platform == 'android':
            # TODO: Use Google Play Developer API (e.g., purchases.subscriptions.get or purchases.products.get)
            # Requires setting up API access and credentials (service account key)
            print("Placeholder: Android validation logic needed.")
            # Simulate success for now
            is_valid = True
            expiry_date = datetime.datetime.now() + datetime.timedelta(days=30) # Simulate 30-day expiry
            pass
        elif platform == 'ios':
            # TODO: Use App Store Server API (e.g., verifyReceipt endpoint or App Store Server Notifications V2)
            # Requires shared secret or other credentials.
            print("Placeholder: iOS validation logic needed.")
             # Simulate success for now
            is_valid = True
            expiry_date = datetime.datetime.now() + datetime.timedelta(days=30) # Simulate 30-day expiry
            pass
        else:
             return Response({"error": "Invalid platform specified."}, status=status.HTTP_400_BAD_REQUEST)
        # --- End Placeholder ---


        if is_valid:
            print(f"Validation successful for {product_id}. Expiry: {expiry_date}")
            # Update user's subscription status in the database
            try:
                status_record = SubscriptionStatus.get_status(identifier=user_identifier)
                status_record.update_status(is_premium=True, expiry_date=expiry_date)
                print(f"Updated subscription status for {user_identifier}")
                return Response({"message": "Purchase validated successfully.", "is_premium": True, "expiry_date": expiry_date}, status=status.HTTP_200_OK)
            except Exception as db_error:
                 print(f"Error updating subscription status after validation: {db_error}")
                 # Return success to client, but log the DB error
                 return Response({"message": "Purchase validated but failed to update status internally.", "is_premium": True, "expiry_date": expiry_date}, status=status.HTTP_200_OK)
        else:
            print(f"Validation failed for {product_id}.")
            # Optionally update status to non-premium if validation fails for an existing user?
            # status_record = SubscriptionStatus.get_status(identifier=user_identifier)
            # status_record.update_status(is_premium=False)
            return Response({"error": "Purchase validation failed."}, status=status.HTTP_400_BAD_REQUEST)


# View to validate In-App Purchases
class ValidatePurchaseView(views.APIView):
    permission_classes = [permissions.AllowAny] # Or IsAuthenticated if linked to user accounts

    def post(self, request, *args, **kwargs):
        platform = request.data.get('platform') # 'android' or 'ios'
        purchase_token = request.data.get('purchase_token') # From PurchaseDetails.verificationData.serverVerificationData
        product_id = request.data.get('product_id') # e.g., 'mediswitch_premium_monthly'
        # TODO: Get user/device identifier if validation is user-specific
        user_identifier = "default_user" # Placeholder

        if not all([platform, purchase_token, product_id]):
            return Response({"error": "Missing required validation data (platform, purchase_token, product_id)."}, status=status.HTTP_400_BAD_REQUEST)

        print(f"Received validation request: Platform={platform}, Product={product_id}, Token={purchase_token[:10]}...") # Log truncated token

        is_valid = False
        expiry_date = None

        # --- Placeholder for Store Validation Logic ---
        # TODO: Implement actual validation using platform-specific APIs/libraries
        if platform == 'android':
            # TODO: Use Google Play Developer API (e.g., purchases.subscriptions.get or purchases.products.get)
            # Requires setting up API access and credentials (service account key)
            print("Placeholder: Android validation logic needed.")
            # Simulate success for now
            is_valid = True
            expiry_date = datetime.datetime.now() + datetime.timedelta(days=30) # Simulate 30-day expiry
            pass
        elif platform == 'ios':
            # TODO: Use App Store Server API (e.g., verifyReceipt endpoint or App Store Server Notifications V2)
            # Requires shared secret or other credentials.
            print("Placeholder: iOS validation logic needed.")
             # Simulate success for now
            is_valid = True
            expiry_date = datetime.datetime.now() + datetime.timedelta(days=30) # Simulate 30-day expiry
            pass
        else:
             return Response({"error": "Invalid platform specified."}, status=status.HTTP_400_BAD_REQUEST)
        # --- End Placeholder ---


        if is_valid:
            print(f"Validation successful for {product_id}. Expiry: {expiry_date}")
            # Update user's subscription status in the database
            try:
                status_record = SubscriptionStatus.get_status(identifier=user_identifier)
                status_record.update_status(is_premium=True, expiry_date=expiry_date)
                print(f"Updated subscription status for {user_identifier}")
                return Response({"message": "Purchase validated successfully.", "is_premium": True, "expiry_date": expiry_date}, status=status.HTTP_200_OK)
            except Exception as db_error:
                 print(f"Error updating subscription status after validation: {db_error}")
                 # Return success to client, but log the DB error
                 return Response({"message": "Purchase validated but failed to update status internally.", "is_premium": True, "expiry_date": expiry_date}, status=status.HTTP_200_OK)
        else:
            print(f"Validation failed for {product_id}.")
            # Optionally update status to non-premium if validation fails for an existing user?
            # status_record = SubscriptionStatus.get_status(identifier=user_identifier)
            # status_record.update_status(is_premium=False)
            return Response({"error": "Purchase validation failed."}, status=status.HTTP_400_BAD_REQUEST)


# View to get analytics summaries (e.g., top searches)
class AnalyticsSummaryView(views.APIView):
    permission_classes = [permissions.IsAdminUser] # Only admins can view summaries

    def get(self, request, *args, **kwargs):
        # --- Top Search Queries ---
        top_n = 10 # Number of top searches to return
        search_events = AnalyticsEvent.objects.filter(event_type='search')

        query_counts = Counter()
        failed_search_count = 0 # Optional: Count searches with no results

        for event in search_events:
            if event.details and isinstance(event.details, dict):
                query = event.details.get('query')
                results_count = event.details.get('results_count') # Assuming frontend sends this

                if isinstance(query, str) and query.strip():
                    query_counts[query.strip().lower()] += 1 # Count lowercase query

                # Optional: Check for failed searches
                if results_count == 0:
                    failed_search_count += 1

        most_common_queries = query_counts.most_common(top_n)

        # --- Prepare Response ---
        summary_data = {
            'total_search_events': search_events.count(),
            'top_search_queries': [
                {'query': query, 'count': count} for query, count in most_common_queries
            ],
            'failed_search_count': failed_search_count, # Optional
            # Add more analytics summaries here later (e.g., top viewed drugs)
        }

        return Response(summary_data, status=status.HTTP_200_OK)


# View to update drug prices from an uploaded CSV/XLSX file
class UpdatePricesFromUploadView(views.APIView):
    permission_classes = [permissions.IsAdminUser]

    # Define expected columns based on the task description format
    # Allowing for flexibility in case sensitivity and whitespace
    EXPECTED_COLUMNS_PRICE_UPDATE = {
        'cleaned drug name': 'trade_name', # Map CSV column to potential model field lookup
        'السعر الجديد': 'new_price',
        'السعر القديم': 'old_price_csv', # Keep separate from model's old_price for now
        'formatted date': 'update_date_csv'
    }

    def post(self, request, *args, **kwargs):
        file_obj = request.FILES.get('file')

        if not file_obj:
            return Response({"error": "No file provided."}, status=status.HTTP_400_BAD_REQUEST)

        allowed_extensions = ['.csv', '.xlsx']
        file_name, file_extension = os.path.splitext(file_obj.name)
        if file_extension.lower() not in allowed_extensions:
            return Response({"error": f"Invalid file type. Allowed: {', '.join(allowed_extensions)}"}, status=status.HTTP_400_BAD_REQUEST)

        updated_count = 0
        not_found_drugs = []
        errors = []

        try:
            print(f"Processing price update file: {file_obj.name}")
            if file_extension.lower() == '.csv':
                df = pd.read_csv(file_obj)
            else: # .xlsx
                df = pd.read_excel(file_obj)

            # Normalize column names (lowercase, strip whitespace)
            df.columns = [col.lower().strip() for col in df.columns]

            # Check for missing columns
            missing_columns = [
                expected for expected in self.EXPECTED_COLUMNS_PRICE_UPDATE.keys()
                if expected not in df.columns
            ]
            if missing_columns:
                print(f"Price update validation failed: Missing columns - {missing_columns}")
                return Response({
                    "error": "Invalid file structure for price update.",
                    "details": f"Missing required columns: {', '.join(missing_columns)}"
                }, status=status.HTTP_400_BAD_REQUEST)

            # Iterate through rows and update prices
            for index, row in df.iterrows():
                drug_name = row.get(list(self.EXPECTED_COLUMNS_PRICE_UPDATE.keys())[0]) # 'cleaned drug name'
                new_price_str = str(row.get(list(self.EXPECTED_COLUMNS_PRICE_UPDATE.keys())[1])) # 'السعر الجديد'
                # Optional: old_price_csv = row.get(list(self.EXPECTED_COLUMNS_PRICE_UPDATE.keys())[2])
                # Optional: update_date_csv = row.get(list(self.EXPECTED_COLUMNS_PRICE_UPDATE.keys())[3])

                if not drug_name or pd.isna(drug_name):
                    errors.append(f"Row {index + 2}: Missing drug name.")
                    continue
                if not new_price_str or pd.isna(new_price_str):
                     errors.append(f"Row {index + 2}: Missing new price for drug '{drug_name}'.")
                     continue

                drug_name = str(drug_name).strip()

                try:
                    new_price = Decimal(new_price_str)
                except InvalidOperation:
                    errors.append(f"Row {index + 2}: Invalid new price format '{new_price_str}' for drug '{drug_name}'.")
                    continue

                # Find the drug (case-insensitive search on trade_name)
                # Consider searching arabic_name as well if needed
                drug = Drug.objects.filter(trade_name__iexact=drug_name).first()

                if drug:
                    try:
                        # Update price logic: store current price as old_price, set new price
                        drug.old_price = drug.price
                        drug.price = new_price
                        # Optionally parse and set last_price_update from update_date_csv if needed
                        # try:
                        #     if update_date_csv and not pd.isna(update_date_csv):
                        #         # Assuming format DD/MM/YYYY
                        #         drug.last_price_update = datetime.datetime.strptime(str(update_date_csv), '%d/%m/%Y').date()
                        # except ValueError:
                        #      errors.append(f"Row {index + 2}: Invalid date format '{update_date_csv}' for drug '{drug_name}'.")
                        drug.save()
                        updated_count += 1
                    except Exception as save_error:
                         errors.append(f"Row {index + 2}: Error saving update for drug '{drug_name}': {save_error}")

                else:
                    not_found_drugs.append(drug_name)

            print(f"Price update processing complete. Updated: {updated_count}, Not Found: {len(not_found_drugs)}, Errors: {len(errors)}")

            return Response({
                "message": "Price update process finished.",
                "updated_count": updated_count,
                "not_found_drugs": not_found_drugs,
                "processing_errors": errors
            }, status=status.HTTP_200_OK)

        except pd.errors.EmptyDataError:
             print("Price update failed: Empty file uploaded.")
             return Response({"error": "Empty file uploaded."}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as processing_error:
            print(f"Error processing price update file: {processing_error}")
            return Response({"error": f"Failed to process price update file: {processing_error}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# View to add new drugs from an uploaded CSV/XLSX file
class AddDrugsFromUploadView(views.APIView):
    permission_classes = [permissions.IsAdminUser]

    # Define expected columns based on the task description format for adding new drugs
    EXPECTED_COLUMNS_ADD_DRUG = {
        'trade_name': 'trade_name',
        'arabic_name': 'arabic_name',
        'old_price': 'old_price',
        'price': 'price',
        'active': 'active_ingredients', # Map 'active' from CSV to 'active_ingredients' model field
        'main_category': 'main_category',
        'main_category_ar': 'main_category_ar',
        'category': 'category',
        'category_ar': 'category_ar',
        'company': 'company',
        'dosage_form': 'dosage_form',
        'dosage_form_ar': 'dosage_form_ar',
        'unit': 'unit',
        'usage': 'usage',
        'usage_ar': 'usage_ar',
        'description': 'description',
        'last_price_update': 'last_price_update'
    }

    def post(self, request, *args, **kwargs):
        file_obj = request.FILES.get('file')

        if not file_obj:
            return Response({"error": "No file provided."}, status=status.HTTP_400_BAD_REQUEST)

        allowed_extensions = ['.csv', '.xlsx']
        file_name, file_extension = os.path.splitext(file_obj.name)
        if file_extension.lower() not in allowed_extensions:
            return Response({"error": f"Invalid file type. Allowed: {', '.join(allowed_extensions)}"}, status=status.HTTP_400_BAD_REQUEST)

        added_count = 0
        skipped_count = 0
        errors = []

        try:
            print(f"Processing add drugs file: {file_obj.name}")
            if file_extension.lower() == '.csv':
                # Handle potential encoding issues common with Arabic text in CSV
                try:
                    df = pd.read_csv(file_obj, encoding='utf-8')
                except UnicodeDecodeError:
                    try:
                        print("UTF-8 failed, trying windows-1256...")
                        file_obj.seek(0) # Reset pointer
                        df = pd.read_csv(file_obj, encoding='windows-1256') # Common Arabic encoding
                    except Exception as e:
                         print(f"Failed to read CSV with multiple encodings: {e}")
                         return Response({"error": f"Could not decode CSV file. Try saving as UTF-8. Error: {e}"}, status=status.HTTP_400_BAD_REQUEST)

            else: # .xlsx
                df = pd.read_excel(file_obj)

            # Normalize column names (lowercase, strip whitespace)
            df.columns = [col.lower().strip() for col in df.columns]

            # Check for missing columns (using the keys from our mapping)
            missing_columns = [
                expected for expected in self.EXPECTED_COLUMNS_ADD_DRUG.keys()
                if expected not in df.columns
            ]
            if missing_columns:
                print(f"Add drug validation failed: Missing columns - {missing_columns}")
                return Response({
                    "error": "Invalid file structure for adding drugs.",
                    "details": f"Missing required columns: {', '.join(missing_columns)}"
                }, status=status.HTTP_400_BAD_REQUEST)

            # Iterate through rows and add drugs
            for index, row in df.iterrows():
                drug_data = {}
                row_errors = []

                # Map CSV columns to model fields, handling potential type errors
                for csv_col, model_field in self.EXPECTED_COLUMNS_ADD_DRUG.items():
                    value = row.get(csv_col)
                    if pd.isna(value):
                        value = None # Use None for empty cells

                    # Basic type conversion and validation
                    if value is not None:
                        try:
                            if model_field in ['price', 'old_price']:
                                drug_data[model_field] = Decimal(str(value)) if value else None
                            elif model_field == 'last_price_update':
                                # Try parsing date/datetime - adjust format as needed
                                parsed_date = parse_date(str(value)) or parse_datetime(str(value))
                                drug_data[model_field] = parsed_date.date() if parsed_date else None
                            else:
                                drug_data[model_field] = str(value).strip() # Default to string
                        except (InvalidOperation, ValueError) as e:
                             row_errors.append(f"Invalid format for '{csv_col}': {value} ({e})")

                    elif model_field == 'price': # Price is mandatory in the model
                         row_errors.append(f"Missing required value for 'price'")
                    else:
                         drug_data[model_field] = None # Allow null/blank for optional fields

                # Check for mandatory trade_name
                if not drug_data.get('trade_name'):
                    row_errors.append("Missing required value for 'trade_name'")

                if row_errors:
                    errors.append(f"Row {index + 2}: {'; '.join(row_errors)}")
                    continue # Skip row with errors

                # Check if drug already exists (case-insensitive trade_name)
                trade_name = drug_data['trade_name']
                if Drug.objects.filter(trade_name__iexact=trade_name).exists():
                    skipped_count += 1
                    continue # Skip existing drug

                # Create new Drug instance
                try:
                    # Remove None values for fields that don't allow null in model but might be missing in CSV
                    # (adjust based on final model definition if needed)
                    final_data = {k: v for k, v in drug_data.items() if v is not None}
                    Drug.objects.create(**final_data)
                    added_count += 1
                except Exception as create_error:
                    errors.append(f"Row {index + 2} (Drug: {trade_name}): Error creating drug: {create_error}")


            print(f"Add drugs processing complete. Added: {added_count}, Skipped (duplicates): {skipped_count}, Errors: {len(errors)}")

            return Response({
                "message": "Add drugs process finished.",
                "added_count": added_count,
                "skipped_duplicates": skipped_count,
                "processing_errors": errors
            }, status=status.HTTP_200_OK)

        except pd.errors.EmptyDataError:
             print("Add drugs failed: Empty file uploaded.")
             return Response({"error": "Empty file uploaded."}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as processing_error:
            print(f"Error processing add drugs file: {processing_error}")
            return Response({"error": f"Failed to process add drugs file: {processing_error}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Placeholder View for Drug Interaction Check API
class DrugInteractionCheckView(views.APIView):
    permission_classes = [permissions.AllowAny] # Adjust permissions as needed later

    def post(self, request, *args, **kwargs):
        # TODO: Implement interaction checking logic
        # 1. Receive list of drug identifiers (e.g., names, IDs) from request.data
        # 2. Use external sources (API-sources.txt) or internal data to check interactions
        # 3. Format and return the interaction results
        drug_list = request.data.get('drugs', [])
        print(f"Received interaction check request for drugs: {drug_list}")
        # Placeholder response
        return Response({
            "message": "Interaction check endpoint not yet implemented.",
            "requested_drugs": drug_list,
            "interactions": [] # Placeholder for results
        }, status=status.HTTP_501_NOT_IMPLEMENTED)


# Placeholder View for Dosage Calculation API
class DosageCalculationView(views.APIView):
    permission_classes = [permissions.AllowAny] # Adjust permissions as needed later

    def post(self, request, *args, **kwargs):
        # TODO: Implement dosage calculation logic
        # 1. Receive drug identifier, patient info (age, weight?), dosage form etc.
        # 2. Use external sources or internal rules to calculate dosage
        # 3. Format and return the calculation result
        calculation_params = request.data
        print(f"Received dosage calculation request with params: {calculation_params}")
        # Placeholder response
        return Response({
            "message": "Dosage calculation endpoint not yet implemented.",
            "request_params": calculation_params,
            "result": {} # Placeholder for results
        }, status=status.HTTP_501_NOT_IMPLEMENTED)

# View for downloading all drug data
from rest_framework.generics import ListAPIView
from rest_framework.permissions import AllowAny
from .models import Drug
from .serializers import DrugSerializer

class DrugDownloadView(ListAPIView):
    """
    Provides a read-only endpoint to download the entire drug list.
    Used by the mobile app to populate/update its local database.
    """
    queryset = Drug.objects.all()
    serializer_class = DrugSerializer
    permission_classes = [AllowAny] # Allow any client (the app) to access this
    pagination_class = None # Return all drugs at once, no pagination
# Add to views.py after existing views

from decimal import Decimal
from django.utils import timezone
from datetime import datetime

class BulkUpsertDrugsView(views.APIView):
    """
    Bulk insert or update drugs from scraped data.
    Used by GitHub Actions for daily updates.
    Accepts a JSON array of drug objects.
    """
    permission_classes = [permissions.IsAdminUser]
    
    def post(self, request, *args, **kwargs):
        drugs_data = request.data.get('drugs', [])
        
        if not isinstance(drugs_data, list):
            return Response(
                {"error": "Expected 'drugs' to be an array"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        stats = {
            'total': len(drugs_data),
            'created': 0,
            'updated': 0,
            'errors': []
        }
        
        for index, drug_data in enumerate(drugs_data):
            try:
                # Extract and validate trade_name (required)
                trade_name = drug_data.get('trade_name', '').strip()
                if not trade_name:
                    stats['errors'].append(f"Row {index}: Missing trade_name")
                    continue
                
                # Parse price fields
                try:
                    price = Decimal(str(drug_data.get('price', 0)))
                    old_price = Decimal(str(drug_data.get('old_price', 0))) if drug_data.get('old_price') else None
                except (ValueError, InvalidOperation):
                    stats['errors'].append(f"Row {index}: Invalid price format")
                    continue
                
                # Parse date if exists
                last_price_update = None
                if drug_data.get('last_price_update'):
                    try:
                        # Try dd/mm/yyyy format
                        date_str = str(drug_data['last_price_update'])
                        last_price_update = datetime.strptime(date_str, '%d/%m/%Y').date()
                    except ValueError:
                        try:
                            # Try yyyy-mm-dd format
                            last_price_update = datetime.strptime(date_str, '%Y-%m-%d').date()
                        except ValueError:
                            pass  # Use None if parsing fails
                
                # Parse visits
                visits = int(drug_data.get('visits', 0)) if drug_data.get('visits') else 0
                
                # Prepare drug data
                drug_fields = {
                    'trade_name': trade_name,
                    'arabic_name': drug_data.get('arabic_name', ''),
                    'price': price,
                    'old_price': old_price,
                    'active_ingredients': drug_data.get('active', ''),
                    'main_category': drug_data.get('main_category', ''),
                    'main_category_ar': drug_data.get('main_category_ar', ''),
                    'category': drug_data.get('category', ''),
                    'category_ar': drug_data.get('category_ar', ''),
                    'company': drug_data.get('company', ''),
                    'dosage_form': drug_data.get('dosage_form', ''),
                    'dosage_form_ar': drug_data.get('dosage_form_ar', ''),
                    'unit': drug_data.get('unit', '1'),
                    'usage': drug_data.get('usage', ''),
                    'usage_ar': drug_data.get('usage_ar', ''),
                    'description': drug_data.get('description', ''),
                    'concentration': drug_data.get('concentration', ''),
                    'visits': visits,
                    'last_price_update': last_price_update,
                }
                
                # Use update_or_create for upsert behavior
                drug, created = Drug.objects.update_or_create(
                    trade_name__iexact=trade_name,
                    defaults=drug_fields
                )
                
                if created:
                    stats['created'] += 1
                else:
                    stats['updated'] += 1
                    
            except Exception as e:
                stats['errors'].append(f"Row {index} ({drug_data.get('trade_name', 'unknown')}): {str(e)}")
        
        return Response({
            "message": "Bulk upsert completed",
            "statistics": stats
        }, status=status.HTTP_200_OK)


class DrugSyncView(views.APIView):
    """
    Returns drugs updated since a specific date.
    Used by Flutter app for incremental sync.
    Query param: ?since=2025-12-01 (ISO format YYYY-MM-DD)
    """
    permission_classes = [permissions.AllowAny]
    
    def get(self, request, *args, **kwargs):
        since_param = request.GET.get('since')
        
        if not since_param:
            return Response(
                {"error": "Missing 'since' parameter. Format: YYYY-MM-DD or dd/mm/yyyy"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Parse date
        try:
            # Try ISO format first (YYYY-MM-DD)
            if '-' in since_param and len(since_param.split('-')[0]) == 4:
                since_date = datetime.strptime(since_param, '%Y-%m-%d')
            # Try dd/mm/yyyy format
            elif '/' in since_param:
                since_date = datetime.strptime(since_param, '%d/%m/%Y')
            else:
                raise ValueError("Invalid date format")
                
        except ValueError:
            return Response(
                {"error": "Invalid date format. Use YYYY-MM-DD or dd/mm/yyyy"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Query drugs updated after the given date
        drugs = Drug.objects.filter(updated_at__gte=since_date).order_by('-updated_at')
        
        # Serialize
        serializer = DrugSerializer(drugs, many=True)
        
        return Response({
            "count": drugs.count(),
            "since": since_param,
            "drugs": serializer.data
        }, status=status.HTTP_200_OK)
