#!/usr/bin/env bash
set -euo pipefail

CHART="helm/ml-api"

echo "==> Helm lint"
helm lint "$CHART"

for ENV in dev staging prod; do
  echo "==> Testing environment: $ENV"

  OUTPUT=$(helm template "ml-api-$ENV" "$CHART" \
    -f "$CHART/values-$ENV.yaml")

  echo "$OUTPUT" | grep -q "kind: Deployment"
  echo "$OUTPUT" | grep -q "kind: Service"
  echo "$OUTPUT" | grep -q "kind: HorizontalPodAutoscaler"
  echo "$OUTPUT" | grep -q 'path: /health'

  echo "PASS: $ENV"
done

echo "==> All Helm chart tests passed"
