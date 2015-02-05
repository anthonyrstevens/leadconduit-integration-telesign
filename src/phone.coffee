crypto = require('crypto');
moment = require('moment');
querystring = require('querystring')
_s = require('underscore.string');

baseUrl = 'https://rest.telesign.com/v1/phoneid/live/'

#
# Request Function -------------------------------------------------------
#

request = (vars) ->

  # Use the API key and Customer ID specified as an environment variables.
  # Assign the values to vars so that we can mask them. This works because the request function is
  # called twice: first to generate the real request, and second to generate the masked request.
  # On the second invocation, the vars properties are already assigned as masked strings.
  vars.apiKey ?= process.env.TELESIGN_ENCODED_API_KEY ? vars.telesign.encoded_apikey
  vars.customerId ?= process.env.TELESIGN_CUSTOMER_ID ? vars.telesign.customer_id

  # Generate the request signature
  date = moment().format('ddd, DD MMM YYYY HH:mm:ss ZZ')
  headers = "x-ts-date:#{date}\n"
  resource = "/v1/phoneid/live/1#{vars.lead.phone_1}"
  stringToSign = "GET\n\n\n#{headers}#{resource}"
  hash = crypto.createHmac('sha1', new Buffer(vars.apiKey, 'base64')).update(stringToSign, 'utf-8').digest('base64')
  signature = "TSA #{vars.customerId}:#{hash}"

  # Build the query string
  query = querystring.encode
    'ucid': 'LEAD'
    'x-ts-date': date
    'x-ts-authorization': signature

  # Mask the sensitive credentials. The masked values will be used on subsequent invocations.
  vars.apiKey = Array(vars.apiKey.length + 1).join('*')
  vars.customerId = Array(vars.customerId.length + 1).join('*')

  url: "#{baseUrl}1#{vars.lead.phone_1}?#{query}",
  method: 'GET',
  headers:
    Accepts: 'application/json'

request.variables = ->
  [
    { name: 'lead.phone_1', type: 'string', required: true, description: 'Phone number' }
  ]

validate = (vars) ->
  return 'phone must not be blank' unless vars.lead?.phone_1?
  return 'phone must be valid' if vars.lead.phone_1?.valid? and vars.lead.phone_1.valid != true
  return 'phone must not be masked' if vars.lead.phone_1?.masked == true

#
# Response Function ------------------------------------------------------
#

response = (vars, req, res) ->

  if res.status == 200
    event = JSON.parse(res.body)
    if event.status.code == 300
      event.billable = true
      event.outcome = 'success'
      # success is the default status on 300, but we change this if the subscriber status is inactive
      # or if the phone type is 6, 7, 8, 9, 11, or 20
      phoneCode = event.phone_type.code
      if event.live?.subscriber_status != 'ACTIVE' or isBadPhoneType(phoneCode)
        event.outcome = 'failure'


    else if event.status.code == 301
      #301 should have a partial flag
      event.outcome = 'failure'
      event.reason = 'partial transaction'
      event.partial = true
      event.billable = true
    else
      event.outcome = 'error'
      event.reason = "#{event.status.code} #{event.status.description}"
      delete event.status
      delete event.reason
      delete event.signature_string

    if event.outcome != 'error'
      event.risk =
      switch event.phone_type.code
        when '1' then 'low'
        when '2', '10' then 'medium-low'
        when '3', '11', '20' then 'medium-high'
        when '4', '5', '6', '7', '8', '9' then 'high'
        else 'unknown'

      event.carrier = event.carrier.name
      event.phone_type = _s.humanize(event.phone_type.description)
      if event.live
        event.subscriber_status = _s.titleize(event.live.subscriber_status)
        event.device_status = _s.titleize(event.live.device_status)
        event.roaming = _s.titleize(event.live.roaming)
        event.roaming_country_code = event.live.roaming_country_iso2
      else
        event.subscriber_status = null
        event.device_status = null
        event.roaming = null
        event.roaming_country_code = null

      if event.location.city
        event.location.city = _s.titleize(event.location.city)
      if event.location.county
        event.location.county = _s.titleize(event.location.county)
      event.location.country_code = event.location.country.iso2
      event.location.postal_code = event.location.zip
      event.location.latitude = event.location.coordinates.latitude
      event.location.longitude = event.location.coordinates.longitude
      event.location.time_zone = event.location.time_zone.name
      delete event.reference_id
      delete event.resource_uri
      delete event.sub_resource
      delete event.status
      delete event.live
      delete event.numbering
      delete event.location.coordinates
      delete event.location.country
      delete event.location.zip

  else
    event = { outcome: 'error', reason: "TeleSign error (#{res.status})" }

  live: event

response.variables = ->
  [
    { name: 'live.risk', type: 'string', description: 'Risk rating for a given number.'}
    { name: 'live.phone_type', type: 'string', description: 'Description parameter of the object containing details about the phone type.' }
    { name: 'live.subscriber_status', type: 'string', description: 'A string indicating the current status of the subscriber’s phone number.' }
    { name: 'live.device_status', type: 'string', description: 'A string indicating the current status of the phone equipment.' }
    { name: 'live.carrier', type: 'string', description: 'A string specifying the name of the carrier.' }
    { name: 'live.roaming_country_code', type: 'string', description: 'The ISO 3166-1 2-letter Country Code in which the mobile device is roaming.' }
    { name: 'live.location.city', type: 'string', description: 'A string specifying the name of the city associated with the phone number.' }
    { name: 'live.location.state', type: 'string', description: 'The 2-letter State Code of the state (province, district, or territory) associated with the phone number (North America only).' }
    { name: 'live.location.postal_code', type: 'string', description: 'The 5-digit United States Postal Service ZIP Code associated with the phone number (U.S. only).' }
    { name: 'live.location.metro_code', type: 'string', description: 'A 4-digit string indicating the Primary Metropolitan Statistical Area (PMSA) Code for the location associated with the phone number (U.S. only). PMSA Codes are governed by the US Census Bureau.' }
    { name: 'live.location.county', type: 'string', description: 'A string specifying the name of the County (or Parish) associated with the phone number (U.S. only).' }
    { name: 'live.location.country_code', type: 'string', description: 'The ISO 3166-1 2-letter Country Code associated with phone number.' }
    { name: 'live.location.latitude', type: 'string', description: 'A value indicating the number of degrees of latitude of the location associated with the phone number, expressed in seven decimal digits, with five decimal places.' }
    { name: 'live.location.longitude', type: 'string', description: 'A value indicating the number of degrees of longitude of the location associated with the phone number, expressed in eight decimal digits, with five decimal places.' }
    { name: 'live.location.time_zone', type: 'string', description: 'A string identifying the Time Zone Name (TZ) associated with the phone number (U.S. only).' }
    { name: 'live.errors', type: 'string', description: 'A JSON object that contains information about error conditions that might have resulted from the request, in an array of property-value pairs. If multiple errors occur, a pair of parameters is returned for each error. If no errors occur, then this object is empty.' }
  ]


#
# Exports ----------------------------------------------------------------
#

module.exports =
  name: 'Phone Data Append'
  validate: validate
  request: request
  response: response

#
# Helpers ----------------------------------------------------------------
#

isBadPhoneType = (phoneCode) ->
  switch phoneCode
    when '6' or '7' or '8' or '9' or '11' or '20' then true
    else false
