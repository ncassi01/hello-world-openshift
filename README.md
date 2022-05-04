# Containerization Guide with OpenLiberty Web Service Reference Application 

## Guide Description
This repo contains a step by step guide on how to containerize and deploy a JEE/Java webservice application. The steps can also be reused for other applications with slight divergence were the steps are technology specific. These were the steps used to containerize the FAD AIP Services.

## Application Description

The application exposes RESTful services using Jakarta Restful Web Services, JSON-B, and Open Liberty.

  - It has 2 GET endpoints that respond at the following context root URL: http://localhost:9080/ 

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

Additional documentaion on the base application can be found here;
  https://openliberty.io/guides/rest-intro.html
  

### How to run application locally
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


# Containerizing and running application on Openshift

## Step 1: Create a ```Dockerfile``` or ```Containerfile```

- There are 3 ways to do this

### 1. Using Docker or Podman
- To create and validate a ```Dockerfile``` you will need to install either Podman or Docker on your computer.
- [Dockerfile checklist](https://grid.blueshieldca.com/display/RHT/Dockerfile+Checklist)


### 2. Using Openshift S2I Process
>What is source-to-image (S2I)? 
> - [source-to-image github](https://github.com/openshift/source-to-image)
> - [Redhat OCP documentation](https://docs.openshift.com/container-platform/4.10/openshift_images/using_images/using-s21-images.html)
> - [An example](https://tomd.xyz/openshift-s2i-example/)
>
 
- Create a multi-stage Dockerfile that will compile the code and and then build the image (see ```Dockerfile.builder```)
- Create helm chart to deploy the S2I's ```deployconfig``` and ```imagestream``` resources for building and saving application image to the internal registry. 

Helm documentation: https://docs.bitnami.com/tutorials/create-your-first-helm-chart/
```sh
# create chart called build
$ helm create build
# Update Chart, templates and values yamls (see example in this repo).
```

- The maven build stage requires credentials to login to artifactory, the following steps creates sealed secrets to be passed to the process

<b>Steps to create Maven settings sealed secret</b>

- Get an **ARTIFACTORY_TOKEN**. To create one, login to [Artifactory](https://artifactory.bsc.bscal.com/artifactory/webapp/#/profile) &rarr; Click on userID on right hand corner &rarr; Create TOKEN &rarr; Copy and save token
- use the below steps on a terminal to seal the ```settings.xml``` and ```security-settings.xml``` with artifactory credentials to be used in the maven build.
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
#### Deploy ```buildconfig``` with helm to compile and build application image.

- Generate your **BITBUCKET_TOKEN** from https://bitbucket.bsc.bscal.com/plugins/servlet/access-tokens/add
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

### 3. Using a Privileged pod in OCP

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


## Step 2: Deploying Application to ```Openshift```

Create the application helm Chart and deploy and application to Openshift

```sh
helm upgrade -i helloworldopenshift helm/helloworldopenshift -n ${NAMESPACE} \
  --set image.repository=image-registry.openshift-image-registry.svc:5000/${NAMESPACE}/helloworldopenshift \
  --set image.tag=latest 
```

> Once deployed successfully the applicatio endpoints can be accessed by using the route provided in as follows:
> Test the application, submit GET request to these endpoints: 
> https://helloworldopenshift-$NAMESPACE.apps.npek8s.bsc.bscal.com/system/hello 
>
> https://helloworldopenshift-$NAMESPACE.apps.npek8s.bsc.bscal.com//system/properties 
> 
> Home page:
> https://helloworldopenshift-$NAMESPACE.apps.npek8s.bsc.bscal.com/
>

# TODO's (Patterns)

## Sealed Secrets Pattern
- How to create a sealed secret

## Database connections Pattern
- The server.xml + datasources.xml patterns. Simulating a database connection Will require development hours. Possible just to read from a real db? ... Or we deploy something? ... But then drivers will be different if we dont connect with denodo, facets, or elastic search. Suggestion is to document the pattern without any DB connections and point to implementation on existing repos with pattern namely FADIntegrationServiceV2, ProviderReviewServiceV2, ProviderSearchDataServiceV3, ProviderSearchMetaDataServiceV2.

## NAS Pertistent Volumes Pattern
- Similar to above implemented in DowloadProviderSearchPDFServiceV2, ProviderSearchDataServicev2, ProviderSearchDataServicev3

## Horizontal Pod AutoScaling patterns
- Implementable in for this app

## CICD Pattern
- Jenkins CI
- ArgoCD 
- Instructions on how to engage SCRM team to get Jenkins Jobs and have pipelines used

## Observability Patterns
- Monitoring use tie in (This is still kinda fuzzy because monitoring team still hasnt showed any actual integration)
- Service Mesh 

<hr>

Markdown CheatSheet : https://www.markdownguide.org/cheat-sheet/


