function getQueryVariable(variable) {
	var query = window.location.search.substring(1),
		vars = query.split("&");

	for (var i = 0; i < vars.length; i++) {
		var pair = vars[i].split("=");

		if (pair[0] === variable) {
			return decodeURIComponent(pair[1].replace(/\+/g, '%20')).trim();
		}
	}
}

function getPreview(query, content, previewLength) {
	previewLength = previewLength || (content.length * 2);

	const parts = query.split(" ");
	var match = content.toLowerCase().indexOf(query.toLowerCase());
	var matchLength = query.length;
	var preview;

	// Find a relevant location in content
	for (var i = 0; i < parts.length; i++) {
		if (match >= 0) {
			break;
		}

		match = content.toLowerCase().indexOf(parts[i].toLowerCase());
		matchLength = parts[i].length;
	}

	// Create preview
	if (match >= 0) {
		const start = match - (previewLength / 2);
		const end = start > 0 ? match + matchLength + (previewLength / 2) : previewLength;

		preview = content.substring(start, end).trim();

		if (start > 0) {
			preview = "..." + preview;
		}

		if (end < content.length) {
			preview = preview + "...";
		}

		// Highlight query parts
		preview = preview.replace(new RegExp("(" + parts.join("|") + ")", "gi"), "<strong>$1</strong>");
	} else {
		// Use start of content if no match found
		preview = content.substring(0, previewLength).trim() + (content.length > previewLength ? "..." : "");
	}

	return preview;
}

function displaySearchResults(results, root, query) {
	const searchResults = document.getElementById("search-results-list");
	searchResults.classList.remove("search-preamble-hidden");

	var resultsHTML = "";
	results.forEach(function(result) {
		const item = window.data[result.ref];
		const contentPreview = getPreview(query, item.content, 300);
		const titlePreview = getPreview(query, item.title);
		resultsHTML += "<li>"
			+ "<span class=\"fa-li\"><i class=\"fab fa-sistrix\"></i></span>"
			+ "<a href=\""
			+ root
			+ item.url.trim()
			+ "\">"
			+ titlePreview
			+ "</a>"
			+ "<p class=\"search-hit-content\">"
			+ contentPreview
			+ "</p>"
			+ "</li>";
	});

	searchResults.innerHTML = resultsHTML;
}

function runSearch(root) {
	const query = decodeURIComponent((getQueryVariable("q") || "").replace(/\+/g, "%20"));
	const searching = document.getElementById("search-searching");
	const emptyQuery = document.getElementById("search-empty-query");
	const noResults = document.getElementById("search-no-results");
	const hasResults = document.getElementById("search-has-results");
	const hitCount = document.getElementById("search-hit-count");
	const searchQuery = document.getElementById("search-query");
	const searchInput = document.getElementById("search-input");

	if (query === "") {
		searching.classList.add("search-preamble-hidden");
		emptyQuery.classList.remove("search-preamble-hidden");
		return;
	}

	window.index = lunr(function() {
		this.field("id");
		this.field("title", { boost: 10 });
		this.field("url");
		this.field("content");
	});

	searchInput.value = query;
	searchQuery.innerText = query;

	for (var key in window.data) {
		window.index.add(window.data[key]);
	}

	const hits = window.index.search(query);

	searching.classList.add("search-preamble-hidden");
	if (hits.length === 0) {
		noResults.classList.remove("search-preamble-hidden");
		return;
	} else {
		hasResults.classList.remove("search-preamble-hidden");
		hitCount.innerText = hits.length;
	}

	displaySearchResults(hits, root, query);
}
