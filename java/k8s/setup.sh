#! /bin/sh

set -euo pipefail
set -x

. ./00-common-env.sh
. ./10-apis.sh
#. ./20-cluster.sh
#. ./30-private-ca-setup.sh
. ./40-k8s-resources.sh
. ./50-td-components.sh
. ./60-routing-components.sh
. ./70-security-components.sh
. ./75-client-deployment.sh

enable_apis
create_cloud_router_instances
#create_cluster
#create_private_ca_resources

create_k8s_resources ${ACCOUNT_SERVICE_NAME} \
  ${ACCOUNT_SERVICE_SA_NAME} \
  ${ACCOUNT_SERVICE_PORT} \
  ${ACCOUNT_NEG_NAME} \
  ${ACCOUNT_SERVICE_IMAGE} \
  ${ACCOUNT_SERVER_CMD} \
  --port=${ACCOUNT_SERVICE_PORT} \
  --admin_port=${ACCOUNT_ADMIN_PORT} \
  --creds="xds" \
  --hostname_suffix=account

create_k8s_resources ${STATS_SERVICE_NAME} \
  ${STATS_SERVICE_SA_NAME} \
  ${STATS_SERVICE_PORT} \
  ${STATS_NEG_NAME} \
  ${STATS_SERVICE_IMAGE} \
  ${STATS_SERVER_CMD} \
  --port=${STATS_SERVICE_PORT} \
  --admin_port=${STATS_ADMIN_PORT} \
  --hostname_suffix=stats \
  --creds="xds" \
  --account_server="xds:///account.grpcwallet.io"

create_k8s_resources ${STATS_PREMIUM_SERVICE_NAME} \
  ${STATS_PREMIUM_SERVICE_SA_NAME} \
  ${STATS_PREMIUM_SERVICE_PORT} \
  ${STATS_PREMIUM_NEG_NAME} \
  ${STATS_PREMIUM_SERVICE_IMAGE} \
  ${STATS_SERVER_CMD} \
  --port=${STATS_SERVICE_PORT} \
  --admin_port=${STATS_ADMIN_PORT} \
  --hostname_suffix=stats_premium \
  --creds="xds" \
  --account_server="xds:///account.grpcwallet.io" \
  --premium_only=true

create_k8s_resources ${WALLET_V1_SERVICE_NAME} \
  ${WALLET_V1_SERVICE_SA_NAME} \
  ${WALLET_V1_SERVICE_PORT} \
  ${WALLET_V1_NEG_NAME} \
  ${WALLET_V1_SERVICE_IMAGE} \
  ${WALLET_SERVER_CMD} \
  --port=${WALLET_V1_SERVICE_PORT} \
  --admin_port=${WALLET_V1_ADMIN_PORT} \
  --hostname_suffix=wallet_v1 \
  --v1_behavior=true \
  --creds="xds" \
  --account_server="xds:///account.grpcwallet.io" \
  --stats_server="xds:///stats.grpcwallet.io"

create_k8s_resources ${WALLET_V2_SERVICE_NAME} \
  ${WALLET_V2_SERVICE_SA_NAME} \
  ${WALLET_V2_SERVICE_PORT} \
  ${WALLET_V2_NEG_NAME} \
  ${WALLET_V2_SERVICE_IMAGE} \
  ${WALLET_SERVER_CMD} \
  --port=${WALLET_V2_SERVICE_PORT} \
  --admin_port=${WALLET_V2_ADMIN_PORT} \
  --hostname_suffix=wallet_v2 \
  --creds="xds" \
  --account_server="xds:///account.grpcwallet.io" \
  --stats_server="xds:///stats.grpcwallet.io"

create_health_check ${ACCOUNT_SERVICE_HEALTH_CHECK_NAME} ${ACCOUNT_ADMIN_PORT}
create_backend_service ${ACCOUNT_BACKEND_SERVICE_NAME} ${ACCOUNT_SERVICE_HEALTH_CHECK_NAME} ${ACCOUNT_NEG_NAME}

create_health_check ${STATS_SERVICE_HEALTH_CHECK_NAME} ${STATS_ADMIN_PORT}
create_backend_service ${STATS_BACKEND_SERVICE_NAME} ${STATS_SERVICE_HEALTH_CHECK_NAME} ${STATS_NEG_NAME}

create_health_check ${STATS_PREMIUM_SERVICE_HEALTH_CHECK_NAME} ${STATS_PREMIUM_ADMIN_PORT}
create_backend_service ${STATS_PREMIUM_BACKEND_SERVICE_NAME} ${STATS_PREMIUM_SERVICE_HEALTH_CHECK_NAME} ${STATS_PREMIUM_NEG_NAME}

create_health_check ${WALLET_V1_SERVICE_HEALTH_CHECK_NAME} ${WALLET_V1_ADMIN_PORT}
create_backend_service ${WALLET_V1_BACKEND_SERVICE_NAME} ${WALLET_V1_SERVICE_HEALTH_CHECK_NAME} ${WALLET_V1_NEG_NAME}

create_health_check ${WALLET_V2_SERVICE_HEALTH_CHECK_NAME} ${WALLET_V2_ADMIN_PORT}
create_backend_service ${WALLET_V2_BACKEND_SERVICE_NAME} ${WALLET_V2_SERVICE_HEALTH_CHECK_NAME} ${WALLET_V2_NEG_NAME}

  # Run this in a for loop if your project is not exempt from the GCE firewall
  # enforcer which will delete your rules periodically.
  #
gcloud compute firewall-rules create ${FIREWALL_RULE_NAME} \
    --network default --action allow --direction INGRESS \
    --source-ranges 35.191.0.0/16,130.211.0.0/22 \
    --target-tags allow-health-checks \
    --rules tcp

create_routing_components
create_security_components

create_client_deployment
