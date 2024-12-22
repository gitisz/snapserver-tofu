# Spotify Credentials
Spotify no longer accepts username and password credentials, so we need to use a refresh token. This folder contains the credentials for the Spotify API, which are used to authenticate the application.

To provision these credentials into k3s, run the following commands from this directory:

```
kubectl create secret generic iszspot-credentials -n snapserver --from-file=credentials.json=./iszspot/credentials.json
kubectl create secret generic sweetspot-credentials -n snapserver --from-file=credentials.json=./sweetspot/credentials.json
kubectl create secret generic wolfspot-credentials -n snapserver --from-file=credentials.json=./wolfspot/credentials.json
```

This will store the `credentials.json` file in Kubernetes secrets.

