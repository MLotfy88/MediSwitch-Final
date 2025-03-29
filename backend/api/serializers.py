from django.contrib.auth.models import User
from rest_framework import serializers

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