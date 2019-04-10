// allowedStartRules = multipleexpressions,textval,integer,duration,catchall,stringlist,locationlist
{
  operators =  {
    // TEXT
    'matches': {
      operator: "matches",
      opposite: "notmatches",
      comparer: function(srcs, targets) {
        for (i = 0; i < srcs.length; i++) {
          src = srcs[i].toLowerCase();
          for (j = 0; j < targets.length; j++) {
            if (src.match(targets[j].toLowerCase())) {
              return true;
            }
          }
        }
        return false;
      }
    },
    'contains': {
      operator: "contains",
      opposite: "notcontains",
      comparer: function(srcs, targets) {
        for (i = 0; i < srcs.length; i++) {
          src = srcs[i].toLowerCase();
          for (j = 0; j < targets.length; j++) {
            if (src.indexOf(targets[j].toLowerCase()) != -1) {
              return true;
            }
          }
        }
        return false;
      }
    },
    'blank': {
      operator: "blank",
      opposite: "notblank",
      comparer: function(vals) {
        for (i = 0; i < vals.length; i++) {
          if (vals[i].length == 0) {
            return true
          }
        }
        return false;
      }
    },
    'exact': {
      operator: "exact",
      opposite: "notequal",
      comparer: function(srcs, targets) {
        for (i = 0; i < srcs.length; i++) {
          src = srcs[i].toLowerCase();
          for (j = 0; j < targets.length; j++) {
            if (src.toLowerCase() == targets[j].toLowerCase()) {
              return true;
            }
          }
        }
        return false;
      },
    },
    'mixedcase': {
      operator: "mixedcase",
      opposite: "notmixedcase",
      comparer: function(vals) {
        for (i = 0; i < vals.length; i++) {
          if (vals[i].match("[a-z][A-Z]")) {
            return true;
          }
        }
        return false;
      },
    },

    'uppercase': {
      operator: "uppercase",
      opposite: "notuppercase",
      comparer: function(vals) {
        for (i = 0; i < vals.length; i++) {
          if (vals[i] == vals[i].toUpperCase()) {
            return true;
          }
        }
        return false;
      },
    },

    'lowercase': {
      operator: "lowercase",
      opposite: "notlowercase",
      comparer: function(vals) {
        for (i = 0; i < vals.length; i++) {
          if (vals[i] == vals[i].toLowerCase()) {
            return true;
          }
        }
        return false;
      },
    },

    // NUMBERS:
    'equals': {operator: "equals", comparer: function(a, b) {return a === b;}, opposite: 'notequals'},
    'greater': {operator: "greater", comparer: function(a, b) {return a > b;},  opposite: 'lessequals'},
    'greaterequals': {operator: "greaterequals", comparer: function(a, b) {return a >= b;}, opposite: 'less'},
    'less':  {operator: "less", comparer: function(a, b) {return a < b;}, opposite: 'greaterequals'},
    'lessequals': {operator: "lessequals", comparer: function(a, b) {return a <= b;}, opposite: 'greater'},

    'true': {
      operator: "true",
      opposite: "false",
      comparer: function(a) {return a}
    }
  };

  fields = {
    // DURATION:
    age: {
      getter: function(venue) {
        created = parseInt(venue.id.slice(0,8), 16);
        now = Date.now()  / 1000 |0
        return now-created
      },
      field: "age"
    },

    // TEXT:
    name: {
      getter: function(venue) {return [venue.name]},
      field: "name",
    },
    phone: {
      getter: function(venue) {
        if (venue.contact)
          return [venue.contact.phone || "", (venue.contact.formattedPhone || "").replace(/[^0-9]/g,"")]
        else
          return [""]
      },
      field: "phone",
      normalizer: function(string) {
        return string.replace(/[^0-9]/g,"")
      }
    },
    url: {
      getter: function(venue) {
        return [venue.url || ""]
      },
      field: "url",
    },
    twitter: {
      getter: function(venue) {
        if (venue.contact)
          return [venue.contact.twitter || ""]
        else
          return [""]
      },
      normalizer: function(string) {
        return string.replace("@","")
      },
      field: "twitter",
    },
    facebook: {
      getter: function(venue) {
        if (venue.contact)
          return [venue.contact.facebook || "", venue.contact.facebookName || "", venue.contact.facebookUsername || ""]
        else
          return [""]
      },
      field: "facebook",
    },
    address: {
      getter: function(venue) {
        return [venue.location.address || ""]
      },
      field: "address",
    },
    city: {
      getter: function(venue) {
        return [venue.location.city || ""]
      },
      field: "city",
    },
    state: {
      getter: function(venue) {
        return [venue.location.state || ""]
      },
      field: "state",
    },
    country: {
      getter: function(venue) {
        return [(venue.location.country || ""), (venue.location.cc || "")]
      },
      field: "country"
    },
    crossStreet: {
      getter: function(venue) {return [venue.location.crossStreet || ""]},
      field: "crossStreet",
    },
    category: {
      getter: function(venue) {
        if (venue.categories.length > 0)
          return [venue.categories[0].name]
        else
          return [""]
      },
      field: "category",
    },
    postalCode: {
      getter: function(venue) {
        return [venue.location.postalCode || ""]
      },
      field: "postalCode",
    },

    // BOOL FIELDS
    'private': {
      getter: (function(venue) {return venue.private;}),
      field: "private"
    },
    verified: {
      getter: (function(venue) {return venue.verified;}),
      field: "verified"
    },
    home: {
      getter: function(venue) {
        if (venue.categories && venue.categories.length > 0) {
          return venue.categories[0].id === "4bf58dd8d48988d103941735"
        } else {
          return false
        }
      },
      field: "home"
    },
    // flagged: {
    //   getter: (function(venue) {return venue.alreadyflagged;}),
    //   field: 'flagged'
    // },
    locked: {
      getter: (function(venue) {return venue.locked;}),
      field: "locked"
    },
    closed: {
      getter: (function(venue) {return venue.closed;}),
      field: "closed"
    },

    // NUMBER:
    tips: {
      getter: function(venue) {return venue.stats.tipCount},
      field: "tips",
    },
    herenow: {
      getter: function(venue) {return venue.hereNow.count},
      field: "herenow",
    },
    users: {
      getter: function(venue) {return venue.stats.usersCount},
      field: "users",
    },
    checkins: {
      getter: function(venue) {return venue.stats.checkinsCount},
      field: "checkins",
    }
  };
  fields.any = {
    getter: function(venue) {
      allfields = [
        fields['name'].getter(venue),
        fields.phone.getter(venue),
        fields.twitter.getter(venue),
        fields.facebook.getter(venue),
        fields.address.getter(venue),
        fields.crossStreet.getter(venue),
        fields.category.getter(venue),
        fields.city.getter(venue),
        fields.state.getter(venue),
        fields.country.getter(venue),
        fields.postalCode.getter(venue)
      ]
      return [].concat.apply([], allfields)
    },
    field: "any"
  }
  units = {
    'minute': 60,
    'hour': 60*60,
    'day': 60*60*24,
    'week': 60*60*24*7,
    'month': 60*60*24*30,
    'year': 60*60*24*365
  }
}

/**
 * This file describes the parse syntax and semantics for the advanced search field.
 */

multipleexpressions =
  first:expression rest:(expression_separator e:expression {return e;})*
  {return [first].concat(rest).filter(function(e) {return e})}

expressionwithspace =
  expressions:expression " "+ {return expressions}

expression =
  negatedexpression / positiveexpression / ""

positiveunparenthesized =

positiveexpression =
  boolvalued / numbervalued / durationvalued / textvalued / anyfield

expression_separator =
   " AND "i / " "+

anyfield =
  operands:stringlist {return {
    field: "any",
    type: "text",
    arity: 2,
    values: operands,
    operator: operators['contains'],
    predicate: function(venue) {
      return operators['contains'].comparer(fields.any.getter(venue), operands)
    }
  }}

// TEXT VALUED:

textvalued =
  text_unary_valued / text_binary_valued

text_binary_valued =
  field:textfield " "* operator:binary_text_operator " "* operands:stringlist {return {
    field: field.field,
    predicate: function(venue) {
      if (field.hasOwnProperty('normalizer')) {
        targets = operands.map(field.normalizer)
      } else {
        targets = operands
      }
      return operator.comparer(field.getter(venue), targets);
    },
    values: operands,
    operator: operator,
    type: 'text',
    arity: 2
  }}

text_unary_valued =
  field:textfield " "* operator:unary_text_operator {return {
    field: field.field,
    predicate: function(venue) {
      return operator.comparer(field.getter(venue))
    },
    type: "text",
    operator: operator,
    arity: 1
  }}

unary_text_operator =
  blank / mixedcase / uppercase / lowercase

blank =
  (":" / "IS"i / "=") " "* ("empty"i / "missing"i / "blank"i) {return operators.blank }
mixedcase =
  (":" / "IS"i / "=") " "* ("mixedcase"i) {return operators.mixedcase }
lowercase =
  (":" / "IS"i / "=") " "* ("lowercase"i) {return operators.lowercase }
uppercase =
  (":" / "IS"i / "=") " "* ("uppercase"i) {return operators.uppercase }
//punctuation =
//  (":" / "IS"i / "=") " "* ("punctuation"i) {return operators.punctuation }

textfield =
  name / address / category / crossStreet / phone / postalCode / twitter / facebook / url / category / city / state / country / any

name = "name"i {return fields.name}
phone = "phone"i {return fields.phone}
postalCode = ("zip"i / "postalCode"i) {return fields.postalCode}
url = ("url"i / "website"i) {return fields.url}
twitter = ("twitter"i) {return fields.twitter}
facebook = ("facebook"i) {return fields.facebook}
address = "address"i {return fields.address}
category = ("category"i / "cat"i) {return fields.category}
crossStreet = ("crossStreet"i / "cross"i) {return fields.crossStreet}
city = "city"i {return fields.city}
state = "state"i {return fields.state}
country = "country"i {return fields.country}
any = "any"i {return fields.any}

binary_text_operator = contains_any / matches_any / exact_any

contains_any = (":" / "IN "i) {return operators['contains']}
matches_any = ("REGEXP "i / "MATCH "i / "REGEX "i) {return operators['matches']}
exact_any = "=" {return operators['exact']}

// BOOL VALUED:
boolvalued =
  field:boolfield {return {
    field: field.field,
    predicate: function(venue) {return field.getter(venue);},
    type: 'bool',
    arity: 1,
    operator: operators.true
  }
}

boolfield = (private / verified / home / locked / closed) /* FIXME: 'homexxx' parses as a boolfield instead of text; add flagged here */

private = "private"i {return fields['private'] }
verified = "verified"i {return fields.verified}
home = "home"i {return fields.home}
// flagged = ("flagged"i / "alreadyflagged"i) {return fields.flagged}

locked = "locked"i {return fields.locked}
closed = "closed"i {return fields.closed}

// DURATION VALUED
durationvalued =
  field:agefield " "* operator:numberoperator " "* value:duration {return {
    field: field.field,
    predicate: function(venue) {
      return operator.comparer(field.getter(venue), value.value);
    },
    operator: operator,
    arity: 2,
    type: "duration",
    value: value
  }}

agefield = "age"i {return fields.age }
duration =
  val:integer " "+ unit:("minute"/"hour"/"day"/"week"/"month"/"year") "s"? {return {
    'value': (val * units[unit]),
    'text': text(),
    'type': 'duration',
    'count': val,
    'unit': unit
  }}

// NUMBER VALUED:

numbervalued =
  field:numberfield " "* operator:numberoperator " "* value:integer {return {
    field: field.field,
    predicate: function(venue) {
      return operator.comparer(field.getter(venue), value);
    },
    value: value,
    operator: operator,
    type: "numeric",
    arity: 2
  };}

numberfield =
  users / checkins / herenow / tips

users = "users"i {return fields.users}
checkins = "checkins"i {return fields.checkins}
herenow = "herenow"i {return fields.herenow}
tips = "tips"i {return fields.tips}

numberoperator = equals / greaterequals / greater / lessequals / less

equals = "=" {return operators.equals}
greater = ">" {return operators.greater}
greaterequals = ">=" {return operators.greaterequals}
less = "<" {return operators.less}
lessequals = "<=" {return operators.lessequals}

negatedexpression =
  ("-" / "NOT"i) " "* val:positiveexpression {return {
    'predicate': function(venue) {return !val.predicate(venue)},
    "type": "negated",
    "target": val
   }
 }

textval = stringlist / doublequotedstring / singlequotedstring / catchall

catchall =
  chars:.+ {return [chars.join("")]}

stringlist =
  strings:stringwithcomma* last:string {strings.push(last); return strings}

stringwithcomma =
  text:string "," " "? {return text}

string =
  singlequotedstring
  / doublequotedstring
  / text:[^ ,:><=~"'&]+ {return text.join("")}

singlequotedstring =
 "'" text:[^\']* "'" {return text.join("")}


doublequotedstring =
 "\"" chars:char* "\"" {return chars.join("")}

char
  = unescaped
  / escape
    sequence:(
        '"'
      / "\\"
      / "/"
      / "b" { return "\b"; }
      / "f" { return "\f"; }
      / "n" { return "\n"; }
      / "r" { return "\r"; }
      / "t" { return "\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }

escape         = "\\"
quotation_mark = '"'
unescaped      = [\x20-\x21\x23-\x5B\x5D-\uFFFFF]
HEXDIG = [0-9a-f]i

integer =
  number:[0-9]+ {return parseInt(number.join(""), 10);}


/* Locationlist related */
locationlist = (loc:location)*

location = lat:lat separator? "," separator? lng:lat locationseparator? {return lat + "," + lng}

separator = [\n \t\r]*

locationseparator = [\n \t\r;]*

lat = num:("-"? int "."? int?) {return parseFloat(num.join(""))}

int = num:[0-9]+ {return num.join("")}

