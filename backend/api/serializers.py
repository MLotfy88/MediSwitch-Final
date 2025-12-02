from django.contrib.auth.models import User
from rest_framework import serializers
from .models import AdMobConfig, GeneralConfig, AnalyticsEvent # Import AnalyticsEvent model

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True) # Password should not be read

    class Meta:
        model = User
        # Specify fields to include in the serialized output
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'password')
        # Add extra constraints if needed
        extra_kwargs = {
            'email': {'required': True, 'allow_blank': False},
            # Add other constraints as necessary
        }

    def create(self, validated_data):
        # Handle password hashing during user creation
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''), # Use get with default
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
        )
        return user

# Serializer for AdMob Configuration
class AdMobConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdMobConfig
        # Exclude fields not needed by the app, or include all relevant ones
        fields = [
            'ads_enabled',
            'banner_ad_unit_id_android',
            'banner_ad_unit_id_ios',
            'interstitial_ad_unit_id_android',
            'interstitial_ad_unit_id_ios',
            # 'last_updated' # Probably not needed by the app
        ]

# Serializer for General Configuration
class GeneralConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = GeneralConfig
        fields = [
            'about_url',
            'privacy_policy_url',
            'terms_of_service_url',
            # Add other fields if needed
        ]

# Serializer for Analytics Events
class AnalyticsEventSerializer(serializers.ModelSerializer):
    # Make 'details' optional as it might not always be sent
    details = serializers.JSONField(required=False, allow_null=True)

    class Meta:
        model = AnalyticsEvent
        fields = ['event_type', 'details'] # Fields expected from the client
        # Exclude 'timestamp' as it's auto-generated
        # Exclude 'user' unless user tracking is implemented

    def create(self, validated_data):
        # Simple creation, no complex logic needed here for now
        return AnalyticsEvent.objects.create(**validated_data)
from .models import Drug # Import Drug model

class DrugSerializer(serializers.ModelSerializer):
    class Meta:
        model = Drug
        fields = '__all__' # Include all fields including concentration and visits
        read_only_fields = ['created_at', 'updated_at']