# Containerization Reference App for OpenLiberty Web Service Application 

  The original application is from a guide on how to create a RESTful service with Jakarta Restful Web Services, JSON-B, and Open Liberty.
  Documentation can be found here:
  https://openliberty.io/guides/rest-intro.html
  
  The application can easily be extended to include other use cases such as;
  - Consume a diplay information from a database

  ## Application Description

  - The RESTful service has 2 GET endpoints that respond at the following context root URL: http://localhost:9080/LibertyProject/ 

  1. ```/system/hello``` - returns string
  ```sh
  Hello World
  ``` 
  
  2. ```/system/properties``` - returns a JSON  of the system properties like this:
  ```sh
  {
    "os.name":"Mac",
    "java.version": "1.8"
  }
  ```
  

### Running locally
To run type:
```sh
$ mvn liberty:run
```
Application is running when you see

> The defaultServer server is ready to run a smarter planet.

Test the application, submit GET request to these endpoints: 
>http://localhost:9081/system/hello 


>http://localhost:9081/system/properties 

Home page:
>http://localhost:9081/

To stop:
```sh
CTRL+C 
or
$ mvn liberty:stop
```
<hr>


# Containerization Process
## Create Helm chart for building the project
Helm documentation: https://docs.bitnami.com/tutorials/create-your-first-helm-chart/
```sh
# create chart called build
$ helm create build
```
Update Chart, templates and values yamls (see example in this repo).

## Setup Maven credentials for Openshift source-to-image (S2I) Builds

What is source-to-image (S2I)? 
 - [source-to-image github](https://github.com/openshift/source-to-image)
 - [Redhat OCP documentation](https://docs.openshift.com/container-platform/4.10/openshift_images/using_images/using-s21-images.html)
 - [An example](https://tomd.xyz/openshift-s2i-example/)

<br>

<details>
<summary><b>Create Maven settings sealed secret</b></summary>

Running Maven commands in Openshift requires authentication to the artifactory maven repo. This is achieved by creating and using your credentials as sealed secrets.

**ARTIFACTORY_TOKEN** is required. To create one, login to [Artifactory](https://artifactory.bsc.bscal.com/artifactory/webapp/#/profile) &rarr; Click on userID on right hand corner &rarr; Create TOKEN &rarr; Copy and save token

```sh
export NAMESPACE=<namespace>
export ARTIFACTORY_USER=<LAN ID>
export M2_MASTER_PASSWORD=<LAN PASSWORD>
export ARTIFACTORY_TOKEN=<PASTE TOKEN> 
export ENCRYPTED_MASTER_PASSWORD=$(mvn --encrypt-master-password ${M2_MASTER_PASSWORD})
envsubst <settings-security.xml > ${HOME}/.m2/settings-security.xml
export ENCRYPTED_PASSWORD=$(mvn --encrypt-password ${ARTIFACTORY_TOKEN})
envsubst <settings.xml > ${HOME}/.m2/settings.xml

# Run below commands to create the sealed secret for maven settings (one time)

oc create secret generic helloworldopenshift-settings-mvn --dry-run=client --from-file=settings.xml=$HOME/.m2/settings.xml --from-file=settings-security.xml=$HOME/.m2/settings-security.xml -n ${NAMESPACE} -o yaml > /tmp/secret-settings-mvn.yaml

kubeseal -o yaml --controller-namespace sealed-secrets </tmp/secret-settings-mvn.yaml >sealedsecrets/sealedsecret-settings-mvn.yaml -n $NAMESPACE

```
</details>

## Build Application container Image
- To create and validate a ```Dockerfile``` you will need to install either Podman or Docker on your computer, however this is not possible on VDI because neither Docker nor Podman support nested virtualization. Below are a of couple ways to accomplish this task;

<details>
<summary><b>1. Using the S2I build process with a multi stage Dockerfile.builder</b></summary>

Generate your **BITBUCKET_TOKEN** from https://bitbucket.bsc.bscal.com/plugins/servlet/access-tokens/add

```sh

#OPTIONAL: export HOME=</c/Users/<LAN ID> for VDI users> 
export BITBUCKET_TOKEN=<your bitbucket token>
export BITBUCKET_USER=<your bitbucket username>

helm upgrade -i helloworldopenshift-build helm/build -n ${NAMESPACE} \
  --set secrets.bitbucket.username=${BITBUCKET_USER} \
  --set secrets.bitbucket.password=${BITBUCKET_TOKEN} \
  --set git.ref=$(git rev-parse --abbrev-ref HEAD) \
  --set git.uri=$(git config --get remote.origin.url) \
  --set-file sealedSecret.settingsMvn=sealedsecrets/sealedsecret-settings-mvn.yaml
```
</details>

<br>

<details>
<summary><b>2. Using a Privileged pod in OCP</b></summary>

> You must run the below steps as a cluster-admin in ocp for this to work
 
```sh
# export namespace to terminal
export NAMESPACE=<namespace>

# deploy the privileged pod as a cluster-admin...
helm upgrade -i podman helm/podman/ -n $NAMESPACE

# build the image (multi-stage build)...
oc exec -it devtools -n $NAMESPACE bash 
export NAMESPACE=<namespace>
cd /tmp
git config --global http.sslVerify false
git clone https://bitbucket.blueshieldca.com/scm/~agimei01/helloworldopenshift.git
cd helloworldopenshift
podman login bsc-docker-all.artifactory.bsc.bscal.com --tls-verify=false
podman build -t image-registry.openshift-image-registry.svc:5000/$NAMESPACE/helloworldopenshift:latest -f Dockerfile.builder.podman --tls-verify=false

# push to internal openshift registry...
oc login https://api.npek8s.bsc.bscal.com:6443 -u <Openshift ID> 
podman login image-registry.openshift-image-registry.svc:5000 --tls-verify=false -u  <Openshift ID> -p $(oc whoami -t) 
podman push image-registry.openshift-image-registry.svc:5000/$NAMESPACE/helloworldopenshift:latest --tls-verify=false

exit
```
</details>


## Deploy Application in Openshift

Create the application helm Chart and deploy and application to Openshift

```sh
helm upgrade -i helloworldopenshift helm/helloworldopenshift -n ${NAMESPACE} \
  --set image.repository=image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/helloworldopenshift \
  --set image.tag=latest 
```

Once deployed successfully the applicatio endpoints can be accessed by using the route provided in as follows:
Test the application, submit GET request to these endpoints: 
>https://helloworldopenshift-<NAMESPACE>.apps.npek8s.bsc.bscal.com/system/hello 


>https://helloworldopenshift-<NAMESPACE>.apps.npek8s.bsc.bscal.com//system/properties 

Home page:
>https://helloworldopenshift-<NAMESPACE>.apps.npek8s.bsc.bscal.com//


## TODO's

- Helm deploy project

- The server.xml + datasources.xml patterns.

- THE MOST DIFFICULT PART is simulating a database connection (toy DB)

- Possible just to read from a real db? ... Or we deploy something? ... But then drivers will be different if we dont connect with denodo, facits, or elastic search...

- But we can just put dead database connection patterns in the repo?

- This is still a well understood pattern even if hard to demo

- Horizontal Pod AutoScaling patterns

- NAS connections

- Monitoring use tie in (This is still kinda fuzzy because monitoring team still hasnt showed any actual integration)

- Argo Charts that can be used in a personal namespace

- Documentation that points to the "Formal Environment" CI/CD processes

- Instructions on how to involve SCRM team to get Jenkins Jobs and have pipelines used

<hr>

Markdown CheatSheet : https://www.markdownguide.org/cheat-sheet/

<details>
<summary></summary>
</details>

