allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.withType<JavaCompile> {
    sourceCompatibility = JavaVersion.VERSION_17.toString()
    targetCompatibility = JavaVersion.VERSION_17.toString()
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions {
        jvmTarget = "17"
    }
}

// clean-задача
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}