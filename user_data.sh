#!/bin/bash
# Redirect logs
exec > >(tee /opt/script.log | logger -t user-data -s 2>/dev/console) 2>&1

# Install dependencies
apt update -y
apt install -y openjdk-21-jdk git maven awscli at

# Verify installations
echo "Java version:"
java -version
echo "Maven version:"
mvn -v

# Clone project
cd /opt
git clone https://github.com/techeazy-consulting/techeazy-devops
cd techeazy-devops

# Build project
echo "Building the project..."
mvn clean install

# Locate and run JAR
JAR_FILE=$(find target -type f -name "*.jar" | head -n 1)
if [[ -f "$JAR_FILE" ]]; then
  echo "JAR built successfully: $JAR_FILE"
  nohup java -jar "$JAR_FILE" > /opt/app.log 2>&1 &
  echo "App started successfully." >> /opt/deploy.log
else
  echo "JAR not found. Build failed." > /opt/error.log
  exit 1
fi

# Create shutdown script for log upload
cat <<EOF > /opt/shutdown-upload.sh
#!/bin/bash
aws s3 cp /opt/app.log s3://${s3_bucket_name}/logs/app-\$(date +%s).log
EOF

chmod +x /opt/shutdown-upload.sh

# Register shutdown upload script
echo "/opt/shutdown-upload.sh" > /etc/rc0.d/K99upload

# Auto shutdown after 15 minutes
SHUTDOWN_MINUTES=15
echo "shutdown -h now" | at now + $SHUTDOWN_MINUTES minutes
echo "App running. System will shut down in $SHUTDOWN_MINUTES minutes." >> /opt/shutdown.log

