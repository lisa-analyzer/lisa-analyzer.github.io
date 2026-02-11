# Creating a project using LiSA

| <name>Goal:</name> using an official release of LiSA as a dependency of your project |
| <name>LiSA release used:</name> 0.2 |
| <name>Requirements:</name> [JDK 11](https://www.oracle.com/it/java/technologies/javase/jdk11-archive-downloads.html), a build tool of your choice (the tutorial will use [Gradle](https://gradle.org/), but steps for other build tools are the same) |
{:.tutorialheader}

---

Setting up a project that uses LiSA can be achieved with few simple steps, the
first one being creating an empty Java project. The procedure depends on the
build system or IDE you decide to use. For this tutorial, we will be using
Gradle 8.14 with no IDE.

### Creating the project

Navigate to the folder where you want to create the project and open a terminal
there. To create the project, execute `gradle init` and follow the instructions
on screen to create the project. Note that, if you don't have Gradle binaries
on your `PATH`, you will have to add the full path to the Gradle executable at
the beginning of the command. The output on your terminal should look like
this:

```
$ gradle init

Select type of build to generate:
  1: Application
  2: Library
  3: Gradle plugin
  4: Basic (build structure only)
Enter selection (default: Application) [1..4] 4

Project name (default: tmp): test-app

Select build script DSL:
  1: Kotlin
  2: Groovy
Enter selection (default: Kotlin) [1..2] 2

Generate build using new APIs and behavior (some features may change in the next minor release)? (default: no) [yes, no] no


> Task :init
Learn more about Gradle by exploring our Samples at https://docs.gradle.org/8.14/samples

BUILD SUCCESSFUL in 28s
1 actionable task: 1 executed
```

Note that the choices you make to create the project can be different from the
ones reported in the example. If the creation is successfull, the contents on
your folder should now be like this:

```bash
$ ls -lah
total 48K
drwxrwxr-x 3 group user 4,0K feb 11 11:44 .
drwxr-xr-x 8 group user 4,0K feb 11 11:42 ..
-rw-rw-r-- 1 group user  199 feb 11 11:44 build.gradle
-rw-rw-r-- 1 group user  278 feb 11 11:44 .gitattributes
-rw-rw-r-- 1 group user  103 feb 11 11:44 .gitignore
drwxrwxr-x 3 group user 4,0K feb 11 11:44 gradle
-rw-rw-r-- 1 group user  194 feb 11 11:44 gradle.properties
-rwxrwxr-x 1 group user 8,6K feb 11 11:44 gradlew
-rw-rw-r-- 1 group user 2,9K feb 11 11:44 gradlew.bat
-rw-rw-r-- 1 group user  344 feb 11 11:44 settings.gradle
```

### Adding the LiSA dependency

The next step is to add a dependency from your project to LiSA. To to this,
navigate to LiSA's [Maven page](https://central.sonatype.com/search?q=g:io.github.lisa-analyzer) and pick the
version of `lisa-sdk`, `lisa-analyses`, `lisa-program`, and `lisa-imp`
that you want to use. Opening the page of
that release (i.e. clicking on the version number) opens a page with snippets
that can be directly copied into the configuration file of the build system to
add the dependency. While `lisa-sdk` is always needed (as it contains all the
components definitions), `lisa-analyses` is required only if you want to execute an
analysis provided by LiSA, `lisa-program` is required only if you want to use simple program
components, and `lisa-imp` is required only if you want to use the IMP frontend.
However, since `lisa-analyses` directly depends on `lisa-sdk`, you can just depend
on the latter to get both of them.

Proceed by copying the snippet you need and add it to your `build.gradle` inside the
`dependencies` section, filling also the rest of the build file:

```groovy
// this is the groovy syntax for gradle, kotlin is also available

plugins {
    // tell Gradle that this is a Java command line application
    id 'application'
}

repositories {
    // use the maven central server to resolve dependencies
    mavenCentral()
}

dependencies {
    // add a depenency to LiSA
    implementation 'io.github.lisa-analyzer:lisa-analyses:0.2'
}

application {
    // tell Gradle which class is contains the main method
    mainClass = 'test.app.App'
}
```

Note that the scope of the dependency can be customized according to your
needs. See
[here](https://docs.gradle.org/current/userguide/declaring_dependencies.html)
for details on Gradle configuration, but similar documents exists also for
other build systems.

### Test your setup

After adding the dependency, you are able to reference all classes defined in
LiSA. You can test it by creating the Java file
`src/main/java/test/app/App.java` with the following content:

```java
package test.app;

import it.unive.lisa.DefaultConfiguration;
import it.unive.lisa.util.numeric.IntInterval;

public class App {
    public static void main(String[] args) {
        // this class is defined inside lisa-sdk
        System.out.println(new IntInterval(5, 5));

        // this class is defined inside lisa-analyses
        System.out.println(new DefaultConfiguration());
    }
}
```

The `main` method in the `App` class simply references two classes, one from
each LiSA project, to ensure that the dependencies are correctly added on the
classpath at compile- and run-time.

You can now execute `gradle run`, that implicitly builds and executes the project:

```bash
$ gradle run

> Task :run
2026-02-11 11:58:49,233 [ WARN] No Log4j configuration found, using default configuration
[5, 5]
LiSA configuration:
  syntacticChecks (0)
  semanticChecks (0)
  outputs (0)
  workdir: /home/luca/Desktop/tmp
  wideningThreshold: 5
  recursionWideningThreshold: 5
  glbThreshold: 5
  forwardFixpoint: ForwardAscendingFixpoint
  forwardDescendingFixpoint: unset
  backwardFixpoint: BackwardAscendingFixpoint
  backwardDescendingFixpoint: unset
  fixpointWorkingSet: OrderBasedWorkingSet
  openCallPolicy: TopExecutionPolicy
  useWideningPoints: true
  hotspots: unset
  dumpForcesUnwinding: false
  shouldSmashError: unset
  synchronousListeners (0)
  asynchronousListeners (0)

BUILD SUCCESSFUL in 1s
2 actionable tasks: 2 executed
```

If your output is similar to the above, congratulations! You successfully
created your first project that uses LiSA.
