from django.urls import path
from . import views # Import views

app_name = 'api' # Define an app namespace

urlpatterns = [
    # Auth URLs
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    # Note: JWT token URLs are likely in the main project urls.py (mediswitch_api/urls.py)

    # Data URLs
    path('admin/data/upload/', views.UploadDataView.as_view(), name='upload_data'),
    path('data/version/', views.DataVersionView.as_view(), name='data_version'),
    path('data/latest/', views.LatestDataView.as_view(), name='latest_data'),

    # Admin Web URLs (Add the login view URL)
    path('admin/login/', views.admin_login_view, name='admin_login'),
    path('admin/upload/', views.admin_upload_view, name='admin_upload'), # Add URL for upload page
]
