---
layout: docpage
prereq:
  - text: Checks
    link: documentation/checks.html
  - text: Event Listeners
    link: documentation/events.html
---

# Analysis Outputs

Output files can be created by users of LiSA at any point during the analysis: all
that is needed is to create an output stream to a file and write to it. However,
LiSA adopts a more schematic approach. By relying purely on LiSA's APIs, all
components that have a `FileManager` reference can create output files. Such
components are `Check`s and `EventListener`s, both through the `ReportingTool`
reference that their callbacks accept as parameter.

{% include diagrams.html %}

## The FileManager class

<center><img src="{{ site.baseurl }}/schemes/file-manager.png" alt="FileManager class diagram" style="width: 70%"></center>

The `FileManager` class is the main API for file management in LiSA. It
provides utilities for creating output files by providing a filler action (i.e.,
a function that consumes a `Writer` instance to write to the output file) or for
creating `BufferedWriter` instances pointint to specific files. In both cases,
file creation happens by creating a file with the given `name` that is created
**inside the working directory of the analysis**, as identified by the
configuration passed to LiSA. More information about the working directory and
how it can be set can be found in the [Configuration page]({{ site.baseurl }}/configuration/).
Optionally, a `path` can be specified to create the file in a subdirectory of the working
directory.

A `FileManager` instance is accessible from the `ReportingTool` passed to both
`Check`s and `EventListener`s: thus, both these components can also create output
files during their execution.
