---
notoc: true
---

# Search Results

<span id="search-searching">Searching...</span>
<span id="search-empty-query" class="search-preamble-hidden">Empty query, cannot search!</span>
<span id="search-no-results" class="search-preamble-hidden">No results found for term:</span>
<span id="search-has-results" class="search-preamble-hidden">
<span id="search-hit-count"></span>
result(s) found for term:
</span>
<span id="search-query" style="font-weight: bold"></span>

<ul id="search-results-list" class="fa-ul search-preamble-hidden"></ul>

<script src="{{ site.baseurl }}/custom-assets/lunr.min.js"></script>
<script src="{{ site.baseurl }}/custom-assets/search.js"></script>

<script>
	window.data = {
		{% for item in site.pages %}
			{% assign ext = item.name | slice: -3, 3 %}
			{% if ext == ".md" and item.url != "/" %}
			  {% if added %},{% endif %}
			  {% assign added = false %}

			  "{{ item.url | slugify }}": {
				  "id": "{{ item.url | slugify }}",
				  "title": "{{ item.title | xml_escape }}",
				  "url": " {{ item.url | xml_escape }}",
				  "content": {{ item.content | markdownify | strip_html | replace_regex: "[\s/\n]+"," " | strip | jsonify }}
			  }

			  {% assign added = true %}
			{% endif %}
		{% endfor %}
	};
	runSearch("{{ site.baseurl }}");
</script>
