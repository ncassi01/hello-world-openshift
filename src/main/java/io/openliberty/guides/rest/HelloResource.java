package io.openliberty.guides.rest;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

// tag::path[]
@Path("hello")
// end::path[]
public class HelloResource {

    // tag::get[]
    @GET
    // end::get[]
    // tag::produces[]
    @Produces(MediaType.APPLICATION_JSON)
    // end::produces[]
    public String getHello() {
        return "Hello World";
    }

}
