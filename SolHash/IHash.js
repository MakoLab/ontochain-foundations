'use strict'

const bigInt	= require('big-integer');
const crypto	= require('crypto');
const XRegExp	= require('xregexp');
const moment	= require('moment');

// regular expression to "clean" literals:
//	- [\p{C} or \p{Other}: invisible control characters and unused code points.](https://www.regular-expressions.info/unicode.html#category)
const regex_invisible = XRegExp('\\pC','g');

const _HASH_SIZE		= 256;
const _BLANK_NODE_SUBJECT_NAME	= "Magic_S";
const _BLANK_NODE_OBJECT_NAME	= "Magic_O";
const _MOD_OPERAND		= bigInt(2 ** _HASH_SIZE);

// Characters in literals that require escaping
var escape    = /["\\\t\n\r\b\f\u0000-\u0019\ud800-\udbff]/,
    escapeAll = /["\\\t\n\r\b\f\u0000-\u0019]|[\ud800-\udbff][\udc00-\udfff]/g,
    escapedCharacters = {
      '\\': '\\\\', '"': '\\"', '\t': '\\t',
      '\n': '\\n', '\r': '\\r', '\b': '\\b', '\f': '\\f',
    };
const _prefixRegex	= /$0^/;
const _prefixIRIs	= Object.create(null);

// Replaces a character by its escaped version
function characterReplacer(character) {
  console.log("escaped");
  // Replace a single character by its escaped version
  var result = escapedCharacters[character];

  if (result === undefined) {
    // Replace a single character with its 4-bit unicode escape sequence
    if (character.length === 1) {
      console.log(1);
      result = character.charCodeAt(0).toString(16);
      result = '\\u0000'.substr(0, 6 - result.length) + result;
    } // Replace a surrogate pair with its 8-bit unicode escape sequence
    else {
      console.log(2);
      console.log(result);
      result = ((character.charCodeAt(0) - 0xD800) * 0x400 + character.charCodeAt(1) + 0x2400).toString(16);
      console.log(result);
      result = '\\U00000000'.substr(0, 10 - result.length) + result;
      console.log(result);
    }
  }

  return result;
}

// ### `_encodeIriOrBlank` represents an IRI or blank node
function _encodeIriOrBlank(entity) {
  // A blank node or list is represented as-is
  if (entity.termType !== 'NamedNode') return 'id' in entity ? entity.id : '_:' + entity.value; // Escape special characters

  var iri = entity.value;
  if (escape.test(iri)) iri = iri.replace(escapeAll, characterReplacer); // Try to represent the IRI as prefixed name

  var prefixMatch =      _prefixRegex.exec(iri);
  return !prefixMatch ? '<' + iri + '>' : !prefixMatch[1] ? iri :      _prefixIRIs[prefixMatch[1]] + prefixMatch[2];
} // ### `_encodeLiteral` represents a literal



function _encodeLiteral(literal) {
  // Escape special characters
  var value = literal.value;
  if (escape.test(value)) value = value.replace(escapeAll, characterReplacer); // Write the literal, possibly with type or language

  if (literal.language) return '"' + value + '"@' + literal.language;
  else if (literal.datatype.value !== 'http://www.w3.org/2001/XMLSchema#string') return '"' + value + '"^^' + _encodeIriOrBlank(literal.datatype); 
  else return '"' + value + '"';
}

// ### `_encodeObject` represents an object
function _encodeObject(object) {
  // "dateTime" - EXCEPTION !!!!
  //if(object.datatypeString === 'http://www.w3.org/2001/XMLSchema#dateTime') {
  // console.log('DBG:\t'+object.value+'\t'+format_dateTime(object.value))
  //} else if(object.termType === 'Literal') {
  // console.log('DBG:\t'+object.value+'\t'+_encodeLiteral(object))
  //}
  // console.log(1);

  if(object.termType === "NamedNode"){
    return object.datatypeString === 'http://www.w3.org/2001/XMLSchema#dateTime' ? '"' + format_dateTime(object.value) + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>' : object.termType === 'Literal' ? _encodeLiteral(object) : _encodeIriOrBlank(object);
  }
  else{
    return object.datatype.value === 'http://www.w3.org/2001/XMLSchema#dateTime' ? '"' + format_dateTime(object.value) + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>' : object.termType === 'Literal' ? _encodeLiteral(object) : _encodeIriOrBlank(object);
  }

  // console.log(object.termType);
  // console.log(object.datatype);
  //return object.datatypeString === 'http://www.w3.org/2001/XMLSchema#dateTime' ? '"' + format_dateTime(object.value) + '"^^<http://www.w3.org/2001/XMLSchema#dateTime>' : object.termType === 'Literal' ? _encodeLiteral(object) : _encodeIriOrBlank(object);
}

function format_dateTime(o) {
 var date = moment.utc(o);
 // console.log('DBG:\t'+o+'\t'+date.toISOString());
 //console.log(date.toISOString());
 //console.log(2);
 return date.toISOString();
}







function iHash (graph) {
 var graph_hash = bigInt.zero;
 graph.forEach((quad) => {
  graph_hash = _modulo_hash(graph_hash, _calculate_triple_hash(quad.subject, quad.predicate, quad.object));

  if(quad.subject.termType === "BlankNode") {
   graph_hash = _modulo_hash(graph_hash, _calculate_hash_for_triples_linked_by_subject(graph, quad.subject));
   graph_hash = _modulo_hash(graph_hash, _calculate_hash_for_triples_linked_by_object(graph, quad.subject));
  }

  if(quad.object.termType === "BlankNode") {
   graph_hash = _modulo_hash(graph_hash, _calculate_hash_for_triples_linked_by_subject(graph, quad.object));
   graph_hash = _modulo_hash(graph_hash, _calculate_hash_for_triples_linked_by_object(graph, quad.object));
  }
 });

 return bigInt(graph_hash).toString(16).padStart(64,'0');
};

function _calculate_triple_hash (s,p,o) {
 return bigInt(crypto.createHash('sha256').update(_encode_triple(s,p,o)).digest("hex"),16);
};

function _calculate_hash_for_triples_linked_by_subject(graph, resource) {
 var partial_hash = bigInt.zero;

 graph.match(null,null,resource,null).forEach((quad) => {
  partial_hash = _modulo_hash(partial_hash, _calculate_triple_hash(quad.subject, quad.predicate, quad.object));
 });

 return partial_hash;
};

function _calculate_hash_for_triples_linked_by_object(graph, resource) {
 var partial_hash = bigInt.zero;

 graph.match(resource,null,null,null).forEach((quad) => {
  partial_hash = _modulo_hash(partial_hash, _calculate_triple_hash(quad.subject, quad.predicate, quad.object));
 });

 return partial_hash;
};

function _encode_triple (s,p,o) {
 var s_encoded = (s.termType === "BlankNode" ? _BLANK_NODE_SUBJECT_NAME : _encodeIriOrBlank(s));
 var p_encoded = _encodeIriOrBlank(p);
 // "clean" literals in object - EXCEPTION !!!
 var o_encoded = (o.termType === "BlankNode" ? _BLANK_NODE_OBJECT_NAME : _encodeObject(o)).replace(regex_invisible,"").normalize('NFC');

 //if (p_encoded === '<http://lei.info/voc/l1/streetAddress>') {
 // var o_encoded_conv = o_encoded.replace(regex_invisible,"");
 // console.log('DBG:\t' + o_encoded + '\t' + Buffer.from(o_encoded,'utf-8').toString('hex'));
 // console.log('DBG:\t' + Buffer.from(o_encoded_conv,'utf-8'));
 //}

 //console.log('DBG:\t' + s_encoded + '\t' + p_encoded + '\t' + o_encoded + '\t' + bigInt(crypto.createHash('sha256').update(s_encoded + p_encoded + o_encoded).digest("hex"),16).toString(16).padStart(64,'0'));
//  console.log(s_encoded+ p_encoded+ o_encoded);
 return s_encoded+ p_encoded+ o_encoded;
};

function _modulo_hash(a_number, a_hash) {
 return bigInt(a_number).add(a_hash).mod(_MOD_OPERAND);
};

module.exports = iHash;