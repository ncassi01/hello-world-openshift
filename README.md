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
>http://localhost:9080/LibertyProject/system/hello 


>http://localhost:9080/LibertyProject/system/properties 

Home page:
>http://localhost:9080/LibertyProject/

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

## Setup maven to use credentials in Openshift S2I Builds (Dockerfile.builder)

> Access to artifactory maven repo requires authentication when accessed in openshift. The below technique offers the ability to seal your credentials and use them to run maven commands in Openshift.

<details>
<summary><b>Create Maven settings sealed secret</b></summary>

Create an **ARTIFACTORY_TOKEN**;
-  Login to [Artifactory](https://artifactory.bsc.bscal.com/artifactory/webapp/#/profile) &rarr; Click on userID on right hand corner &rarr; Create TOKEN

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

oc create secret generic fadintegrationservicev2-settings-mvn --dry-run=client --from-file=settings.xml=$HOME/.m2/settings.xml --from-file=settings-security.xml=$HOME/.m2/settings-security.xml -n ${NAMESPACE} -o yaml > /tmp/secret-settings-mvn.yaml

kubeseal -o yaml --controller-namespace sealed-secrets </tmp/secret-settings-mvn.yaml >sealedsecrets/${PROP_ENV}/sealedsecret-${PROP_ENV}-settings-mvn.yaml

```
</details>

## Build and Deploy container Image to Openshift
- To create and validate a ```Dockerfile``` you will need to install either Podman or Docker on your computer, however this is not possible on VDI because neither Docker nor Podman support nested virtualization. Below are a of couple ways to accomplish this task;

<details>
<summary><b>1. Using the S2I (Source to Image) build process using a multi stage Dockerfile.builder</b></summary>

Generate your **BITBUCKET_TOKEN** from https://bitbucket.bsc.bscal.com/plugins/servlet/access-tokens/add

```sh

#OPTIONAL: export HOME=</c/Users/<LAN ID> for VDI users> 
export BITBUCKET_TOKEN=<your bitbucket token>
export BITBUCKET_USER=<your bitbucket username>

helm upgrade -i helloworldopenshift-build helm/build -n ${NAMESPACE} \
  --set secrets.bitbucket.username=${BITBUCKET_USER} \
  --set secrets.bitbucket.password=${BITBUCKET_TOKEN} \
  --set git.ref=$(git rev-parse --abbrev-ref HEAD) \
  --set git.uri=$(git config --get remote.origin.url)
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
podman build -t image-registry.openshift-image-registry.svc:5000/$NAMESPACE/helloworldopenshift:latest -f Dockerfile.builder --tls-verify=false

# push to internal openshift registry...
oc login -u <Openshift ID> https://api.npek8s.bsc.bscal.com:6443
podman login -u  <Openshift ID> -p $(oc whoami -t) image-registry.openshift-image-registry.svc:5000 --tls-verify=false
podman push image-registry.openshift-image-registry.svc:5000/$NAMESPACE/helloworldopenshift:latest --tls-verify=false

exit
```
</details>


## TODO's

- The Dockerfiles

- Helm deploy project

- The server.xml + datasources.xml patterns.

- THE MOST DIFFICULT PART is simulating a database connection (toy DB)

- Possible just to read from a real db? ... Or we deploy something? ... But then drivers will be different if we dont connect with denodo, facits, or elastic search...

- But we can just put dead database connection patterns in the repo?

- This is still a well understood pattern even if hard to demo

- The build/ deploy helm charts

- An example of sealing of some secrets (already very well documented)

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

