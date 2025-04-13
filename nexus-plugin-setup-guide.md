
# Setting Up Nexus Repository on AWS EC2 with Terraform and Publishing a Custom Gradle Plugin

## 1. Introduction to Sonatype Nexus

### What is Sonatype Nexus?
Sonatype Nexus is a powerful, open-source repository manager that allows organizations to store and manage software artifacts. It supports both internal and external repositories for various package formats such as Maven, npm, NuGet, Docker, and more. Nexus helps in managing and distributing binary artifacts, ensuring efficient version control and secure access to packages within an organization.

### Why Use Nexus?
Nexus Repository provides several benefits:
- **Centralized Artifact Management**: Nexus stores artifacts like libraries, dependencies, and Docker images, making them easy to share and reuse across different projects.
- **Secure Artifact Distribution**: It allows for secure access to artifacts through permissions and policies, preventing unauthorized access and ensuring the integrity of software artifacts.
- **Supports Multiple Formats**: Nexus supports different repository formats such as Maven, npm, Docker, etc., making it flexible and adaptable for various development environments.
- **Integration with Build Systems**: Nexus can be integrated into CI/CD pipelines for automated artifact management and deployment.

---

## 2. Project Overview

In this project, we automated the installation of Sonatype Nexus on an AWS EC2 instance using Terraform and demonstrated the publishing and usage of a custom Gradle plugin through Nexus.

The project is divided into three major parts:
1. **Deploy Nexus via Terraform**  
2. **Create and Publish a Custom Gradle Plugin to Nexus**  
3. **Use the Published Plugin in a Spring Boot Backend Project**

---

## 3. Deploying Nexus Using Terraform

We created a Terraform configuration to:
- Launch an EC2 instance
- Install Java and Nexus via a shell script
- Set up Nexus as a system service
- Open port `8081` to access Nexus UI

**Key Terraform Files:**

### `main.tf`
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "nexus" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 or Ubuntu AMI
  instance_type = "t2.medium"
  key_name      = "your-key-pair"

  vpc_security_group_ids = [aws_security_group.nexus_sg.id]

  user_data = file("install-nexus.sh")
}

resource "aws_security_group" "nexus_sg" {
  name        = "nexus_sg"
  description = "Allow Nexus and SSH"

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### `install-nexus.sh`
This bash script installs Java 8, sets up a `nexus` user, installs Nexus, and starts it as a systemd service.

---

## 4. Creating a Custom Gradle Plugin

We created a Gradle plugin project to define reusable logic. Here’s how:

### `build.gradle`
```groovy
plugins {
    id 'java-gradle-plugin'
    id 'maven-publish'
}

group = 'com.dependencie'
version = '1.0.0-SNAPSHOT'

repositories {
    mavenCentral()
}

dependencies {
    implementation gradleApi()
    implementation localGroovy()
}

gradlePlugin {
    plugins {
        backendPublisher {
            id = 'com.dependencie.nexusplugin'
            implementationClass = 'com.dependencie.nexusplugin.BackendPublisherPlugin'
        }
    }
}

publishing {
    repositories {
        maven {
            name = "nexusSnapshots"
            url = uri("http://<your-ec2-ip>:8081/repository/maven-snapshots/")
            allowInsecureProtocol = true
            credentials {
                username = "admin"
                password = "12345"
            }
        }
    }
}
```

### Plugin Implementation (`BackendPublisherPlugin.java`)
```java
package com.dependencie.nexusplugin;

import org.gradle.api.Plugin;
import org.gradle.api.Project;

public class BackendPublisherPlugin implements Plugin<Project> {
    @Override
    public void apply(Project project) {
        project.getTasks().create("helloPlugin", task -> {
            task.doLast(action -> {
                System.out.println("✅ Custom Nexus Plugin Applied Successfully!");
            });
        });
    }
}
```

### Publishing the Plugin
Run this in the plugin project root:
```bash
./gradlew publish
```

The plugin will be published to your Nexus snapshot repository.

---

## 5. Using the Custom Plugin in a Backend Project

Once published, we integrated the custom plugin into a Spring Boot project.

### Backend Project Structure

**`settings.gradle`**
```groovy
pluginManagement {
    repositories {
        maven {
            url = uri("http://<your-ec2-ip>:8081/repository/maven-snapshots/")
            allowInsecureProtocol = true
            credentials {
                username = "admin"
                password = "12345"
            }
        }
        gradlePluginPortal()
        mavenCentral()
    }
}
rootProject.name = 'employee-management'
```

**`build.gradle`**
```groovy
plugins {
    id 'com.dependencie.nexusplugin' version '1.0.0-SNAPSHOT'
    id 'java'
    id 'org.springframework.boot' version '3.4.4'
    id 'io.spring.dependency-management' version '1.1.7'
}

group = 'com.example'
version = '0.0.1-SNAPSHOT'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
}

repositories {
    mavenCentral()
    maven {
        url = uri("http://<your-ec2-ip>:8081/repository/maven-snapshots/")
        allowInsecureProtocol = true
        credentials {
            username = "admin"
            password = "12345"
        }
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    runtimeOnly 'com.h2database:h2'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

tasks.named('test') {
    useJUnitPlatform()
}
```

### Verify Plugin Integration
Run:
```bash
./gradlew helloPlugin
```

Output:
```
✅ Custom Nexus Plugin Applied Successfully!
```

---

## 6. Conclusion

In this end-to-end setup, we:
- Deployed Sonatype Nexus on AWS EC2 using Terraform
- Created and published a custom Gradle plugin to Nexus
- Integrated that plugin into a Spring Boot backend project

This setup can be expanded further to publish internal libraries, enforce quality gates, or share reusable Gradle logic across teams.
