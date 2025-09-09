import base64
import uuid
from django.core.files.base import ContentFile
from rest_framework import serializers

class Base64ImageField(serializers.ImageField):
    """
    A custom serializer field for handling Base64-encoded image uploads and downloads.
    It decodes the Base64 string into a file object on write and encodes the image
    file to a Base64 string on read.
    """

    def to_internal_value(self, data):
        # Handles decoding the Base64 string to a file for saving.
        # Expects a format like: "data:image/jpeg;base64,/9j/4AAQSk...
        if isinstance(data, str) and data.startswith('data:image'):
            # Split the header from the Base64 data
            try:
                header, data = data.split(';base64,')
            except ValueError:
                raise serializers.ValidationError("Invalid base64 image format.")

            # Get the file extension
            ext = header.split('/')[-1]

            # Create a unique filename
            filename = f"{uuid.uuid4()}.{ext}"

            # Decode the data and create a Django ContentFile
            try:
                decoded_file = base64.b64decode(data)
            except (ValueError, TypeError):
                raise serializers.ValidationError("Invalid base64 encoding.")
            
            data = ContentFile(decoded_file, name=filename)

        return super().to_internal_value(data)

    def to_representation(self, value):
        # Handles encoding the image file to a Base64 string for display.
        if not value:
            return None

        try:
            with value.open('rb') as image_file:
                # Read the file content and encode it
                encoded_string = base64.b64encode(image_file.read()).decode()
            
            # Get the file extension for the data URI
            ext = value.name.split('.')[-1].lower()
            
            # Return in "data:image/..." format
            return f"data:image/{ext};base64,{encoded_string}"
        except Exception:
            # If the file can't be opened or read, return None
            return None 