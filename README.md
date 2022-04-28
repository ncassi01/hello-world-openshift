# Simple OpenLiberty RESTful web service for Openshift containerization

  - Documentation can be found here:
  https://openliberty.io/guides/rest-intro.html

  - Download original code here:
  https://github.com/openliberty/guide-rest-intro.git

  - The RESTful service responds to GET requests made to the http://localhost:9080/LibertyProject/system/properties URL.

  - The service responds to a GET request with a JSON representation of the system properties, where each property is a field in a JSON object, like this:

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

