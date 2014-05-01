baseUrl = 'https://bpi.briteverify.com/emails.json'


#
# Request Function -------------------------------------------------------
#

request = (vars) ->
  {
  url: "#{baseUrl}?address=#{vars.lead.email}&apikey=#{vars.briteverify.apikey}",
  method: 'GET',
  headers:
    {
    Accepts: 'application/json'
    }
  }

request.variables = ->
  [
    { name: 'briteverify.apikey', type: 'string', required: true, description: 'BriteVerify API Key' },
    { name: 'lead.email', type: 'string', required: true, description: 'Email address' }
  ]


#
# Response Function ------------------------------------------------------
#

response = (vars, req, res) ->
  if res.status == 200
    event = JSON.parse(res.body)
    event['outcome'] = 'success'
    event
  else
    { outcome: 'error', reason: "BriteVerify error (#{res.status})" }

response.variables = ->
  [
    { name: 'briteverify.email.address', type: 'string', description: 'the email that was passed' },
    { name: 'briteverify.email.account', type: 'string', description: 'the inbox or account parsed from the email' },
    { name: 'briteverify.email.domain', type: 'string', description: 'the domain parsed from the email' },
    { name: 'briteverify.email.status', type: 'string', description: 'the status of the given email address' },
    { name: 'briteverify.email.error_code', type: 'number', description: 'a code representation of error' },
    { name: 'briteverify.email.error', type: 'string', description: 'the error message if the email is invalid' },
    { name: 'briteverify.email.disposable', type: 'boolean', description: 'is the email a temporary or "disposable" email address?' },
    { name: 'briteverify.email.role_address', type: 'boolean', description: 'is the email aside for a function rather than a person (postmaster, sales, admin, info, etc)?' },
    { name: 'briteverify.email.duration', type: 'number', description: 'the time it took to process your request' }
  ]


#
# Exports ----------------------------------------------------------------
#

module.exports =
  request: request,
  response: response


