val enforcedKotlinVersion = "2.1.0"

buildscript {
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    buildscript {
        configurations.configureEach {
            resolutionStrategy.eachDependency {
                if (requested.group == "org.jetbrains.kotlin") {
                    useVersion("2.1.0")
                }
            }
        }
    }
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    configurations.matching { config ->
        config.name.contains("implementation", ignoreCase = true) ||
            config.name.contains("compileOnly", ignoreCase = true) ||
            config.name.contains("runtimeOnly", ignoreCase = true)
    }.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion(enforcedKotlinVersion)
            }
            if (requested.group == "androidx.concurrent" &&
                requested.name == "concurrent-futures"
            ) {
                useVersion("1.2.0")
            }
        }
    }
    plugins.withId("com.android.application") {
        dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
    }
    plugins.withId("com.android.library") {
        dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
