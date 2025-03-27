# MediSwitch Docker Environment

This document provides instructions for using the Docker environment for the MediSwitch application.

## Prerequisites

- Docker installed on your system
- Basic knowledge of Docker commands

## Building the Docker Image

To build the Docker image, navigate to the project directory and run:

```bash
docker build -t mediswitch .
```

This will create a Docker image named `mediswitch` with all the necessary dependencies installed.

## Running the Container

The Docker container supports several commands through its entrypoint script:

### Run the Application

```bash
docker run --rm -it mediswitch run
```

### Build the APK

```bash
docker run --rm -it -v $(pwd)/build:/app/build mediswitch build
```

This will build the APK and save it to your local build directory.

### Run Tests

```bash
docker run --rm -it mediswitch test
```

### Run Web Server

```bash
docker run --rm -it -p 8080:8080 mediswitch web
```

Then access the application at http://localhost:8080

## Environment Details

The Docker environment includes:

- Ubuntu 22.04 as the base OS
- JDK 23.0.2
- Android SDK with platforms 28, 29, 33, 34, 35
- Android build tools 30.0.3, 34.0.0, 36.0.0
- Android NDK 27.0.12077973
- Flutter SDK 3.29.2
- Dart SDK 3.7.2
- All dependencies required for SQLCipher, CSV handling, and other project requirements

## Customizing the Build

You can customize the build by modifying the Dockerfile. For example, to add additional Android platforms or build tools, modify the `sdkmanager` command in the Dockerfile.

## Troubleshooting

### Common Issues

1. **Build fails with memory issues**: Increase Docker memory allocation in Docker Desktop settings
2. **License acceptance issues**: The Dockerfile automatically accepts licenses, but if you encounter issues, you may need to run the container interactively and accept licenses manually
3. **Network issues during build**: Ensure you have a stable internet connection as the build process downloads several large files

### Getting Help

If you encounter any issues with the Docker environment, please check the Flutter and Docker documentation or reach out to the development team.