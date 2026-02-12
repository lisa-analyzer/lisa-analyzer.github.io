# Building from source

| <name>Goal:</name> retrieve the source code of LiSA and build it locally |
| <name>LiSA release used:</name> 0.2 |
| <name>Requirements:</name> [JDK 11](https://www.oracle.com/it/java/technologies/javase/jdk11-archive-downloads.html), [Git](https://git-scm.com/downloads)
| <name>Note:</name> you should build from source only if you plan to work directly on LiSA itself, or if you need to work with an unreleased version. If you want to use LiSA as-is instead, please refer to the [Creating a project using LiSA]({{ site.baseurl}}/get-started/maven-dependency.md) tutorial instead. |
{:.tutorialheader}

---

LiSA comes as a [Gradle](https://gradle.org/) 8.10 project. Gradle can be
executed through a local wrapper without downloading and installing a
centralized version of it, and LiSA comes with a wrapper! You'll always be able
to build LiSA with the version of Gradle it is meant to be compiled with,
without spending time managing your own Gradle installation.

The instructions for building LiSA are straightforward. On Linux/Mac, you can
execute:

```bash
git clone git@github.com:lisa-analyzer/lisa.git
cd lisa/lisa
./gradlew completeBuild
```

The above commands will clone the repository, navigate into the cloned folder,
navigate inside the `lisa` subfolder (which is the root of the Gradle project),
and execute a complete build (generating sources, compiling, packaging and running tests).
Note that building must be performed from the command line **before** importing
LiSA into an IDE, otherwise the IDE will signal errors due to missing generated sources.

On Windows, the commands are the same, except for the Gradle script to execute:

```batch
git clone git@github.com:lisa-analyzer/lisa.git
cd lisa\lisa
.\gradlew.bat completeBuild
```

---

The `build` task ensures that everything (from code generation to compilation,
packaging and test execution) works fine. If the above commands succeed, then
everthing is set. You can now import the project in any IDE of your choice.

## Next steps

Now that you know how to build LiSA (and optionally import it into an IDE), you
can immediately start implementing new components directly on LiSA.
