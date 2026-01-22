---
notoc: true
---

# LiSA

LiSA (Library for Static Analysis) aims to ease the creation and implementation
of sound static analyzers based on the Abstract Interpretation theory. LiSA provides
an analysis engine that works on a generic and extensible control flow graph
representation of the program to analyze. Abstract interpreters in LiSA are
built for analyzing such representation, providing a unique analysis
infrastructure for all the analyzers that will rely on it.

Building an analyzer upon LiSA boils down to writing a parser for the language
that one aims to analyze, translating the source code or the compiled code
towards the control flow graph representation of LiSA. Then, simple checks
iterating over the results provided by the semantic analyses of LiSA can be
easily defined to translate semantic information into warnings that can be of
value for the final user.

{% include important.html content="LiSA is a research project under active
development. Some features might be incomplete or missing,
and the API might change in future releases. We will do our best to
self-document this through semantic versioning, but things might break
nonetheless." %}

### How to contrubute

LiSA is developed and maintained by the [Software and System Verification
(SSV)](https://ssv.dais.unive.it/) group @ Università Ca' Foscari in Venice,
Italy. External contributions are always welcome! Check out our [contributing
guidelines](https://github.com/lisa-analyzer/lisa/blob/master/CONTRIBUTING.md)
for information on how to contribute to LiSA.

### Contents

This website describes LiSA's architecture and provides guides on how to use and
extend it. It is intended to be valid for the latest stable release of LiSA,
but should be compatible with versions 0.2 and later. Signatures or packages
might differ in older versions, but the overall architecture and design
principles should remain the same.

Head to [Tutorials]({{ site.baseurl }}/tutorials/) for a list of guides and
tutorials on how to work with LiSA. The [Structure]({{ site.baseurl
}}/structure/) page describes LiSA's inputs, outputs and how the internal
mechanics are structured, while [Configuration]({{ site.baseurl
}}/configuration/) describes the available options and the available component
implementations. [IMP]({{ site.baseurl }}/imp/) is a simple documentation of the
object-oriented IMP language used for internal testing and POCs. Visit
[Resources]({{ site.baseurl }}/material/) for a collection of papers and
presentations discussing LiSA.
