#!/bin/bash

#script log
exec > >(tee /opt/script.log | logger -t user-data -s 2>/dev/console) 2>&1

apt update -y
apt install -y openjdk-21-jdk git maven at

echo "################Java version:#############3"
java -version
echo "####################Maven version:##################"
mvn -v

# Clone project
cd /opt
git clone https://github.com/techeazy-consulting/techeazy-devops
cd techeazy-devops

# Build project
echo "##### Building the project...#################"
mvn clean install

JAR_FILE=$(find target -type f -name "*.jar" | head -n 1)
if [[ -f "$JAR_FILE" ]]; then
  echo "JAR built successfully: $JAR_FILE"
  nohup java -jar "$JAR_FILE" > /opt/app.log 2>&1 &
  echo "App started successfully." >> /opt/deploy.log
else
  echo "JAR not found. Build failed." > /opt/error.log
  exit 1
fi

# Auto shutdown after 30 minutes to save cost
SHUTDOWN_MINUTES=30
echo "shutdown -h now" | at now + $SHUTDOWN_MINUTES minutes
echo "App running. System will shut down in $SHUTDOWN_MINUTES minutes." >> /opt/deploy.log
