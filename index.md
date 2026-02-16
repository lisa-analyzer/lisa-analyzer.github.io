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
link_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;Browse the code on GitHub"
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
link_text="<i class=\"fas fa-book-reader\"></i>&nbsp;&nbsp;Check out all publications using LiSA"
%}

{% include card-left.html
image="science.png"
alt="Banner image for scientific principles"
title="Scientifically grounded"
content="Built on the principles of <b>Abstract Interpretation</b>, LiSA provides
<b>sound</b>, <b>rigorous</b> analysis with <b>formal guarantees</b>. Its theoretical foundation
ensures that results are reliable and reproducible, making it suitable for
high-assurance applications and scientific research."
link="https://www.di.ens.fr/~cousot/AI/IntroAbsInt.html"
link_text="<i class=\"fas fa-graduation-cap\"></i>&nbsp;&nbsp;Read more on Abstract Interpretation"
%}

{% capture card_link %}
{{ site.baseurl }}/configuration/
{% endcapture %}
{% include card-right.html
image="versatile.png"
alt="Banner image for applicability"
title="Versatile by design"
content="LiSA has been applied across a wide range of domains, including
blockchain systems, robotics, microservices, and data science applications.
Supporting multiple programming languages and fully integrated into Ghidra, it
provides <b>practical</b>, <b>real-world applicability</b> alongside foundational work on
modular and compositional analysis."
link=card_link
link_text="<i class=\"fas fa-wrench\"></i>&nbsp;&nbsp;Discover how LiSA can be configured"
%}

<div style="width: 60%; margin: 3rem auto">
{% include important.html content="LiSA is a research project under active
development. Some features might be incomplete or missing,
and the API might change in future releases. We will do our best to
self-document this through semantic versioning, but things might break
nonetheless." %}
</div>

## Frontends and Projects

LiSA is a powerful engine backing several static analyzers for different
programming languages and domains, all developed as part of the project.

<div class="slideshow-wrapper" id="frontends-slideshow-wrapper">
  <div class="slideshow-container" id="frontends-slideshow-container">
    <button class="arrow" onclick="moveFrontendSlide(-1)" id="frontends-slideshow-prev">‹</button>
    <div class="slideshow-viewport" id="frontends-slideshow-viewport">
      <div class="slideshow-track" id="frontends-slideshow-track">
	<div class="slide frontend-slide">
	  {% include slide_card.html 
	    title="JLiSA" 
	    content="A frontend for the analysis of Java programs, participating in SV-COMP since 2026."
	    btn_link="https://github.com/lisa-analyzer/jlisa" 
	    btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
	  {% include slide_card.html 
	    title="GoLiSA" 
	    content="A frontend for the analysis of Go blockchain programs and smart contracts, focusing on Hyperledger Fabric, Cosmos SDK, Tendermint Core, and Ethereum."
	    btn_link="https://github.com/lisa-analyzer/go-lisa" 
	    btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
	  {% include slide_card.html 
	    title="EVMLiSA" 
	    content="A frontend for the analysis of EVM bytecode for Ethereum blockchains."
	    btn_link="https://github.com/lisa-analyzer/evm-lisa" 
	    btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
	</div>
	<div class="slide frontend-slide">
	  {% include slide_card.html 
	    title="MichelsonLiSA" 
	    content="A frontend for the analysis of Michelson bytecode for Tezos blockchains."
	    btn_link="https://github.com/lisa-analyzer/michelson-lisa" 
	    btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
	  {% include slide_card.html 
	    title="PyLiSA" 
	    content="A frontend for the analysis of Python programs, focusing on Data Science scripts and ROS2 projects."
	    btn_link="https://github.com/lisa-analyzer/pylisa" 
	    btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
	  {% include slide_card.html 
	    title="LiSA4Ros2" 
	    content="A tool for extracting ROS2 policies from Python software."
	    btn_link="https://github.com/lisa-analyzer/lisa4ros2" 
	    btn_text="<i class=\"fab fa-github\"></i>&nbsp;&nbsp;GitHub" %}
	</div>
      </div>
    </div>
    <button class="arrow" onclick="moveFrontendSlide(1)" id="frontends-slideshow-next">›</button>
  </div>
  <div class="dots-container" id="frontends-dots-container">
  </div>
</div>

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
  {% include member_card.html
    img_div_class="teambox-card-container"
    img_class="teambox-img"
    image="https://lucaneg.github.io/photo_small.jpg"
    name="Luca Negrini"
    position="Assistant Professor"
    affiliation="Ca' Foscari University of Venice"
    email="luca.negrini@unive.it"
    website="https://lucaneg.github.io" %}
  {% include member_card.html
    img_div_class="teambox-card-container"
    img_class="teambox-img"
    image="https://vincenzoarceri.github.io/photo_small.jpg"
    name="Vincenzo Arceri"
    position="Assistant Professor"
    affiliation="University of Parma"
    email="vincenzo.arceri@unipr.it"
    website="https://vincenzoarceri.github.io" %}
  {% include member_card.html
    img_div_class="teambox-card-container"
    img_class="teambox-img"
    image="https://olivieriluca.github.io/small_photo.jpg"
    name="Luca Olivieri"
    position="Assistant Professor"
    affiliation="Ca' Foscari University of Venice"
    email="luca.olivieri@unive.it"
    website="https://olivieriluca.github.io" %}
</div>

### Project Members

<div class="div-person-table-row">
  {% include member_card.html
    img_div_class="teambox-card-container-smaller"
    img_class="teambox-img-smaller"
    image="https://pietroferrara.github.io/picture.jpg"
    name="Pietro Ferrara"
    position="Associate Professor"
    affiliation="Ca' Foscari University of Venice"
    email="pietro.ferrara@unive.it"
    website="https://pietroferrara.github.io" %}
  {% include member_card.html
    img_div_class="teambox-card-container-smaller"
    img_class="teambox-img-smaller"
    image="https://www.unive.it/pag/fileadmin/user_upload/img/persone/5591776.jpg"
    name="Agostino Cortesi"
    position="Full Professor"
    affiliation="Ca' Foscari University of Venice"
    email="cortesi@unive.it"
    website="https://www.unive.it/data/persone/5591776" %}
  {% include member_card.html
    img_div_class="teambox-card-container-smaller"
    img_class="teambox-img-smaller"
    image="https://www.giacomozanatta.com/pic.jpg"
    name="Giacomo Zanatta"
    position="PhD Student"
    affiliation="Ca' Foscari University of Venice"
    email="giacomo.zanatta@unive.it"
    website="https://www.giacomozanatta.com/" %}
  {% include member_card.html
    img_div_class="teambox-card-container-smaller"
    img_class="teambox-img-smaller"
    image="https://giacomoboldini.github.io/cv/profile.jpg"
    name="Giacomo Boldini"
    position="PhD Student"
    affiliation="Ca' Foscari University of Venice"
    email="giacomo.boldini@unive.it"
    website="https://giacomoboldini.github.io/" %}
</div>

## News and Highlights

<div class="slideshow-wrapper" id="stories-slideshow-wrapper">
  <div class="slideshow-container" id="stories-slideshow-container">
    <button class="arrow" onclick="moveStorySlide(-1)" id="stories-slideshow-prev">‹</button>
    <div class="slideshow-viewport" id="stories-slideshow-viewport">
      <div class="slideshow-track" id="stories-slideshow-track">
	<div class="slide story-slide">
	  {% include slide_card.html 
	    title="JLiSA placed 3rd in SV-COMP 2026 in its first participation"
	    content="JLiSA, the Java frontend of LiSA, participated for the
	    first time in SV-COMP 2026, the leading competition for software
	    verification tools, and placed 3rd in the Java category,
	    demonstrating its effectiveness and competitiveness in the field.
	    JLiSA is the only Java tool based on Abstract Interpretation, and
	    achieved fully sound results with no false positives in the entire
	    competition."
	    btn_link="https://sv-comp.sosy-lab.org/2026/results/results-verified/#java-verification" 
	    btn_text="Check out SV-COMP 2026 results for the Java category" %}
	</div>
	<div class="slide story-slide">
	  {% include slide_card.html 
	  title="LiSA integrated into Ghidra" 
	  content="LiSA has been fully integrated into Ghidra since version
	  12.0, providing a powerful static analysis framework for PCode
	  (Ghidra's intermediate representation) able to perform a wide range
	  of analyses on binary code."
	  btn_link="https://github.com/NationalSecurityAgency/ghidra/blob/2b6a66cee0aeef3092eec9ed403516d91e3b463c/Ghidra/Extensions/Lisa/src/main/help/help/topics/LisaPlugin/LisaPlugin.html" 
	  btn_text="See Ghidra's documentation of the integration" %}
	</div>
      </div>
    </div>
    <button class="arrow" onclick="moveStorySlide(1)" id="stories-slideshow-next">›</button>
  </div>
  <div class="dots-container" id="stories-dots-container">
  </div>
</div>

<script>
const frontend_slides = document.querySelectorAll('.frontend-slide');
const story_slides = document.querySelectorAll('.story-slide');
const frontend_dotsContainer = document.getElementById('frontends-dots-container');
const story_dotsContainer = document.getElementById('stories-dots-container');
let frontend_currentIndex = 0;
let story_currentIndex = 0;

function createDots(slides, dotsContainer, callback) {
  slides.forEach((_, i) => {
    const dot = document.createElement('span');
    dot.classList.add('dot');
    if (i === 0) dot.classList.add('active');
    dot.addEventListener('click', () => callback(i));
    dotsContainer.appendChild(dot);
  });
}

function updateSlideshow(label, currentIndex) {
  const container = document.getElementById(label + '-slideshow-track');
  const dots = document.getElementById(label + '-dots-container').children;
  container.style.transform = `translateX(-${currentIndex * 100}%)`;
  for (let i = 0; i < dots.length; i++) {
    dots[i].classList.toggle('active', i === currentIndex);
  }
}

function moveFrontendSlide(step) {
  frontend_currentIndex = (frontend_currentIndex + step + frontend_slides.length) % frontend_slides.length;
  updateSlideshow('frontends', frontend_currentIndex);
}

function moveStorySlide(step) {
  story_currentIndex = (story_currentIndex + step + story_slides.length) % story_slides.length;
  updateSlideshow('stories', story_currentIndex);
}

function currentFrontendSlide(index) {
  frontend_currentIndex = index;
  updateSlideshow('frontends', frontend_currentIndex);
}

function currentStorySlide(index) {
  story_currentIndex = index;
  updateSlideshow('stories', story_currentIndex);
}

createDots(frontend_slides, frontend_dotsContainer, currentFrontendSlide); 
createDots(story_slides, story_dotsContainer, currentStorySlide); 
</script>
