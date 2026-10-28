#!/usr/bin/env bash
# Scan WebGoat.NET against SonarQube Cloud staging. Needs SONAR_TOKEN in the environment.
set -euo pipefail
cd "$(dirname "$0")"

prop() { grep -E "^$1=" sonar-project.properties | head -n 1 | cut -d= -f2-; }
HOST="${SONAR_HOST_URL:-$(prop sonar.host.url)}"
API="${SONAR_API_URL:-$(prop sonar.scanner.apiBaseUrl)}"
ORG="${SONAR_ORG:-$(prop sonar.organization)}"
KEY="${SONAR_PROJECT_KEY:-$(prop sonar.projectKey)}"
: "${SONAR_TOKEN:?export SONAR_TOKEN first}"

export PATH="$PATH:$HOME/.dotnet/tools"
command -v dotnet-sonarscanner >/dev/null || dotnet tool install --global dotnet-sonarscanner

dotnet sonarscanner begin /k:"$KEY" /o:"$ORG" /d:sonar.scanner.sonarcloudUrl="$HOST" /d:sonar.scanner.apiBaseUrl="$API" /d:sonar.token="$SONAR_TOKEN"
# The csproj references Microsoft.NET.Test.Sdk, so the scanner would classify the app as test code.
dotnet build "${1:-WebGoat.NET.sln}" --no-incremental -p:SonarQubeTestProject=false
dotnet sonarscanner end /d:sonar.token="$SONAR_TOKEN"

echo "Results: $HOST/dashboard?id=$KEY"
