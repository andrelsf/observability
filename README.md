sum(otelcol_exporter_sent_spans offset 1m) by (exporter)


# Instrumentacao Automatica com Agente Otel

```shell
-javaagent:src/main/resources/opentelemetry/opentelemetry-javaagent.jar
-Dotel.service.name=mc-assessments
-Dotel.traces.exporter=otlp
-Dotel.metrics.exporter=none
-Dotel.logs.exporter=none
-Dotel.exporter.otlp.traces.endpoint=http://localhost:4317
-Dotel.instrumentation.jdbc.enabled=false
-Dotel.instrumentation.jdbc-datasource.enabled=false
-Dotel.instrumentation.spring-data.enabled=false
-Dotel.instrumentation.hibernate.enabled=false
```

---

# Instrumentacao AutoConfigure Java

```xml
<!-- Open Telemetry Starter -->
<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-spring-boot-starter</artifactId>
    <version>1.23.0-alpha</version>
</dependency>

<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-spring-boot</artifactId>
    <version>1.23.0-alpha</version>
</dependency>

<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-spring-webflux-5.0</artifactId>
    <version>1.23.0-alpha</version>
</dependency>

<!-- Open Telemetry OTLP Exporter -->
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
    <version>1.23.0</version>
</dependency>

```

```yaml
otel:
  springboot:
    resource:
      attributes:
        environment: ${spring.profiles.active}
    aspects:
      enabled: false
  exporter:
    otlp:
      enabled: true
      endpoint: http://localhost:4317
    jaeger:
      enabled: false
    zipkin:
      enabled: false
    logging:
      enabled: false
```

```java
@Configuration
@EnableConfigurationProperties({ LoggingExporterProperties.class, SamplerProperties.class })
public class OpenTelemetryAutoConfiguration {

  public OpenTelemetryAutoConfiguration() {}

  @Configuration
  @ConditionalOnMissingBean(OpenTelemetry.class)
  public static class OpenTelemetryBeanConfig {

    @Bean
    @ConditionalOnMissingBean
    public SdkTracerProvider sdkTracerProvider(
        SamplerProperties samplerProperties,
        ObjectProvider<List<SpanExporter>> spanExportersProvider,
        Resource otelResource) {

      SdkTracerProviderBuilder tracerProviderBuilder = SdkTracerProvider.builder();
      spanExportersProvider.getIfAvailable(Collections::emptyList).stream()
          .map(spanExporter -> BatchSpanProcessor.builder(spanExporter).build())
          .forEach(tracerProviderBuilder::addSpanProcessor);
      return tracerProviderBuilder
          .setResource(otelResource)
          .setSampler(Sampler.traceIdRatioBased(samplerProperties.getProbability()))
          .addSpanProcessor(BatchSpanProcessor.builder(LoggingSpanExporter.create()).build())
          .build();
    }

    @Bean
    @ConditionalOnMissingBean
    public Resource otelResource(Environment env, ObjectProvider<List<ResourceProvider>> resourceProviders) {
      ConfigProperties config = new SpringResourceConfigProperties(env, new SpelExpressionParser());
      Resource resource = Resource.getDefault();
      for (ResourceProvider resourceProvider :
          resourceProviders.getIfAvailable(Collections::emptyList)) {
        resource = resource.merge(resourceProvider.createResource(config));
      }
      return resource;
    }

    @Bean
    public OpenTelemetry openTelemetry(ObjectProvider<ContextPropagators> propagatorsProvider, SdkTracerProvider tracerProvider) {
      ContextPropagators propagators = propagatorsProvider.getIfAvailable(ContextPropagators::noop);
      return OpenTelemetrySdk.builder()
          .setTracerProvider(tracerProvider)
          .setPropagators(propagators)
          .build();
    }
  }
}