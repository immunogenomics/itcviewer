/**
 * The main logic of this application.
 *
 * 1. Create a Bloodhound to retrieve batches of results from mygene.info.
 * 2. Connect the Bloodhound to the typeahead.js input field.
 * 3. Register an event when the user selected an item from typeahead.js.
 */
function main() {
  // 1. Create a Bloodhound to retrieve batches of results from mygene.info.
  var engine = new Bloodhound({
    name: 'genes',
    limit: 15,
    remote: {
      url: 'http://mygene.info/v2/query?q=%QUERY*' +
	'&fields=symbol,name,entrezgene,summary,genomic_pos_hg19,HGNC,map_location,pathway.wikipathways' +
	'&species=human&size=15' +
	'&email=slowikow@broadinstitute.org',
      filter: function(datum) {
	var results = datum['hits'].filter(function(el) {
	  return el['symbol'] && el['genomic_pos_hg19'] && el['HGNC'];
	});
	// Sort results by length. If enabled, BRCA1 is not first-displayed :(
	// results.sort(function(a, b) {
	//   return a.symbol.length - b.symbol.length;
	// });
	return results;
      }
    },
    datumTokenizer: function(datum) {
      return Bloodhound.tokenizers.whitespace(datum.val);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace
  });

  var promise = engine.initialize();
  promise
  .done(function() { console.log('success!'); })
  .fail(function() { console.log('err!'); });

  // 2. Connect the Bloodhound to the typeahead.js input field.
  $('#mainSearch').typeahead(null, {
    name: 'genes',
    displayKey: 'symbol',
    source: engine.ttAdapter(),
    templates: {
      suggestion: formatSuggestion
    }
  });

  // 3. Register an event when the user selected an item from typeahead.js.
  $('#mainSearch').on('typeahead:selected', function(obj, datum, name) {      
    //console.log(datum);
    $("#savedResults").prepend(formatSavedResult(datum));
  });
}

/**
 * Format a dropdown suggestion displayed by typeahead.js.
 *
 * @param {Object} datum - An object returned by mygene.info.
 *
 * @returns {String} - The HTML for a suggestion.
 */
function formatSuggestion(datum) {
  var space = '&nbsp;&nbsp;&nbsp;&nbsp;';
  var form = '<div><span id="gene-symbol">{symbol}</span>';

  if (datum['name']) {
    form += space + '<span id="gene-name">{name}</span>';
  }

  // var pos = datum['genomic_pos_hg19'];
  // var region = '';
  // if (pos) {
  //   if (pos.length > 1) {
  //     pos = pos[0];
  //   }
  //   region = ucscRegionLink(pos);
  //   form += '<br><small>' + space + region + '</small>';
  // }

  // if (datum['HGNC']) {
  //   form += '<br><small>' + space + hgncGeneLink(datum) + '</small>';
  // }

  form += '</div>';
  return format(form, datum);
}

/**
 * Format a document element with information about a gene.
 *
 * @param {Object} datum - An object returned by mygene.info.
 *
 * @returns {String} - The HTML for a gene.
 */
function formatSavedResult(datum) {
  var space = '&nbsp;&nbsp;&nbsp;&nbsp;';
  var form = '<div id="savedResult">';

  form += '<p>';

  form += '<span id="gene-symbol">{symbol}</span>';

  if (datum['map_location']) {
    form += space +
      '<span id="gene-map-location">' + datum['map_location'] + '</span>';
  }

  if (datum['HGNC']) {
    form += space + hgncGeneLink(datum);
  }

  form += '</p>';

  form += '<p>';

  if (datum['name']) {
    form += '<span id="gene-name">{name}</span>';
  }

  form += '</p>';

  form += '<p>';

  var pos = datum['genomic_pos_hg19'];
  if (pos) {

    if (pos.length > 1) {
      pos = pos[0];
    }
    form += '<strong>Browsers:</strong>';
    form += space + ucscRegionLink(pos);
    form += space + jbrowseRegionLink(pos);

    // Get variants from myvariant.info.
    myvariantList(pos);
  }

  form += '</p>';

  if (datum['pathway.wikipathways']
      && datum['pathway.wikipathways'].length > 0) {
    form += '<p>' + wikipathwayLinks(datum) + '</p>';
  }

  if (datum['summary']) {
    // form += '<p><strong>Summary:</strong>' + summaryList(datum) + '</p>';
    form += makeCollapseSection(
      'gene-summary-' + datum['symbol'], 'Summary', summaryList(datum),
      'false');
  }

  form += '</div>';
  return format(form, datum);
}

function makeCollapseSection(id, buttonText, sectionText, opened) {
  return '<section>' +
    '<paper-button raised="true" onclick="' + 
    "document.querySelector('#" + id + "').toggle()" + '">' + 
    buttonText + '</paper-button>' +
    '<core-collapse opened="' + opened +
    '" id="' + id + '">' +
    '<div class="content">' + sectionText + '</div>' +
    '</core-collapse>' +
    '</section>';
}


/****************************************************************************
 * Pure functions.
 */

/**
 * Sort objects by a single property shared by all of the objects.
 *
 * @param {String} property - The property present in each object.
 *
 * @returns {Function} - A function to be use with Array.sort()
 */
function dynamicSort(property) {
    var sortOrder = 1;
    if (property[0] === "-") {
        sortOrder = -1;
        property = property.substr(1);
    }
    return function (a, b) {
        var result = (a[property] < b[property]) 
	  ? -1
	  : (a[property] > b[property])
	    ? 1
	    : 0;
        return result * sortOrder;
    }
}

/**
 * Insert commas into a number so triplets are separated. Returns a string.
 *
 * @example
 * // returns "1,000"
 * numberWithCommas(1000);
 *
 * @param {Number} x - A number.
 *
 * @returns {String} - The number coverted to a string with commas.
 */
function numberWithCommas(x) {
  return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/**
 * Format a template string.
 *
 * @example
 * // returns "Hi Kamil"
 * format("Hi {name}", {name: "Kamil"});
 *
 * @param {String} form - The template string.
 * @param {Object} datum - An object. Its properties are used in the template.
 *
 * @returns {String} - The formatted template with values filled in.
 */
function format(form, datum) {
  return form.replace(/{([^}]+)}/g, function(match, key) { 
    return typeof datum[key] != 'undefined' ? datum[key] : '';
  });
};

/**
 * Convert an object with genomic coordinates into a region string.
 *
 * @example
 * // returns "chr1:1,000-10,000,000"
 * posToRegion({chr: "chr1", start: 1000, end: 10000000});
 *
 * @param {Object} pos - An object with properties: chr, start, end
 * 
 * @returns {String} - A string representation of the region.
 */
function posToRegion(pos) {
  if (pos['chr'] && pos['start'] && pos['end']) {
    return pos['chr'] + ':' +
      numberWithCommas(pos['start']) + '-' +
      numberWithCommas(pos['end']);
  }
  return '';
}

/**
 * Get a nested property inside an object if it exists.
 *
 * @example
 * // returns "deep secret"
 * getNestedKey({html: body: { heart: "deep secret" } }, "html.body.heart");
 *
 * @example
 * // returns null
 * getNestedKey({html: body: { heart: "deep secret" } }, "html.body.brain");
 *
 * @param {Object} item - The object with nested properties.
 * @param {String} keys - A period-delimited string of properties.
 *
 * @returns {Object} - The value stored inside the given object.
 *
 */
function getNestedKey(item, keys) {
  var result = item;
  keys = keys.split(".");
  for (var i = 0; i < keys.length; i++) {
	if (result[keys[i]]) {
	  result = result[keys[i]];
	} else {
	  return null;
	}
  }
  return result;
}

/**
 * Encode HTML entitites in a string.
 *
 * @example
 * // returns "&#x3C;strong&#x3E;"
 * encodeStr("<strong>");
 *
 * @param {String} raw - A string with HTML entities.
 *
 * @returns {String} - A string with HTML entities encoded.
 */
function encodeStr(raw) {
  return raw.replace(/[\u00A0-\u9999<>\&]/gim, function(i) {
	return '&#' + i.charCodeAt(0) + ';';
  });
}

/****************************************************************************
 * Links to other websites.
 */

/**
 * Create a link to the NCBI Entrez Gene database.
 *
 * @example
 * // returns '<strong>Entrez:</strong> <a target="_blank" href="http://www.ncbi.nlm.nih.gov/gene/123">123</a>'
 * entrezGeneLink({entrezgene: 123});
 *
 * @param {Object} datum - An object with a property: entrezgene
 *
 * @returns {String} - An HTML link to a gene at the NCBI Entrez Gene database.
 */
function entrezGeneLink(datum) {
  var form = '<strong>Entrez:</strong> ' +
    '<a target="_blank" href="http://www.ncbi.nlm.nih.gov/gene/{entrezgene}">' +
    '{entrezgene}</a>';
  if (datum['entrezgene']) {
    return format(form, datum);
  }
  return '';
}

/**
 * Create a link to the HGNC database.
 *
 * @example
 * // returns '<strong>HGNC:</strong> <a target="_blank" href="http://www.genenames.org/cgi-bin/gene_symbol_report?hgnc_id=HGNC:123">123</a>'
 * hgncGeneLink({HGNC: 123});
 *
 * @param {Object} datum - An object with a property: HGNC
 *
 * @returns {String} - An HTML link to a gene at the HGNC database.
 */
function hgncGeneLink(datum) {
  var form = '<a target="_blank"' +
    ' href="http://www.genenames.org/cgi-bin/gene_symbol_report' +
    '?hgnc_id=HGNC:{HGNC}">HGNC</a>';
  if (datum['HGNC']) {
    return format(form, datum);
  }
  return '';
}

/**
 * Create an HTML list of pathways described in WikiPathways.
 *
 * @param {Object} datum - An object with a property: pathway.wikipathways
 *
 * @returns {String} - An HTML list of pathways.
 */
function wikipathwayLinks(datum) {
  var links = '<strong>Wikipathways:</strong>';
  var pathways = datum['pathway.wikipathways'];
  var url = 'http://www.wikipathways.org/index.php/Pathway:{id}';
  var form = '<li><a target="_blank" href="' + url + '">{name}</a></li><br>';
  if (pathways) {
    links += '<ul>';
    for (var i = 0; i < pathways.length; i++) {
      links += format(form, pathways[i]);
    }
    links += '</ul>';
  }
  return links;
}

/**
 * Create an HTML list of the sentences in a gene's summary.
 *
 * @example
 * //returns "<ul><li>One.</li><li>Two.</li></ul>"
 * summaryList({summary: "One. Two."});
 *
 * @param {Object} datum - An object with property: datum
 *
 * @returns {String} - An HTML list.
 */
function summaryList(datum) {
  var summary = datum['summary'];
  var result = '';
  if (summary) {
    var parts = summary.split(".");
    result += '<ul>';
    for (var i = 0; i < parts.length - 1; i++) {
      result +=  '<li>' + parts[i] + '.</li><br>';
    }
    result += '</ul>';
  }
  return result;
}

/**
 * Create a link to Kamil Slowikowski's JBrowse instance with GTEx data.
 *
 * @param {Object} pos - An object with properties: chr, start, end
 *
 * @returns {String} - The url to the JBrowse genome browser.
 */
function jbrowseRegionLink(pos) {
  var url = 'http://www.broadinstitute.org/~slowikow/JBrowse-1.10.1/' +
    '?loc={chr}%3A{start}..{end}' +
    '&tracks=Adipose%20-%20Subcutaneous%2CWhole%20Blood' +
    '%2CArtery%20-%20Aorta%2CMuscle%20-%20Skeletal' +
    '%2CBrain%20-%20Hippocampus%2CPituitary' +
    '%2CSkin%20-%20Sun%20Exposed%20(Lower%20leg)%2CStomach' +
    '%2CPancreas%2CColon%20-%20Transverse' +
    '%2CEnsembl%20v72%20Transcripts';
  var form = '<a target="_blank" href="' + url + '">GTEx</a>';
  if (pos['chr'] && pos['start'] && pos['end']) {
    return format(form, pos);
  }
  return '';
}

/**
 * Create a link to the UCSC genome browser.
 *
 * @param {Object} pos - An object with properties: chr, start, end
 *
 * @returns {String} - The url to the UCSC genome browser.
 */
function ucscRegionLink(pos) {
  var form = '<a target="_blank"' +
    ' href="https://genome.ucsc.edu/cgi-bin/hgTracks' +
    '?db=hg19&position=chr{chr}%3A{start}-{end}">' +
    'UCSC</a>';
  if (pos['chr'] && pos['start'] && pos['end']) {
    return format(form, pos);
  }
  return '';
}

/**
 * TODO: Create a link to the WashU Epigenome Browser.
 *
 * @param {Object} pos - An object with properties: chr, start, end
 *
 * @returns {String} - The url to the browser.
 */
// function epigenomeRegionLink(pos) {
//   var form = '<strong>GTEx:</strong> ' +
//     'http://epigenomegateway.wustl.edu/browser/' +
//     '?genome=hg19&coordinate=chr7:26663835-28123541';
// }

/****************************************************************************
 * AJAX calls.
 */

/**
 * Asynchronously call the myvariant.info API to retrieve variants within
 * a genomic region.
 *
 * @example
 * // inserts HTML into the element with id="myvariants"
 * get_myvariantsList(pos, $("#myvariants"));
 *
 * @param {Object} pos - An object with properties: chr, start, end
 */
function myvariantList(pos) {
  var myvariant_url = "http://myvariant.info/api/query?q=chr{chr}:{start}-{end}";
  var snpedia_url = "http://snpedia.com/index.php/";

  if (pos['chr'] && pos['start'] && pos['end']) {

    // Send a query to the myvariant.info service with a callback function.
    $.getJSON(format(myvariant_url, pos), function(data) {
      console.log(data);
      // Retrieve the returned variants.
      var items = [];
      var hits = data['hits']['hits'];

      // Check if we got anything.
      if (hits.length > 0) {
	// Append an item if it has information from MutDB.
	$.each(hits, function(i) {
	      var mutdb = getNestedKey(hits[i], '_source.mutdb');
	      if (mutdb.dbsnp_id) {
		var rsid = mutdb.dbsnp_id.split(",")[0];
		items.push("<li><a target='_blank' href='" +
		  snpedia_url + rsid + "'>" + rsid + "</a></li><br>");
	      }
	});
	items.sort();
      }

      if (items.length > 0) {

	// Append HTML to the specified element.
	var element = $("#savedResult").first();

	var variantButton = '<br>' + makeCollapseSection(
	  format('variants-{chr}-{start}-{end}', pos),
	  'Variants', '<ul>' + items.join('') + '</ul>', 'false');

	$(variantButton).appendTo(element);
      }

      // $("<p><strong>myvariant.info:</strong></p>").appendTo(element);
      // $("<ul/>", {
	// "id": "myvariant-list",
	// "html": items
      // }).appendTo(element);
    });

  }
}

// Start the application.
main();
