package it.dev.appsody.starter;


import static org.junit.jupiter.api.Assertions.*;



import org.junit.jupiter.api.Test;
import org.microshed.testing.jaxrs.RESTClient;
import org.microshed.testing.jupiter.MicroShedTest;
import org.microshed.testing.testcontainers.ApplicationContainer;
import org.testcontainers.junit.jupiter.Container;
import dev.appsody.starter.StarterResource;

@MicroShedTest
public class JaxrsTestit {
	
	@Container
    public static ApplicationContainer app = new ApplicationContainer()
                    .withAppContextRoot("/")
                    .withReadinessPath("/health/ready");
                    
	
	@RESTClient 
	public static StarterResource appService;
	
	
	@Test
	public void testAppResponse() {
		   assertEquals("Hello! Welcome to Openliberty", appService.getRequest());
	}
	               
}