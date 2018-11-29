var x = '';

function search_pubmed(query) {
  var url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?";
  $.get(url, {
    usehistory: "y",
    db: "pubmed",
    term: query
  })
  .done(function(data) {
    console.log("esearch done");
    var xml = $(data);
    var web = xml.find("WebEnv").html();
    var key = xml.find("QueryKey").html();
    var pubmed_ids = xml.find("IdList").children().map(function(i, item) {
      return item.innerHTML;
    });
    add_abstracts(query, pubmed_ids);
  });
}

function add_abstracts(query, pubmed_ids) {
  var url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?";
  $.get(url, {
    db: "pubmed",
    rettype: "abstract",
    id: Array.prototype.join.call(pubmed_ids)
  })
  .done(function(data) {
    console.log("efetch done");
    // Example: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=17284678,9997&rettype=abstract
    // x = data;
    var titles = $(data).find("ArticleTitle").map(function(i, item) {
      return {
        pubmed: pubmed_ids[i],
        title: item.innerHTML
      };
    // }).toArray().sort(dynamicSort('title')).map(function(item) {
    }).toArray().map(function(item) {
      return '<li><a href="https://www.ncbi.nlm.nih.gov/pubmed/' +
        item.pubmed + '">' + item.title + '</a></li>';
    }).join('');
    $('#pubmed-abstracts').innerHTML = '';
    $('<ul>' + titles + '</ul>').prependTo("#pubmed-abstracts");
  });
}

function mygene_query(gene, callback) {
  var request = new XMLHttpRequest();
  request.open(
    'GET', 'https://mygene.info/v3/query?q=' + gene + '&species=human', true
  );
  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      // Success!
      var data = JSON.parse(request.responseText);
      callback(data);
    } else {
      // We reached our target server, but it returned an error
      console.log('error ' + request.responseText);
    }
  };
  request.onerror = function(data) {
    console.log('error ' + data);
  };
  request.send();
}

function mygene_gene(id, callback) {
  var request = new XMLHttpRequest();
  request.open(
    'GET',
    'https://mygene.info/v3/gene/' + id + '?email=kslowikowski@gmail.com'
  );
  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      // Success!
      var data = JSON.parse(request.responseText);
      callback(data);
    } else {
      // We reached our target server, but it returned an error
      console.log('error ' + request.responseText);
    }
  };
  request.onerror = function(data) {
    console.log('error ' + data);
  };
  request.send();
}

function fill_geneinfo(data) {
  x = data;
  console.log(data);
  var geneinfo = document.getElementById('geneinfo');
//  // var el = document.createElement("div");
  var form = '<h3><i>{symbol}</i></h3>' +
  '<p>{name}</p>' +
  '<p><b>Aliases:</b> {aliases}</p>' +
  '<p><b>Summary:</b> {summary}</p>' +
  '<p><b>iHOP:</b> <a target="_blank" href="http://www.ihop-net.org/UniPub/iHOP/index.html?field=all&search={symbol}&organism_id=1">link</a></p>' +
  '<p><b>GeneRIF:</b><div class="generif"><ul>{generif_list}</ul></div></p>' +
  '<p><b>Pubmed:</b> "t cell" AND {symbol}' +
  '<div id="pubmed-abstracts"></div></p>';
  data.aliases = Array.isArray(data.alias) ? data.alias.join(", ") : data.alias;
  data.generif_list = data.generif.sort(dynamicSort('text')).map(function(d) {
    return '<a href="https://www.ncbi.nlm.nih.gov/pubmed/' + d.pubmed + '">' +
      d.text + '</a>';
  }).map(function(d) {
    return '<li>' + d + '</li>';
  }).join('\n');
  geneinfo.innerHTML = format(form, data);
  search_pubmed('"t cell" AND ' + data.symbol);
}

shinyjs.queryGene = function(params) {
  var gene = params[0];
  console.log(gene);
  mygene_query(gene, function(data) {
    var id = data.hits[0]._id;
    mygene_gene(id, fill_geneinfo);
  });
};

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
    };
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
}

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
