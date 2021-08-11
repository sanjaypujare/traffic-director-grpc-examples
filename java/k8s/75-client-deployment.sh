#! /bin/bash

function create_client_deployment {
  envsubst < ClientDeployment.yaml | kubectl apply -f -

  gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[default/${CLIENT_SERVICE_ACCOUNT_NAME}]" \
    ${PROJECT_NUM}-compute@developer.gserviceaccount.com

  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[default/${CLIENT_SERVICE_ACCOUNT_NAME}]" \
    --role roles/trafficdirector.client

  kubectl get deployment ${CLIENT_DEPLOYMENT_NAME} -o yaml

  ## ssh into the pod and run commands

  # This command calls 'FetchBalance' from 'wallet-service' in a loop,
  # to demonstrate that 'FetchBalance' gets responses from 'wallet-v1' (40%)
  # and 'wallet-v2' (60%).
  # ./wallet_client balance --wallet_server="xds:///wallet.grpcwallet.io" --unary_watch --creds="xds"

  # This command calls the streaming RPC 'WatchBalance' from 'wallet-service'.
  # The RPC path matches the service prefix, so all requests
  # are sent to 'wallet-v2'.
  # ./wallet_client balance --wallet_server="xds:///wallet.grpcwallet.io" --watch --creds="xds"

  # This command calls 'WatchPrice' from 'stats-service'. It sends the
  # user's membership (premium or not) in metadata. Premium requests are
  # all sent to 'stats-premium' and get faster responses. Alice's requests
  # always go to premium and Bob's go to regular.
  # ./wallet_client price --stats_server="xds:///stats.grpcwallet.io" --watch --user=Bob --creds="xds"
  # ./wallet_client price --stats_server="xds:///stats.grpcwallet.io" --watch --user=Alice --creds="xds"
}

function delete_client_deployment {
  gcloud iam service-accounts remove-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[default/${CLIENT_SERVICE_ACCOUNT_NAME}]" \
    ${PROJECT_NUM}-compute@developer.gserviceaccount.com

  gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[default/${CLIENT_SERVICE_ACCOUNT_NAME}]" \
    --role roles/trafficdirector.client

  kubectl delete serviceaccount ${CLIENT_SERVICE_ACCOUNT_NAME}
  kubectl delete deployment ${CLIENT_DEPLOYMENT_NAME}
}
