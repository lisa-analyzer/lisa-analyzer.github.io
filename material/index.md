# Resources and Publications

## Releases

Details on the latest official release of LiSA can be found on the
[GitHub releases page](https://github.com/lisa-analyzer/lisa/releases).
There, you can find release notes, source code archives, and links to
pre-built binaries that are publihed on Maven Central.

<center>
  <a href="https://central.sonatype.com/artifact/io.github.lisa-analyzer/lisa-sdk"><img alt="LiSA SDK Latest Release" src="https://img.shields.io/maven-central/v/io.github.lisa-analyzer/lisa-sdk?strategy=highestVersion&style=flat-square&logo=apachemaven&label=LiSA%20SDK&color=brightgreen"/></a>
  &nbsp;
  <a href="https://central.sonatype.com/artifact/io.github.lisa-analyzer/lisa-analyses"><img alt="LiSA Analyses Latest Release" src="https://img.shields.io/maven-central/v/io.github.lisa-analyzer/lisa-analyses?strategy=highestVersion&style=flat-square&logo=apachemaven&label=LiSA%20Analyses&color=brightgreen"/></a>
  &nbsp;
  <a href="https://central.sonatype.com/artifact/io.github.lisa-analyzer/lisa-program"><img alt="LiSA Program Latest Release" src="https://img.shields.io/maven-central/v/io.github.lisa-analyzer/lisa-program?strategy=highestVersion&style=flat-square&logo=apachemaven&label=LiSA%20Program&color=brightgreen"/></a>
  &nbsp;
  <a href="https://central.sonatype.com/artifact/io.github.lisa-analyzer/lisa-imp"><img alt="LiSA IMP Latest Release" src="https://img.shields.io/maven-central/v/io.github.lisa-analyzer/lisa-imp?strategy=highestVersion&style=flat-square&logo=apachemaven&label=LiSA%20IMP&color=brightgreen"/></a>
</center>

The snapshot of the last commit of the `master` branch is always available on
[GitHub Packages](https://github.com/orgs/lisa-analyzer/packages?repo_name=lisa).
Be aware that you will need a personal access token to use
packages as server for resolving dependencies. You can refer to the official
GitHub guide for [Maven](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-apache-maven-registry#authenticating-to-github-packages)
or [Gradle](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-gradle-registry#authenticating-to-github-packages) for more information.

## Javadoc

An additional source of documentation is LiSA's javadoc, that is published
alongside each release. Your IDE should be able to automatically fetch it
when you add LiSA as a dependency to your project. Otherwise, you can find
it online:

<center>
  <a href="https://javadoc.io/doc/io.github.lisa-analyzer/lisa-sdk"><img src="https://img.shields.io/badge/LiSA%20SDK-javadoc.io-brightgreen?style=flat-square&logo=readthedocs" alt="LiSA SDK javadoc link"/></a>
  &nbsp;
  <a href="https://javadoc.io/doc/io.github.lisa-analyzer/lisa-analyses"><img src="https://img.shields.io/badge/LiSA%20Analyses-javadoc.io-brightgreen?style=flat-square&logo=readthedocs" alt="LiSA Analyses javadoc link"/></a>
  &nbsp;
  <a href="https://javadoc.io/doc/io.github.lisa-analyzer/lisa-program"><img src="https://img.shields.io/badge/LiSA%20Program-javadoc.io-brightgreen?style=flat-square&logo=readthedocs" alt="LiSA Program javadoc link"/></a>
  &nbsp;
  <a href="https://javadoc.io/doc/io.github.lisa-analyzer/lisa-imp"><img src="https://img.shields.io/badge/LiSA%20IMP-javadoc.io-brightgreen?style=flat-square&logo=readthedocs" alt="LiSA IMP javadoc link"/></a>
</center>

## Publications

{% include warn.html content="Note that some of these publications might refer to older versions of LiSA,
and thus some details might be outdated. Nonetheless, they can provide useful
insights on LiSA's design and capabilities." %}

{% include important.html content="If you have published a paper using LiSA and would like it to be listed here,
open an <a href=\"https://github.com/lisa-analyzer/lisa-analyzer.github.io/issues\">issue</a>
to let us know so that we can add it to this list!" %}

The <i class="fas fa-laptop-code"></i> icon indicates and links the frontend used in the publication, if any.

### Publications describing LiSA

<ins>Luca Negrini</ins> (2023).
**A Generic Framework for Multilanguage Analysis.**
Ph.D. thesis, Ca' Foscari University of Venice.<br/>
<small>[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/phd-thesis.pdf)</small>

<ins>Luca Negrini, Vincenzo Arceri, Luca Olivieri, Agostino Cortesi, Pietro Ferrara</ins> (2024).
**Teaching Through Practice: Advanced Static Analysis with LiSA.**
In: Sekerinski, E., Ribeiro, L. (eds) Formal Methods Teaching. FMTea 2024.
Lecture Notes in Computer Science, vol 14939. Springer, Cham.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/FMTEA24.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1007/978-3-031-71379-8_3)
</small>

<ins>Luca Negrini, Pietro Ferrara, Vincenzo Arceri, Agostino Cortesi</ins> (2023).
**LiSA: A Generic Framework for Multilanguage Static Analysis.**
In: Arceri, V., Cortesi, A., Ferrara, P., Olliaro, M. (eds) Challenges of Software Verification.
Intelligent Systems Reference Library, vol 238. Springer, Singapore.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/CSV23.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1007/978-981-19-9601-6_2)
</small>

<ins>Pietro Ferrara, Luca Negrini, Vincenzo Arceri, Agostino Cortesi</ins> (2021).
**Static analysis for dummies: experiencing LiSA.**
In: Proceedings of the 10th ACM SIGPLAN International Workshop on the State Of the Art in Program Analysis (SOAP 2021).
Association for Computing Machinery, New York, NY, USA, 1–6.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/SOAP21.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3460946.3464316)
</small>

### Publications using LiSA

<ins>Luca Negrini</ins> (2026).
**Whole-value analysis by abstract interpretation.**
In: Frontiers in Computer Science, 7:1655377.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/FCOMP26.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.3389/fcomp.2025.1655377)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Luca Olivieri, Luca Negrini</ins> (2025).
**Don’t Panic: Error Handling Patterns in Go Smart Contracts and Blockchain Software.**
In: 7th Conference on Blockchain Research & Applications for Innovative Networks and Services
(BRAINS), Zurich, Switzerland, 2025, pp. 1-9.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/BRAINS25.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1109/BRAINS67003.2025.11302935)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Luca Olivieri</ins> (2025).
**Detection of Cross-Channel Invocation Risks in Hyperledger Fabric.**
In: 2025 IEEE 36th International Symposium on Software Reliability Engineering (ISSRE),
São Paulo, Brazil, 2025, pp. 107-118<br/>
<small>
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1109/ISSRE66568.2025.00023)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Luca Olivieri, David Beste, Luca Negrini, Lea Schönherr, Antonio Emanuele Cinà, Pietro Ferrara</ins> (2025).
**Code Generation of Smart Contracts with LLMs: A Case Study on Hyperledger Fabric.**
In: 2025 IEEE 36th International Symposium on Software Reliability Engineering (ISSRE),
São Paulo, Brazil, 2025, pp. 239-251<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/ISSRE25.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1109/ISSRE66568.2025.00034)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Vincenzo Arceri, Saverio Mattia Merenda, Luca Negrini, Luca Olivieri, Enea Zaffanella</ins> (2025).
**EVMLiSA: Sound Static Control-Flow Graph Construction for EVM Bytecode.**
In: Blockchain: Research and Applications, 100384.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/BCRA25.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1016/j.bcra.2025.100384)
&nbsp;
[<i class="fas fa-laptop-code"></i> evm-lisa](https://github.com/lisa-analyzer/evm-lisa)
</small>

<ins>Luca Olivieri, Luca Negrini, Vincenzo Arceri, Pietro Ferrara, Agostino Cortesi, Fausto Spoto</ins> (2025).
**Static Detection of Untrusted Cross-Contract Invocations in Go Smart Contracts.**
In: Proceedings of the 40th ACM/SIGAPP Symposium on Applied Computing
(SAC '25). Association for Computing Machinery, New York, NY, USA, 338–347. <br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/SAC25-2.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3672608.3707728)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Luca Olivieri, Luca Negrini, Vincenzo Arceri, Pietro Ferrara, Agostino Cortesi</ins> (2025).
**Detection of Read-Write Issues in Hyperledger Fabric Smart Contracts.**
In: Proceedings of the 40th ACM/SIGAPP Symposium on Applied Computing (SAC '25).
Association for Computing Machinery, New York, NY, USA, 329–337.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/SAC25-1.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3672608.3707721)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Giacomo Zanatta, Gianluca Caiazza, Pietro Ferrara, Luca Negrini</ins> (2024).
**Inference of access policies through static analysis.**
In: International Journal on Software Tools for Technology Transfer, 26, 797-821.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/CSV24.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1007/s10009-024-00777-8)
&nbsp;
[<i class="fas fa-laptop-code"></i> pylisa](https://github.com/lisa-analyzer/pylisa)
</small>

<ins>Luca Negrini, Sofia Presotto, Pietro Ferrara, Enea Zaffanella, Agostino Cortesi</ins> (2024).
**Stability: an Abstract Domain for the Trend of Variation of Numerical Variables.**
In: Proceedings of the 10th ACM SIGPLAN International Workshop on Numerical and Symbolic Abstract Domains (NSAD '24).
Association for Computing Machinery, New York, NY, USA, 10–17.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/NSAD24.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3689609.3689995)
&nbsp;
[<i class="fas fa-laptop-code"></i> lisa-imp](https://github.com/lisa-analyzer/lisa)
</small>

<ins>Giacomo Zanatta, Gianluca Caiazza, Pietro Ferrara, Luca Negrini, Ruffin White</ins> (2024).
**Automating ROS2 Security Policies Extraction through Static Analysis.**
In: 2024 IEEE/RSJ International Conference on Intelligent Robots and Systems (IROS),
Abu Dhabi, United Arab Emirates, 2024, pp. 3627-3634.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/IROS24.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1109/IROS58592.2024.10802507)
&nbsp;
[<i class="fas fa-laptop-code"></i> pylisa](https://github.com/lisa-analyzer/pylisa)
</small>

<ins>Giacomo Zanatta, Pietro Ferrara, Teodors Lisovenko, Luca Negrini, Gianluca Caiazza, Ruffin White</ins> (2024).
**Sound Static Analysis for Microservices: Utopia? A preliminary experience with LiSA.**
In: Proceedings of the 26th ACM International Workshop on Formal Techniques for Java-like Programs (FTfJP 2024).
Association for Computing Machinery, New York, NY, USA, 5–10.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/FTFJP24-1.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3678721.3686229)
&nbsp;
[<i class="fas fa-laptop-code"></i> pylisa](https://github.com/lisa-analyzer/pylisa)
</small>

<ins>Vincenzo Arceri, Saverio Mattia Merenda, Greta Dolcetti, Luca Negrini, Luca Olivieri, Enea Zaffanella</ins> (2024).
**Towards a Sound Construction of EVM Bytecode Control-flow Graphs.**
In: Proceedings of the 26th ACM International Workshop on Formal Techniques for Java-like Programs (FTfJP 2024).
Association for Computing Machinery, New York, NY, USA, 11–16.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/FTFJP24-2.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3678721.3686227)
&nbsp;
[<i class="fas fa-laptop-code"></i> evm-lisa](https://github.com/lisa-analyzer/evm-lisa)
</small>

<ins>Luca Olivieri, Luca Negrini, Vincenzo Arceri, Badaruddin Chachar, Pietro Ferrara, Agostino Cortesi</ins> (2024).
**Detection of Phantom Reads in Hyperledger Fabric.**
In: EEE Access, vol. 12, pp. 80687-80697, 2024.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/IEEEA24.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1109/ACCESS.2024.3410019)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Luca Negrini, Vincenzo Arceri, Agostino Cortesi, Pietro Ferrara</ins> (2024).
**Tarsis: An effective automata-based abstract domain for string analysis.**
In: Journal of Software: Evolution and Process, 2024. 36(8):e2647.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/JSEP24.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1002/smr.2647)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Luca Olivieri, Luca Negrini, Vincenzo Arceri, Thomas Jensen, Fausto Spoto</ins> (2024).
**Design and Implementation of Static Analyses for Tezos Smart Contracts.**
In: Distributed Ledger Technologies: Research and Practice. 4, 2, Article 13 (June 2025), 23 pages.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/DLTRP24.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3643567)
&nbsp;
[<i class="fas fa-laptop-code"></i> michelson-lisa](https://github.com/lisa-analyzer/michelson-lisa)
</small>

<ins>Luca Olivieri, Vincenzo Arceri, Luca Negrini, Fabio Tagliaferro, Pietro Ferrara, Agostino Cortesi, Fausto Spoto</ins> (2023).
**Information Flow Analysis for Detecting Non-Determinism in Blockchain.**
In: 37th European Conference on Object-Oriented Programming (ECOOP 2023).
Leibniz International Proceedings in Informatics (LIPIcs), Volume 263, pp. 23:1-23:25,
Schloss Dagstuhl – Leibniz-Zentrum für Informatik.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/ECOOP23.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.4230/LIPIcs.ECOOP.2023.23)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>

<ins>Static Analysis of Data Transformations in Jupyter Notebooks</ins> (2023).
**Luca Negrini, Guruprerana Shabadi, Caterina Urban.**
In: Proceedings of the 12th ACM SIGPLAN International Workshop on the State Of the Art in Program Analysis (SOAP 2023).
Association for Computing Machinery, New York, NY, USA, 8–13.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/SOAP23.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3589250.3596145)
&nbsp;
[<i class="fas fa-laptop-code"></i> pylisa](https://github.com/lisa-analyzer/pylisa)
</small>

<ins>MichelsonLiSA: A Static Analyzer for Tezos</ins> (2023).
**Luca Olivieri, Thomas Jensen, Luca Negrini, Fausto Spoto.**
In: 2023 IEEE International Conference on Pervasive Computing and Communications Workshops and other Affiliated Events (PerCom Workshops),
Atlanta, GA, USA, 2023, pp. 80-85.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/BRAIN23.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1109/PerComWorkshops56833.2023.10150247)
&nbsp;
[<i class="fas fa-laptop-code"></i> michelson-lisa](https://github.com/lisa-analyzer/michelson-lisa)
</small>

<ins>Luca Olivieri, Fabio Tagliaferro, Vincenzo Arceri, Marco Ruaro, Luca Negrini, Agostino Cortesi, Pietro Ferrara, Fausto Spoto, Enrico Tallin</ins> (2022).
**Ensuring Determinism in Blockchain Software with GoLiSA: An Industrial Experience Report.**
In: Proceedings of the 11th ACM SIGPLAN International Workshop on the State Of the Art in Program Analysis (SOAP 2022).
Association for Computing Machinery, New York, NY, USA, 23–29.<br/>
<small>
[<i class="far fa-file-pdf"></i> PDF](https://lucaneg.github.io/papers/SOAP22.pdf)
&nbsp;
[<i class="fas fa-link"></i> DOI](https://doi.org/10.1145/3520313.3534658)
&nbsp;
[<i class="fas fa-laptop-code"></i> go-lisa](https://github.com/lisa-analyzer/go-lisa)
</small>
