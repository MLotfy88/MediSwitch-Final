from django.urls import path, include # Add include
from . import views # Import views

from .views import ( # Import the new view
    RegisterView, UploadDataView, DataVersionView, LatestDataView,
    AdMobConfigView, GeneralConfigView, LogAnalyticsView, AnalyticsSummaryView,
    ValidatePurchaseView, # Added ValidatePurchaseView
    UpdatePricesFromUploadView, # Import the price update view
    AddDrugsFromUploadView, # Import the add drugs view
    DrugInteractionCheckView, # Import placeholder interaction view
    DosageCalculationView, # Import placeholder dosage view
    admin_login_view, admin_upload_view
)

app_name = 'api' # Define an app namespace
urlpatterns = [
    # Auth URLs
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    # Note: JWT token URLs are likely in the main project urls.py (mediswitch_api/urls.py)

    # Data URLs
    path('admin/data/upload/', views.UploadDataView.as_view(), name='upload_data'), # Uploads the main data file
    path('admin/data/update-prices/', views.UpdatePricesFromUploadView.as_view(), name='update_prices_from_upload'), # Uploads file for price updates
    path('admin/data/add-drugs/', views.AddDrugsFromUploadView.as_view(), name='add_drugs_from_upload'), # Uploads file for adding new drugs
    path('data/version/', views.DataVersionView.as_view(), name='data_version'), # Legacy? Or needs update for sync?
    path('data/latest/', views.LatestDataView.as_view(), name='latest_data'), # Legacy? Or needs update for sync?

    # Core Functionality APIs
    path('drugs/check-interactions/', views.DrugInteractionCheckView.as_view(), name='check_interactions'),
    path('drugs/calculate-dosage/', views.DosageCalculationView.as_view(), name='calculate_dosage'),

    # Config URLs
    path('config/ads/', views.AdMobConfigView.as_view(), name='admob_config'), # AdMob config endpoint
    path('config/general/', views.GeneralConfigView.as_view(), name='general_config'), # General config endpoint

    # Analytics URL
    path('analytics/log/', views.LogAnalyticsView.as_view(), name='log_analytics'),
    path('analytics/summary/', views.AnalyticsSummaryView.as_view(), name='analytics_summary'),
    path('subscriptions/validate/', views.ValidatePurchaseView.as_view(), name='validate_purchase'), # Add validation URL
    # Admin Web URLs (Add the login view URL)
    path('admin/login/', views.admin_login_view, name='admin_login'),
    path('admin/upload/', views.admin_upload_view, name='admin_upload'), # Add URL for upload page
]
