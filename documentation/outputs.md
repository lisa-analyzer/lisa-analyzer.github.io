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

https://github.com/lisa-analyzer/lisa/blob/master/lisa/lisa-sdk/src/main/java/it/unive/lisa/util/file/FileManager.java

Anywhere there is a reference you can create an output

## The LiSAReport class

https://github.com/lisa-analyzer/lisa/blob/master/lisa/lisa-sdk/src/main/java/it/unive/lisa/LiSARunInfo.java
https://github.com/lisa-analyzer/lisa/blob/master/lisa/lisa-sdk/src/main/java/it/unive/lisa/LiSAReport.java
Additional info

## The LiSAOutput interface

Deferred execution of report outputs

https://github.com/lisa-analyzer/lisa/blob/master/lisa/lisa-sdk/src/main/java/it/unive/lisa/outputs/LiSAOutput.java
https://github.com/lisa-analyzer/lisa/blob/master/lisa/lisa-sdk/src/main/java/it/unive/lisa/LiSA.java#L70
