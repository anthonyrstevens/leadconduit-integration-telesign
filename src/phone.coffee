crypto = require('crypto');
moment = require('moment');
_s = require('underscore.string');

baseUrl = 'https://rest.telesign.com/v1/phoneid/live/'

#
# Request Function -------------------------------------------------------
#

# Z questions:  date and duration?

request = (vars) ->
  d = Date.now()
  rfc822Date = moment(d).format('ddd, DD MMM YYYY HH:mm:ss ZZ')
  CanonicalizedTsHeaders = 'x-ts-date:' + rfc822Date + '\n'
  CanonicalizedPOSTVariables = ''
  CanonicalizedResource = "/v1/phoneid/live/1#{vars.lead.phone1}"
  apiKeyDecoded = new Buffer("#{vars.telesign.encoded_apikey}", 'base64')
  stringToSign = String("GET\n\n\n" + CanonicalizedTsHeaders + CanonicalizedResource);
  hash = crypto.createHmac('sha1', apiKeyDecoded).update(stringToSign, 'utf-8').digest('base64')
  signature = "TSA " + "#{vars.telesign.customer_id}" + ":" + hash
  url: "#{baseUrl}1#{vars.lead.phone1}?ucid=LEAD&x-ts-date=#{rfc822Date}&x-ts-authorization=#{signature}",
  method: 'GET',
  headers:
    Accepts: 'application/json'

request.variables = ->
  [
    { name: 'telesign.customer_id', type: 'string', required: true, description: 'Telesign Customer Id' },
    { name: 'telesign.encoded_apikey', type: 'string', required: true, description: 'Telesign base64-encoded API Key' },
    { name: 'lead.phone1', type: 'string', required: true, description: 'Phone Number' }
  ]



#
# Response Function ------------------------------------------------------
#

response = (vars, req, res) ->
  if res.status == 200
    event = JSON.parse(res.body)
    # this should only be a success if the status.code is 300 or 301.  if 301 it should have a partial flag
    if event.status.code == 300
      event.outcome = 'success'
    else if event.status.code == 301
      event.outcome = 'success'
      event.partial = true
    else
      event.outcome = 'error'
      event.reason = event.status.code + ' - ' + event.status.description
      delete event['status'];
      delete event['reason'];
      delete event['signature_string'];

    if event.outcome == 'success'
      phone_code = event.phone_type.code
      switch (phone_code)
        when "1" then event.risk = 'low'; break;
        when "2", "10" then event.risk = 'medium-low'; break;
        when "3", "11", "20" then event.risk = 'medium-high'; break;
        when "4", "5", "6", "7", "8", "9" then event.risk = 'high'; break;
        else event.risk = 'unknown'

      event.carrier = event.carrier.name
      event.phone_type = _s.humanize(event.phone_type.description)
      if event.live
        event.subscriber_status = _s.capitalize(event.live.subscriber_status.toLowerCase())
        event.device_status = _s.capitalize(event.live.device_status.toLowerCase())
        event.roaming = _s.capitalize(event.live.roaming.toLowerCase())
        event.roaming_country_code = event.live.roaming_country_iso2
      else
        event.subscriber_status = null
        event.device_status = null
        event.roaming = null
        event.roaming_country_code = null

      event.location.city = _s.capitalize(event.location.city.toLowerCase())
      event.location.county = _s.capitalize(event.location.county.toLowerCase())
      event.location.country_code = event.location.country.iso2
      event.location.postal_code = event.location.zip
      event.location.latitude = event.location.coordinates.latitude
      event.location.longitude = event.location.coordinates.longitude
      event.location.time_zone = event.location.time_zone.name
      delete event['resource_uri'];
      delete event['sub_resource'];
      delete event['status'];
      delete event['live'];
      delete event.location['coordinates']
      delete event.location['country']
      delete event.location['zip']

  else
    event = { outcome: 'error', reason: "Telesign error (#{res.status})" }
    live: event

  live: event

# clean up these events, use underscore_strings and make more user friendly
response.variables = ->
  [
    { name: 'live.reference_id', type: 'string', description: 'A 32-digit hex value used to identify the web service request. The value is unique to each web service request, is randomly-generated by TeleSign, and is returned in the response message immediately following the web service request.' },
    { name: 'live.errors', type: 'string', description: 'A JSON object that contains information about error conditions that might have resulted from the request, in an array of property-value pairs. If multiple errors occur, a pair of parameters is returned for each error. If no errors occur, then this object is empty.' },
    { name: 'live.phone_type', type: 'string', description: 'Description parameter of the object containing details about the phone type.'},
    { name: 'live.risk', type: 'string', description: 'Risk rating for a given number.'},
    { name: 'live.carrier', type: 'string', description: 'A string specifying the name of the carrier.'},
    { name: 'live.subscriber_status', type: 'string', description: 'A string indicating the current status of the subscriber’s phone number.'},
    { name: 'live.device_status', type: 'string', description: 'A string indicating the current status of the phone equipment.'},
    { name: 'live.roaming_country_code', type: 'string', description: 'The ISO 3166-1 2-letter Country Code in which the mobile device is roaming.'},
    { name: 'live.location.city', type: 'string', description: 'A string specifying the name of the city associated with the phone number.'},
    { name: 'live.location.state', type: 'string', description: 'The 2-letter State Code of the state (province, district, or territory) associated with the phone number (North America only).'},
    { name: 'live.location.postal_code', type: 'string', description: 'The 5-digit United States Postal Service ZIP Code associated with the phone number (U.S. only).'},
    { name: 'live.location.metro_code', type: 'string', description: 'A 4-digit string indicating the Primary Metropolitan Statistical Area (PMSA) Code for the location associated with the phone number (U.S. only). PMSA Codes are governed by the US Census Bureau.'},
    { name: 'live.location.county', type: 'string', description: 'A string specifying the name of the County (or Parish) associated with the phone number (U.S. only).'},
    { name: 'live.location.country_code', type: 'string', description: 'The ISO 3166-1 2-letter Country Code associated with phone number.'},
    { name: 'live.location.latitude', type: 'string', description: 'A value indicating the number of degrees of latitude of the location associated with the phone number, expressed in seven decimal digits, with five decimal places.'},
    { name: 'live.location.longitude', type: 'string', description: 'A value indicating the number of degrees of longitude of the location associated with the phone number, expressed in eight decimal digits, with five decimal places.'},
    { name: 'live.location.time_zone', type: 'string', description: 'A string identifying the Time Zone Name (TZ) associated with the phone number (U.S. only).'},
    { name: 'live.numbering.original.complete_phone_number', type: 'string', description: 'The Base Phone Number prefixed with the Country Dialing Code. This forms the Subresource Identifier part of the PhoneID Live web service URI.'},
    { name: 'live.numbering.original.country_code', type: 'number', description: 'A 1, 2, or 3-digit number representing the Country Dialing Code.'},
    { name: 'live.numbering.original.phone_number', type: 'number', description: 'The Base Phone Number. This is simply the phone number without the Country Dialing Code.'},
    { name: 'live.numbering.cleansing.call.country_code', type: 'number', description: 'A 1, 2, or 3-digit number representing the Country Dialing Code.'},
    { name: 'live.numbering.cleansing.call.phone_number', type: 'string', description: 'The Base Phone Number. This is simply the phone number without the Country Dialing Code.'},
    { name: 'live.numbering.cleansing.call.cleansed_code', type: 'number', description: 'One of the Phone Number Cleansing Codes describing the cleansing operation TeleSign performed on the phone number. The default value is 100 (No changes were made to the phone number).'},
    { name: 'live.numbering.cleansing.call.min_length', type: 'number', description: 'The minimum number of digits allowed for phone numbers with this particular Country Dialing Code.'},
    { name: 'live.numbering.cleansing.call.max_length', type: 'number', description: 'The maximum number of digits allowed for phone numbers with this particular Country Dialing Code.'}
  ]


#
# Exports ----------------------------------------------------------------
#

module.exports =
  request: request,
  response: response