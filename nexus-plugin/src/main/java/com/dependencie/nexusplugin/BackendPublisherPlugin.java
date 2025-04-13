package com.dependencie.nexusplugin;

import org.gradle.api.Plugin;
import org.gradle.api.Project;


public class BackendPublisherPlugin implements Plugin<Project> {

    @Override
    public void apply(Project project) {
        project.getPluginManager().apply("java");
        project.getPluginManager().apply("org.springframework.boot");
        project.getPluginManager().apply("io.spring.dependency-management");

        project.setGroup("com.example");
        project.setVersion("0.0.1-SNAPSHOT");

        project.getExtensions().getExtraProperties().set("springBootVersion", "3.4.4");

        project.getRepositories().mavenCentral();

        project.getDependencies().add("implementation", "org.springframework.boot:spring-boot-starter-data-jpa");
        project.getDependencies().add("implementation", "org.springframework.boot:spring-boot-starter-web");
        project.getDependencies().add("implementation", "org.springframework.boot");
        project.getDependencies().add("compileOnly", "org.projectlombok:lombok");
        project.getDependencies().add("runtimeOnly", "com.h2database:h2");
        project.getDependencies().add("annotationProcessor", "org.projectlombok:lombok");
        project.getDependencies().add("testImplementation", "org.springframework.boot:spring-boot-starter-test");
        project.getDependencies().add("testRuntimeOnly", "org.junit.platform:junit-platform-launcher");
    }
}
