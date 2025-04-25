# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
# Set the working directory in the container
WORKDIR /app

# Install system dependencies if needed (e.g., for postgresql client)
# RUN apt-get update && apt-get install -y --no-install-recommends postgresql-client && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
# Copy only the requirements file first to leverage Docker cache
COPY requirements.txt .
# Upgrade pip and install requirements
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . .

# Collect static files (if using Django's staticfiles app)
# This assumes you have STATIC_ROOT configured in settings.py
RUN python manage.py collectstatic --noinput

# Expose the port the app runs on (matching Gunicorn command)
EXPOSE 8000

# Define the command to run the application using Gunicorn
# Gunicorn is a production-ready WSGI server
# Ensure gunicorn is listed in requirements.txt
# The number of workers can be adjusted based on the server resources
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "mediswitch_api.wsgi:application"]