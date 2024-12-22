# Snapserver

This repository contains the code for running a containerized instance of [Snapcast](https://github.com/badaix/snapcast) server. This repository also provides a way to provision a Snapcast server on a [K3S](https://docs.k3s.io/) cluster using Terraform ([OpenTofu](https://opentofu.org/)).

## Docker
The Snapcast server (`snapserver`) is deployed as a containerized application. The Docker image is built using the Dockerfile in the root of the repository. The Docker image should be pushed to a private Docker registry. The Docker image may then pulled by the K3S using the Terraform configuration scripts provided.

## Running Locally
If you want to test this locally there is a file called `snapserver.conf` in the root of the repository. The `snapserver.conf` configuration file should be mounted as a volume to the container. The `snapserver.conf` is used to configure the Snapserver but should be modified to suit your needs.

Additionally, you will need a credential to use Snapcast with Spotify. This credential will also require mounting to the container. When properly mounted, the credential will be read through the `snapserver.conf` file which is appended to the stream configuration, e.g. `cache=/snapserver/my-secret`. The host side of the volume mount should have a `credentials.json` file with the following contents:

```
{
  "username":"<my-spotify-username>",
  "auth_type":1,
  "auth_data":"<my-spotify-auth-token>"
}
```

_TODO: describe how the `authh_data` is generated._

Last, there is a `docker-compose.yml` file which can be used for an alternative solution for deploying Snapserver.

## Kubernetes (k3s)
To deploy the Snapserver in Kubernetes, the following steps are required...

Create a .env file at the root of the repository. The .env file should contain the following variables:

 * export **TF_VAR_DOCKER_REGISTRY_SERVER**="<dockyard.my-domain.com>"
 * export **TF_VAR_DOCKER_REGISTRY_USERNAME**="<Docker-registry-username>"
 * export **TF_VAR_DOCKER_REGISTRY_PASSWORD**="<Docker-registry-password>"
 * export **TF_VAR_DOCKER_REGISTRY_EMAIL**="<administrator@my-domain.com>"
 * export **TF_VAR_CERT_MANAGER_CLOUDFLARE_DNS_ZONE**="<my-domain.com>"


Once the .env file is created, source the .env file : `source .env`.

Next, run the following command to initialize the Terraform configuration:

```
tofu init
```

Next, run the following command to create a plan:

```
tofu plan -var='spotify_users=[{"name":"crazy","username":"crazy-spotify","auth_token":"xxyy123="},{"name":"sanity","username":"sane-spotify","auth_token":"aabb123="}]'
```

_NOTE: The `spotify_users` variable is a list of Spotify users. Each user must have a unique name, username, and auth_token._

After inspecting the plan, apply the plan:

```
tofu apply -var='spotify_users=[{"name":"crazy","username":"crazy-spotify","auth_token":"xxyy123="},{"name":"sanity","username":"sane-spotify","auth_token":"aabb123="}]'
```

You can find a number of variables in the `variables.tf` file, all of which can be overridden by using the `-var` flag.

Here is a run down of what steps the Terraform scripts will perform:
 * Create a Namespace in Kubernetes called `snapserver`
 * Create a Secret for the Docker registry to allow K3S to pull the Docker image
 * Create a Secret for each Spotify user (you can have multiple streams per user)
 * Create a ConfigMap for the Snapserver configuration `snapserver.conf`
 * Create a PersistentVolumeClaim for the Snapserver to map
   * The FIFO volume is used to pipe the stream
   * The Logs volume is used to store the logs
   * The User volumes are used to store each user's credentials
 * Create a Deployment for the Snapserver
 * Create a Service for the Snapserver
 * Create an IngressRoute for the Snapserver (this allows you to access the Snapserver website from outside the cluster)
 * Create a Certificate for the IngressRoute through LetsEncrypt and Cert-Manager (this allows you to access the Snapserver website from outside the cluster using a trusted certificate)

Once the Terraform scripts have been run, you can access the Snapserver website by navigating to the IngressRoute URL, e.g. https://snapserver.my-domain.com.

