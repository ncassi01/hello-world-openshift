# Containerization Reference App for OpenLiberty Web Service Application 

  The original application is from a guide on how to create a RESTful service with Jakarta Restful Web Services, JSON-B, and Open Liberty.

  - Documentation can be found here:
  https://openliberty.io/guides/rest-intro.html

  ## Application Description

  - The RESTful service has 2 endpoints to GET requests made to the http://localhost:9080/LibertyProject/ as below;

  1. ```/system/properties``` - returns a JSON  of the system properties like this:

  ```sh
  {
    "os.name":"Mac",
    "java.version": "1.8"
  }
  ```
  2. ```/system/hello``` - returns string
  ```sh
  Hello World
  ```

### Running locally
To run type:
```sh
$ mvn liberty:run
```
Application is running when you see

> The defaultServer server is ready to run a smarter planet.

Test the application, submit GET request to this endpoint: 
>http://localhost:9080/LibertyProject/system/properties 

Home page:
>http://localhost:9080/LibertyProject/

To stop:
```sh
CTRL+C 
or
$ mvn liberty:stop
```

# Containerization Process
## Create Helm chart for building the project
Helm documentation: https://docs.bitnami.com/tutorials/create-your-first-helm-chart/
```sh
$ helm create build
```

## TODO's

### Build and Deploy to Openshift

```sh
# generate your bitbucket token from https://bitbucket.bsc.bscal.com/plugins/servlet/access-tokens/add
export BITBUCKET_TOKEN=<your bitbucket token>
export BITBUCKET_USER=<your bitbucket username>
export NAMESPACE=<namespace>

helm upgrade -i helloworldopenshift-build helm/build -n ${NAMESPACE} \
  --set secrets.bitbucket.username=${BITBUCKET_USER} \
  --set secrets.bitbucket.password=${BITBUCKET_TOKEN} \
  --set git.ref=$(git rev-parse --abbrev-ref HEAD) \
  --set git.uri=$(git config --get remote.origin.url)
```

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

