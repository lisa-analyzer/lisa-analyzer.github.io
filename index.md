---
notoc: true
banner: true
---

{% include card-left.html
image="reusable.png"
alt="Banner image for reusability"
title="Accessible and extensible"
content="Written entirely in Java with comprehensive and clear documentation,
LiSA is designed around modular components that encourage <b>reuse</b>, <b>extension</b>,
and <b>rapid adoption</b>. Its structure makes it easy for new users to get started,
while still supporting advanced customization for researchers and developers."
link="https://github.com/lisa-analyzer/lisa"
link_text="Browse the code on GitHub"
%}

{% capture card_link %}
{{ site.baseurl }}/material/
{% endcapture %}
{% include card-right.html
image="material.png"
alt="Banner image for additional material"
title="Proven in practice"
content="LiSA is supported by an extensive body of publications and has
been adopted in both <b>research</b> and <b>teaching contexts</b>. Its track record
demonstrates reliability, meaningful impact, and a strong presence in the
academic community, making it a trusted platform for experimentation and
education."
link=card_link
link_text="See all publications using LiSA"
%}

{% include card-left.html
image="science.png"
alt="Banner image for scientific principles"
title="Scientifically grounded"
content="Built on the principles of <b>Abstract Interpretation</b>, LiSA provides
<b>sound</b>, <b>rigorous</b> analysis with <b>formal guarantees</b>. Its theoretical foundation
ensures that results are reliable and reproducible, making it suitable for
high-assurance applications and scientific research."
link="https://sv-comp.sosy-lab.org/2026/results/results-verified/#java-verification"
link_text="Check out SV-COMP 2026 results"
%}

{% include card-right.html
image="versatile.png"
alt="Banner image for applicability"
title="Versatile by design"
content="LiSA has been applied across a wide range of domains, including
blockchain systems, robotics, microservices, and data science applications.
Supporting multiple programming languages and fully integrated into Ghidra, it
provides <b>practical</b>, <b>real-world applicability</b> alongside foundational work on
modular and compositional analysis."
link="https://github.com/NationalSecurityAgency/ghidra/blob/2b6a66cee0aeef3092eec9ed403516d91e3b463c/Ghidra/Extensions/Lisa/src/main/help/help/topics/LisaPlugin/LisaPlugin.html"
link_text="Discover Ghidra's integration of LiSA"
%}

<div style="width: 60%; margin: 3rem auto">
{% include important.html content="LiSA is a research project under active
development. Some features might be incomplete or missing,
and the API might change in future releases. We will do our best to
self-document this through semantic versioning, but things might break
nonetheless." %}
</div>

## Frontends and Projects

<div class="carousel-container" id="carousel-container">

<button class="arrow" id="prev">‹</button>

  <div class="carousel-viewport" id="carousel-viewport">
    <div class="carousel-track" id="carousel">
      {% include frontend_card.html 
	title="JLiSA" 
	content="A frontend for the analysis of Java programs, participating in SV-COMP since 2026."
        btn_link="https://github.com/lisa-analyzer/jlisa" 
	btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
      {% include frontend_card.html 
	title="GoLiSA" 
	content="A frontend for the analysis of Go blockchain programs and smart contracts, focusing on Hyperledger Fabric, Cosmos SDK, Tendermint Core, and Ethereum."
        btn_link="https://github.com/lisa-analyzer/go-lisa" 
	btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
      {% include frontend_card.html 
	title="EVMLiSA" 
	content="A frontend for the analysis of EVM bytecode for Ethereum blockchains."
        btn_link="https://github.com/lisa-analyzer/evm-lisa" 
	btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
      {% include frontend_card.html 
	title="MichelsonLiSA" 
	content="A frontend for the analysis of Michelson bytecode for Tezos blockchains."
        btn_link="https://github.com/lisa-analyzer/michelson-lisa" 
	btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
      {% include frontend_card.html 
	title="PyLiSA" 
	content="A frontend for the analysis of Python programs, focusing on Data Science scripts and ROS2 projects."
        btn_link="https://github.com/lisa-analyzer/pylisa" 
	btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
      {% include frontend_card.html 
	title="LiSA4Ros2" 
	content="A tool for extracting ROS2 policies from Python software."
        btn_link="https://github.com/lisa-analyzer/lisa4ros2" 
	btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
    </div>
  </div>

<button class="arrow" id="next">›</button>

</div>

<script>
const container = document.getElementById("carousel-container");
const track = document.getElementById("carousel");
const viewport = document.getElementById("carousel-viewport");
const nextBtn = document.getElementById("next");
const prevBtn = document.getElementById("prev");

// duplicate cards ONCE
const cards = Array.from(track.children);
cards.forEach(card => track.appendChild(card.cloneNode(true)));

// compute exact scroll distance (half the track)
const halfWidth = track.scrollWidth / 2;
track.style.setProperty("--scroll-distance", `-${halfWidth}px`);

// card width
const cardWidth = cards[0].offsetWidth + 20;

// pause/resume on hover
viewport.addEventListener("mouseenter", () => {
  track.style.animationPlayState = "paused";
});
viewport.addEventListener("mouseleave", () => {
  track.style.animationPlayState = "running";
});

// helper: get current X even during animation
function getCurrentTranslateX() {
  const style = window.getComputedStyle(track);
  const matrix = new DOMMatrixReadOnly(style.transform);
  return matrix.m41;
}

// move by one card
function nudge(dir) {
  // freeze animation at current spot
  const currentX = getCurrentTranslateX();
  track.style.animation = "none";
  track.style.transform = `translateX(${currentX + dir * cardWidth}px)`;

  // force reflow so browser applies transform
  track.offsetHeight;

  // restore animation
  // track.style.animation = "scroll 20s linear infinite";
}

nextBtn.onclick = () => nudge(-1);
prevBtn.onclick = () => nudge(1);
</script>

## Get Involved

LiSA is developed and maintained by the [Software and System Verification
(SSV)](https://ssv.dais.unive.it/) group @ Università Ca' Foscari in Venice,
Italy. External contributions are always welcome! Check out our [contributing
guidelines](https://github.com/lisa-analyzer/lisa/blob/master/CONTRIBUTING.md)
for information on how to contribute to LiSA.

We are open for collaborations! If you want to work with LiSA or have an idea
for a new frontend and you want to join forces, get in contact with one of the team members.

## People

LiSA is the result of the work of many people gravitating around the
[SSV research group]({{ site.ssv-homepage }}), focusing on differnt parts
of the library or on one of the frontends developed over the years.

### Maintainers and Main Contributors

<div class="div-person-table-row">
  <div class="div-person-table-col">
    <div class="teambox-card-container">
      <img class="teambox-img" src="https://lucaneg.github.io/photo_small.jpg"/>
    </div>
    <div class="div-person-table-info">
      Luca Negrini<br/>
      <small>
	Assistant Professor<br/>
	Ca' Foscari University of Venice<br/>
	<a href="mailto:luca.negrini@unive.it"><i class="fas fa-envelope"></i></a> • 
	<a href="https://lucaneg.github.io"><i class="fas fa-globe"></i></a>
      </small>
    </div>
  </div>
  <div class="div-person-table-col">
    <div class="teambox-card-container">
      <img class="teambox-img" src="https://vincenzoarceri.github.io/photo_small.jpg"/>
    </div>
    <div class="div-person-table-info">
      Vincenzo Arceri<br/>
      <small>
	Assistant Professor<br/>
	University of Parma<br/>
	<a href="mailto:vincenzo.arceri@unipr.it"><i class="fas fa-envelope"></i></a> • 
	<a href="https://vincenzoarceri.github.io"><i class="fas fa-globe"></i></a>
      </small>
    </div>
  </div>
  <div class="div-person-table-col">
    <div class="teambox-card-container">
      <img class="teambox-img" src="https://olivieriluca.github.io/small_photo.jpg"/>
    </div>
    <div class="div-person-table-info">
      Luca Olivieri<br/>
      <small>
	Assistant Professor<br/>
	Ca' Foscari University of Venice<br/>
	<a href="mailto:luca.olivieri@unive.it"><i class="fas fa-envelope"></i></a> • 
	<a href="https://olivieriluca.github.io"><i class="fas fa-globe"></i></a>
      </small>
    </div>
  </div>
</div>

### Project Members

<div class="div-person-table-row">
  <div class="div-person-table-col">
    <div class="teambox-card-container-smaller">
      <img class="teambox-img-smaller" src="https://pietroferrara.github.io/picture.jpg"/>
    </div>
    <div class="div-person-table-info">
      Pietro Ferrara<br/>
      <small>
	Associate Professor<br/>
	Ca' Foscari University of Venice<br/>
	<a href="mailto:pietro.ferrara@unive.it"><i class="fas fa-envelope"></i></a> • 
	<a href="https://pietroferrara.github.io/"><i class="fas fa-globe"></i></a>
      </small>
    </div>
  </div>
  <div class="div-person-table-col">
    <div class="teambox-card-container-smaller">
      <img class="teambox-img-smaller" src="https://www.unive.it/pag/fileadmin/user_upload/img/persone/5591776.jpg"/>
    </div>
    <div class="div-person-table-info">
      Agostino Cortesi<br/>
      <small>
	Full Professor<br/>
	Ca' Foscari University of Venice<br/>
	<a href="mailto:cortesi@unive.it"><i class="fas fa-envelope"></i></a> • 
	<a href="https://www.unive.it/data/persone/5591776"><i class="fas fa-globe"></i></a>
      </small>
    </div>
  </div>
  <div class="div-person-table-col">
    <div class="teambox-card-container-smaller">
      <img class="teambox-img-smaller" src="https://www.giacomozanatta.com/pic.jpg"/>
    </div>
    <div class="div-person-table-info">
      Giacomo Zanatta<br/>
      <small>
	PhD Student<br/>
	Ca' Foscari University of Venice<br/>
	<a href="mailto:giacomo.zanatta@unive.it"><i class="fas fa-envelope"></i></a> • 
	<a href="https://www.giacomozanatta.com/"><i class="fas fa-globe"></i></a>
      </small>
    </div>
  </div>
  <div class="div-person-table-col">
    <div class="teambox-card-container-smaller">
      <img class="teambox-img-smaller" src="https://giacomoboldini.github.io/cv/profile.jpg"/>
    </div>
    <div class="div-person-table-info">
      Giacomo Boldini<br/>
      <small>
	PhD Student<br/>
	Ca' Foscari University of Venice<br/>
	<a href="mailto:giacomo.boldini@unive.it"><i class="fas fa-envelope"></i></a> • 
	<a href="https://giacomoboldini.github.io/"><i class="fas fa-globe"></i></a>
      </small>
    </div>
  </div>
</div>
